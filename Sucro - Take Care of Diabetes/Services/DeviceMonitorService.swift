//
//  DeviceMonitorService.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/13/26.
//

import Network
import UIKit
import Combine
import SwiftUI
import CoreBluetooth

// CHANGED: Inherit from NSObject
class DeviceMonitorService: NSObject, ObservableObject {
    static let shared = DeviceMonitorService()
    
    @Published var batteryLevel: Double = 0.0
    @Published var batteryState: UIDevice.BatteryState = .unknown
    @Published var isConnected: Bool = true
    @Published var connectionType: ConnectionType?
    @Published var lastSyncTime: Date?
    @Published var isBluetoothEnabled: Bool = false
    @Published var isCGMConnected: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    private var centralManager: CBCentralManager?
    private var cgmPeripheral: CBPeripheral?
    
    enum ConnectionType: String {
        case wifi
        case cellular
        case bluetooth
        case other
    }
    
    // CHANGED: Override init and call super.init()
    override init() {
        super.init()  // Must call super.init() first
        setupBatteryMonitoring()
        setupNetworkMonitoring()
        setupBluetoothMonitoring()
        startSyncTimer()
    }
    
    private func setupBatteryMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        updateBatteryStatus()
        
        NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateBatteryStatus()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIDevice.batteryStateDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateBatteryStatus()
            }
            .store(in: &cancellables)
    }
    
    private func updateBatteryStatus() {
        DispatchQueue.main.async {
            self.batteryLevel = Double(UIDevice.current.batteryLevel)
            self.batteryState = UIDevice.current.batteryState
        }
    }
    
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                
                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = .cellular
                } else {
                    self?.connectionType = .other
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    private func setupBluetoothMonitoring() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func connectToCGM(peripheral: CBPeripheral) {
        cgmPeripheral = peripheral
        centralManager?.connect(peripheral, options: nil)
    }
    
    func disconnectCGM() {
        if let peripheral = cgmPeripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
    }
    
    private func startSyncTimer() {
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                if let lastReading = self?.lastSyncTime {
                    if Date().timeIntervalSince(lastReading) < 300 {
                        self?.lastSyncTime = Date()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func recordSync() {
        lastSyncTime = Date()
    }
    
    var batteryColor: Color {
        switch batteryLevel {
        case 0..<0.2: return .red
        case 0.2..<0.4: return .orange
        default: return .green
        }
    }
    
    var batteryIcon: String {
        switch batteryState {
        case .charging, .full: return "battery.100.bolt"
        case .unplugged:
            let level = Int(batteryLevel * 100)
            switch level {
            case 0..<25: return "battery.25"
            case 25..<50: return "battery.50"
            case 50..<75: return "battery.75"
            default: return "battery.100"
            }
        default: return "battery.0"
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension DeviceMonitorService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        DispatchQueue.main.async {
            switch central.state {
            case .poweredOn:
                self.isBluetoothEnabled = true
            case .poweredOff, .unauthorized, .unsupported, .resetting, .unknown:
                self.isBluetoothEnabled = false
                self.isCGMConnected = false
            @unknown default:
                self.isBluetoothEnabled = false
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            self.isCGMConnected = true
            self.connectionType = .bluetooth
            peripheral.delegate = self
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            self.isCGMConnected = false
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            self.isCGMConnected = false
            print("Failed to connect to CGM: \(error?.localizedDescription ?? "Unknown error")")
        }
    }
}

// MARK: - CBPeripheralDelegate

extension DeviceMonitorService: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        // Handle service discovery
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        // Handle characteristic discovery
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // Handle incoming glucose data
    }
}
