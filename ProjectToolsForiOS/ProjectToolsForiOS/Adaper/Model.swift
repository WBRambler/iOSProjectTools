//
//  Model.swift
//  ProjectToolsForiOS
//
//  Created by WuBo on 2025/12/23.
//

import Combine
import CoreBluetooth
import Foundation

// MARK: - 原有状态枚举（复用+扩展）
enum ConnectionState: Equatable {
    case disconnected          // 未连接
    case connecting            // 连接中
    case connected             // 已连接
    case failed(String?)       // 连接失败（带错误信息）
}

// MARK: - 蓝牙专用枚举/模型
/// 蓝牙权限状态
enum BluetoothPermissionState: Equatable {
    case notDetermined  // 未授权
    case authorized     // 已授权
    case denied         // 拒绝
    case restricted     // 受限制（比如家长控制）
}

/// 蓝牙中心管理器状态
enum BluetoothCentralState: Equatable {
    case unknown
    case resetting
    case unsupported    // 设备不支持蓝牙
    case unauthorized   // 权限不足
    case poweredOff     // 蓝牙关闭
    case poweredOn      // 蓝牙开启（可用）
}

/// 扫描到的蓝牙设备模型
struct BluetoothPeripheralModel: Equatable, Identifiable {
    let id = UUID()              // 本地唯一标识
    let peripheral: CBPeripheral // 系统蓝牙设备对象
    let name: String?            // 设备名称
    let rssi: Int                // 信号强度
    let advertisementData: [String: Any] // 广播数据
}

/// 设备整体连接状态结构体（扩展：新增蓝牙子状态+扫描数据）
struct DeviceConnectionStatus: Equatable {
    // 原有状态
    var bluetoothState: ConnectionState  // 蓝牙连接状态（设备配对层面）
    var hotspotState: ConnectionState    // 热点连接状态
    var tcpState: ConnectionState        // TCP连接状态
    
    // 新增蓝牙扩展状态
    var bluetoothCentralState: BluetoothCentralState = .unknown // 蓝牙模块本身状态
    var bluetoothPermissionState: BluetoothPermissionState = .notDetermined // 蓝牙权限
    var scannedPeripherals: [BluetoothPeripheralModel] = [] // 扫描到的设备列表
    
    // 初始化：默认全为未连接
    static let `default` = DeviceConnectionStatus(
        bluetoothState: .disconnected,
        hotspotState: .disconnected,
        tcpState: .disconnected
    )
}
