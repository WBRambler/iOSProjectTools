//
//  DeviceDispatchCenter.swift
//  ProjectToolsForiOS
//
//  Created by WuBo on 2025/12/23.
//

import Foundation
import Combine
import CoreBluetooth

// MARK: - 设备状态调度中心（集成蓝牙管理）
final class DeviceDispatchCenter {
    // MARK: - 单例（线程安全）
    static let shared = DeviceDispatchCenter()
    private init() {
        // 监听蓝牙管理器的所有状态，同步到自身
        bindBluetoothManager()
    }
    
    // MARK: - 依赖注入（蓝牙管理器）
    private let bluetoothManager = BluetoothManager.shared
    
    // MARK: - Combine 核心发布者
    private let statusSubject = CurrentValueSubject<DeviceConnectionStatus, Never>(.default)
    var statusPublisher: AnyPublisher<DeviceConnectionStatus, Never> {
        statusSubject.eraseToAnyPublisher()
    }
    
    // 存储订阅者
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 蓝牙操作对外暴露方法（页面只需调用这里）
    /// 申请蓝牙权限
    func requestBluetoothPermission() {
        bluetoothManager.requestBluetoothPermission()
    }
    
    /// 开启蓝牙（触发系统蓝牙初始化，提示用户开启）
    func enableBluetooth() {
        bluetoothManager.enableBluetooth()
    }
    
    /// 开始扫描蓝牙设备
    func startBluetoothScanning(serviceUUIDs: [CBUUID]? = nil, timeout: TimeInterval = 10) {
        // 先清空历史扫描数据
        var current = statusSubject.value
        current.scannedPeripherals.removeAll()
        statusSubject.send(current)
        
        // 开始扫描
        bluetoothManager.startScanning(serviceUUIDs: serviceUUIDs, timeout: timeout)
    }
    
    /// 停止扫描蓝牙设备
    func stopBluetoothScanning() {
        bluetoothManager.stopScanning()
    }
    
    /// 连接指定蓝牙设备
    func connectBluetoothPeripheral(_ peripheral: CBPeripheral) {
        bluetoothManager.connectPeripheral(peripheral)
    }
    
    /// 断开蓝牙设备连接
    func disconnectBluetoothPeripheral(_ peripheral: CBPeripheral? = nil) {
        bluetoothManager.disconnectPeripheral(peripheral)
    }
    
    // MARK: - 内部方法：绑定蓝牙管理器状态
    private func bindBluetoothManager() {
        // 1. 监听蓝牙中心状态（开启/关闭等）
        bluetoothManager.centralStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                var current = self.statusSubject.value
                current.bluetoothCentralState = state
                self.statusSubject.send(current)
            }
            .store(in: &cancellables)
        
        // 2. 监听蓝牙权限状态
        bluetoothManager.permissionStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                var current = self.statusSubject.value
                current.bluetoothPermissionState = state
                self.statusSubject.send(current)
            }
            .store(in: &cancellables)
        
        // 3. 监听蓝牙连接状态（设备配对层面）
        bluetoothManager.connectionStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                var current = self.statusSubject.value
                current.bluetoothState = state
                self.statusSubject.send(current)
            }
            .store(in: &cancellables)
        
        // 4. 监听扫描到的蓝牙设备（添加到列表，去重）
        bluetoothManager.scannedPeripheralPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] peripheralModel in
                guard let self else { return }
                var current = self.statusSubject.value
                // 去重：根据peripheral的identifier判断
                let isExist = current.scannedPeripherals.contains {
                    $0.peripheral.identifier == peripheralModel.peripheral.identifier
                }
                if !isExist {
                    current.scannedPeripherals.append(peripheralModel)
                } else {
                    // 替换已有设备（更新信号强度等）
                    current.scannedPeripherals = current.scannedPeripherals.map {
                        $0.peripheral.identifier == peripheralModel.peripheral.identifier ? peripheralModel : $0
                    }
                }
                self.statusSubject.send(current)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 原有状态更新方法
    func updateBluetoothState(_ state: ConnectionState) {
        var current = statusSubject.value
        current.bluetoothState = state
        statusSubject.send(current)
    }
    
    func updateHotspotState(_ state: ConnectionState) {
        var current = statusSubject.value
        current.hotspotState = state
        statusSubject.send(current)
    }
    
    func updateTCPState(_ state: ConnectionState) {
        var current = statusSubject.value
        current.tcpState = state
        statusSubject.send(current)
    }
    
    func resetAllStates() {
        // 停止扫描
        stopBluetoothScanning()
        // 断开蓝牙连接
        disconnectBluetoothPeripheral()
        // 重置状态
        statusSubject.send(.default)
    }
}
