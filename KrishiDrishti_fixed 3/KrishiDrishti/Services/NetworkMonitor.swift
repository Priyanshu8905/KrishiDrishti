// Services/NetworkMonitor.swift
// KrishiDrishti — Real-time network connectivity monitoring
// Enables seamless online/offline mode switching

import Network
import SwiftUI
import Combine

final class NetworkMonitor: ObservableObject {

    static let shared = NetworkMonitor()

    @Published var isConnected: Bool = true
    @Published var connectionType: ConnectionType = .unknown

    private let monitor = NWPathMonitor()
    private let queue   = DispatchQueue(label: "com.krishidrishti.network", qos: .background)

    enum ConnectionType {
        case wifi, cellular, ethernet, unknown
        var icon: String {
            switch self {
            case .wifi:     return "wifi"
            case .cellular: return "antenna.radiowaves.left.and.right"
            case .ethernet: return "cable.connector"
            case .unknown:  return "network.slash"
            }
        }
    }

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                if path.usesInterfaceType(.wifi)     { self?.connectionType = .wifi }
                else if path.usesInterfaceType(.cellular) { self?.connectionType = .cellular }
                else if path.usesInterfaceType(.wiredEthernet) { self?.connectionType = .ethernet }
                else { self?.connectionType = .unknown }
            }
        }
        monitor.start(queue: queue)
    }

    deinit { monitor.cancel() }
}
