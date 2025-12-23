//
//  BluetoothManager.swift
//  ProjectToolsForiOS
//
//  Created by WuBo on 2025/12/23.
//

import UIKit
import CoreBluetooth

// MARK: - 蓝牙管理单例（封装CoreBluetooth+Combine）
final class BluetoothManager {
    // MARK: - 单例
    static let shared = BluetoothManager()
    private init() {
        
    }
    
    // MARK: - CoreBluetooth 核心对象
    private let centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.global(qos: .utility))
    
    // MARK: - Combine 发布者（对外只读）
    /// 蓝牙中心管理器状态发布者（开启/关闭/不支持等）
    private let centralStateSubject = CurrentValueSubject<BluetoothCentralState, Never>(.unknown)
    var centralStatePublisher: AnyPublisher<BluetoothCentralState, Never> {
        centralStateSubject.eraseToAnyPublisher()
    }
    
    /// 蓝牙权限状态发布者
    private let permissionStateSubject = CurrentValueSubject<BluetoothPermissionState, Never>(.notDetermined)
    var permissionStatePublisher: AnyPublisher<BluetoothPermissionState, Never> {
        permissionStateSubject.eraseToAnyPublisher()
    }
    
    /// 扫描到的蓝牙设备发布者（发送新增/更新的设备）
    private let scannedPeripheralSubject = PassthroughSubject<BluetoothPeripheralModel, Never>()
    var scannedPeripheralPublisher: AnyPublisher<BluetoothPeripheralModel, Never> {
        scannedPeripheralSubject.eraseToAnyPublisher()
    }
    
    /// 蓝牙连接状态发布者（设备配对层面）
    private let connectionStateSubject = CurrentValueSubject<ConnectionState, Never>(.disconnected)
    var connectionStatePublisher: AnyPublisher<ConnectionState, Never> {
        connectionStateSubject.eraseToAnyPublisher()
    }
    
    // MARK: - 内部属性
    private var isScanning = false // 是否正在扫描
    private var connectedPeripheral: CBPeripheral? // 当前连接的设备
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 对外方法：权限申请/蓝牙操作
    /// 申请蓝牙权限（iOS 13+ 需要主动请求）
    func requestBluetoothPermission() {
        if #available(iOS 13.0, *) {
            centralManager.requestAlwaysAuthorization()
        }
        // 更新权限状态
        updatePermissionState()
    }
    
    /// 开启蓝牙（本质是触发系统蓝牙中心管理器初始化，用户手动开启蓝牙）
    func enableBluetooth() {
        // 蓝牙中心管理器会自动触发状态回调，只需等待用户开启
        if centralManager.state == .poweredOff {
            // 可在这里提示用户去设置开启蓝牙
            print("请前往设置开启蓝牙")
        }
    }
    
    /// 开始扫描蓝牙设备
    /// - Parameters:
    ///   - serviceUUIDs: 要扫描的服务UUID（nil则扫描所有）
    ///   - timeout: 扫描超时时间（默认10秒）
    func startScanning(serviceUUIDs: [CBUUID]? = nil, timeout: TimeInterval = 10) {
        guard !isScanning else { return }
        guard centralManager.state == .poweredOn else {
            print("蓝牙未开启，无法扫描")
            connectionStateSubject.send(.failed("蓝牙未开启"))
            return
        }
        
        // 先更新状态
        isScanning = true
        // 开始扫描（允许重复发现，用于更新信号强度）
        centralManager.scanForPeripherals(withServices: serviceUUIDs, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: true
        ])
        
        // 扫描超时自动停止
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
            self?.stopScanning()
        }
    }
    
    /// 停止扫描蓝牙设备
    func stopScanning() {
        guard isScanning else { return }
        centralManager.stopScan()
        isScanning = false
        print("蓝牙扫描已停止")
    }
    
    /// 连接蓝牙设备
    /// - Parameter peripheral: 要连接的设备
    func connectPeripheral(_ peripheral: CBPeripheral) {
        guard centralManager.state == .poweredOn else {
            connectionStateSubject.send(.failed("蓝牙未开启"))
            return
        }
        
        connectionStateSubject.send(.connecting)
        centralManager.connect(peripheral, options: nil)
    }
    
    /// 断开蓝牙设备连接
    /// - Parameter peripheral: 要断开的设备（nil则断开当前连接的）
    func disconnectPeripheral(_ peripheral: CBPeripheral? = nil) {
        let targetPeripheral = peripheral ?? connectedPeripheral
        guard let targetPeripheral else { return }
        
        centralManager.cancelPeripheralConnection(targetPeripheral)
        connectionStateSubject.send(.disconnected)
        connectedPeripheral = nil
    }
    
    // MARK: - 内部方法：更新权限状态
    private func updatePermissionState() {
        let status = CBCentralManager.authorization
        switch status {
        case .notDetermined:
            permissionStateSubject.send(.notDetermined)
        case .authorizedAlways, .authorizedWhenInUse:
            permissionStateSubject.send(.authorized)
        case .denied:
            permissionStateSubject.send(.denied)
        case .restricted:
            permissionStateSubject.send(.restricted)
        @unknown default:
            permissionStateSubject.send(.notDetermined)
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothManager: CBCentralManagerDelegate {
    /// 蓝牙中心管理器状态变化
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // 更新中心状态
        let newState: BluetoothCentralState
        switch central.state {
        case .unknown: newState = .unknown
        case .resetting: newState = .resetting
        case .unsupported: newState = .unsupported
        case .unauthorized: newState = .unauthorized
        case .poweredOff: newState = .poweredOff
        case .poweredOn: newState = .poweredOn
        @unknown default: newState = .unknown
        }
        centralStateSubject.send(newState)
        
        // 更新权限状态
        updatePermissionState()
    }
    
    /// 发现蓝牙设备（扫描回调）
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // 过滤空名称设备（可选，根据业务需求）
        guard peripheral.name != nil || !peripheral.name!.isEmpty else { return }
        
        // 封装设备模型
        let model = BluetoothPeripheralModel(
            peripheral: peripheral,
            name: peripheral.name,
            rssi: RSSI.intValue,
            advertisementData: advertisementData
        )
        
        // 发送扫描到的设备
        scannedPeripheralSubject.send(model)
    }
    
    /// 蓝牙连接成功
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        peripheral.delegate = self // 设置外设代理（用于通信）
        connectionStateSubject.send(.connected)
        print("蓝牙设备连接成功：\(peripheral.name ?? "未知设备")")
    }
    
    /// 蓝牙连接失败
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connectionStateSubject.send(.failed(error?.localizedDescription ?? "连接失败"))
        print("蓝牙设备连接失败：\(error?.localizedDescription ?? "未知错误")")
    }
    
    /// 蓝牙断开连接
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectedPeripheral = nil
        if let error {
            connectionStateSubject.send(.failed(error.localizedDescription))
            print("蓝牙设备断开连接（异常）：\(error.localizedDescription)")
        } else {
            connectionStateSubject.send(.disconnected)
            print("蓝牙设备断开连接（主动）")
        }
    }
}

// MARK: - CBPeripheralDelegate（蓝牙通信）
extension BluetoothManager: CBPeripheralDelegate {
    /// 发现设备服务（通信前置步骤）
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            print("发现服务失败：\(error.localizedDescription)")
            return
        }
        // 遍历服务，发现特征值（示例）
        peripheral.services?.forEach { service in
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    /// 发现特征值（通信核心）
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error {
            print("发现特征值失败：\(error.localizedDescription)")
            return
        }
        // 可在这里监听可读写的特征值，或读写数据（示例）
        service.characteristics?.forEach { characteristic in
            // 监听特征值通知
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    /// 特征值数据更新（接收设备数据）
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error {
            print("接收数据失败：\(error.localizedDescription)")
            return
        }
        // 解析接收到的数据（示例：转成字符串）
        if let data = characteristic.value, let str = String(data: data, encoding: .utf8) {
            print("收到蓝牙数据：\(str)")
            // 可通过Combine发布接收到的数据（扩展：新增dataPublisher）
        }
    }
    
    /// 写入数据成功
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error {
            print("写入数据失败：\(error.localizedDescription)")
        } else {
            print("写入数据成功")
        }
    }
}
