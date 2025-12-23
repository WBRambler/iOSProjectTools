
import Combine
import CoreBluetooth
import UIKit

// MARK: - 示例：蓝牙设备列表页面
class BluetoothDeviceListVC: UIViewController {
    // 存储订阅者
    private var cancellables = Set<AnyCancellable>()
    // 扫描到的设备列表（用于UI展示）
    private var scannedDevices: [BluetoothPeripheralModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        subscribeDeviceStates()
        // 页面加载后，申请权限并开启蓝牙
        DeviceDispatchCenter.shared.requestBluetoothPermission()
        DeviceDispatchCenter.shared.enableBluetooth()
    }
    
    /// 订阅设备状态变化
    private func subscribeDeviceStates() {
        DeviceDispatchCenter.shared.statusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self else { return }
                
                // 1. 处理蓝牙权限状态
                self.handleBluetoothPermission(status.bluetoothPermissionState)
                
                // 2. 处理蓝牙中心状态（比如未开启）
                self.handleBluetoothCentralState(status.bluetoothCentralState)
                
                // 3. 更新扫描到的设备列表
                self.scannedDevices = status.scannedPeripherals
                self.updateDeviceListUI()
                
                // 4. 处理蓝牙连接状态
                self.handleBluetoothConnectionState(status.bluetoothState)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - UI事件处理
    /// 点击“开始扫描”按钮
    @objc private func startScanButtonTapped() {
        // 开始扫描（指定服务UUID，或nil扫描所有）
        DeviceDispatchCenter.shared.startBluetoothScanning(
            serviceUUIDs: [CBUUID(string: "FFF0")], // 示例：扫描指定服务的设备
            timeout: 15 // 扫描15秒后自动停止
        )
    }
    
    /// 点击“停止扫描”按钮
    @objc private func stopScanButtonTapped() {
        DeviceDispatchCenter.shared.stopBluetoothScanning()
    }
    
    /// 点击设备列表项（连接设备）
    @objc private func connectDevice(_ peripheral: CBPeripheral) {
        DeviceDispatchCenter.shared.connectBluetoothPeripheral(peripheral)
    }
    
    // MARK: - 状态处理
    /// 处理蓝牙权限
    private func handleBluetoothPermission(_ state: BluetoothPermissionState) {
        switch state {
        case .notDetermined:
            print("蓝牙权限：未授权")
        case .authorized:
            print("蓝牙权限：已授权")
        case .denied:
            // 提示用户去设置开启权限
            showPermissionAlert()
        case .restricted:
            print("蓝牙权限：受限制")
        }
    }
    
    /// 处理蓝牙中心状态
    private func handleBluetoothCentralState(_ state: BluetoothCentralState) {
        switch state {
        case .poweredOff:
            // 提示用户开启蓝牙
            showBluetoothOffAlert()
        case .unsupported:
            showUnsupportedAlert()
        case .unauthorized:
            showPermissionAlert()
        case .poweredOn:
            print("蓝牙已开启，可正常使用")
        default:
            break
        }
    }
    
    /// 处理蓝牙连接状态
    private func handleBluetoothConnectionState(_ state: ConnectionState) {
        switch state {
        case .connecting:
            showLoadingHUD(text: "正在连接设备...")
        case .connected:
            hideLoadingHUD()
            showToast(text: "设备连接成功")
            // 跳转到通信页面
        case .failed(let error):
            hideLoadingHUD()
            showToast(text: error ?? "连接失败")
        case .disconnected:
            showToast(text: "设备已断开")
        }
    }
    
    // MARK: - UI更新（示例）
    private func updateDeviceListUI() {
        // 刷新TableView/CollectionView展示scannedDevices
        print("扫描到\(scannedDevices.count)个设备：\(scannedDevices.map { $0.name ?? "未知" })")
    }
    
    // MARK: - 提示框（示例）
    private func showPermissionAlert() {
        let alert = UIAlertController(
            title: "蓝牙权限不足",
            message: "请前往设置开启蓝牙权限，否则无法使用设备连接功能",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "前往设置", style: .default, handler: { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showBluetoothOffAlert() {
        let alert = UIAlertController(
            title: "蓝牙未开启",
            message: "请开启蓝牙后再进行设备扫描",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    private func showUnsupportedAlert() {
        let alert = UIAlertController(
            title: "设备不支持",
            message: "当前设备不支持蓝牙功能，无法使用该功能",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - 辅助方法（示例）
    private func setupUI() {
        // 添加开始/停止扫描按钮（示例）
        let startBtn = UIButton(type: .system)
        startBtn.setTitle("开始扫描设备", for: .normal)
        startBtn.addTarget(self, action: #selector(startScanButtonTapped), for: .touchUpInside)
        startBtn.frame = CGRect(x: 50, y: 100, width: 200, height: 44)
        view.addSubview(startBtn)
        
        let stopBtn = UIButton(type: .system)
        stopBtn.setTitle("停止扫描", for: .normal)
        stopBtn.addTarget(self, action: #selector(stopScanButtonTapped), for: .touchUpInside)
        stopBtn.frame = CGRect(x: 50, y: 160, width: 200, height: 44)
        view.addSubview(stopBtn)
    }
    
    private func showLoadingHUD(text: String) {
        // 展示加载框（示例）
        print(text)
    }
    
    private func hideLoadingHUD() {
        // 隐藏加载框（示例）
        print("加载完成")
    }
    
    private func showToast(text: String) {
        // 展示提示框（示例）
        print(text)
    }
}
