// Core/DI/DIContainer.swift
// KrishiDrishti — Dependency Injection Container resolving repository and system service protocols

import Foundation

final class DIContainer: @unchecked Sendable {
    static let shared = DIContainer()

    private var services: [String: Any] = [:]
    private let queue = DispatchQueue(label: "com.krishidrishti.dicontainer", attributes: .concurrent)

    private init() {
        registerDefaultServices()
    }

    func register<T>(type: T.Type, service: Any) {
        queue.async(flags: .barrier) {
            let key = String(describing: type)
            self.services[key] = service
        }
    }

    func resolve<T>(type: T.Type) -> T {
        var service: Any?
        queue.sync {
            let key = String(describing: type)
            service = self.services[key]
        }
        guard let resolved = service as? T else {
            fatalError("Dependency for type \(type) could not be resolved. Make sure it is registered in DIContainer.")
        }
        return resolved
    }

    private func registerDefaultServices() {
        // Register Managers & Local Persistence
        let dataManager = DataManager()
        register(type: DataManagerProtocol.self, service: dataManager)

        // Register Security
        let keychain = KeychainManager()
        register(type: KeychainManagerProtocol.self, service: keychain)

        let security = SecurityManager()
        register(type: SecurityManagerProtocol.self, service: security)

        // Register Networking
        let network = NetworkManager()
        register(type: NetworkManagerProtocol.self, service: network)

        // Register AI/ML Services
        let coreML = CoreMLService()
        register(type: CoreMLServiceProtocol.self, service: coreML)

        let vision = VisionService()
        register(type: VisionServiceProtocol.self, service: vision)

        let prediction = PredictionEngine(coreMLService: coreML, visionService: vision)
        register(type: PredictionEngineProtocol.self, service: prediction)

        // Register Location Services
        let location = LocationManager()
        register(type: LocationManagerProtocol.self, service: location)

        let map = MapService()
        register(type: MapServiceProtocol.self, service: map)

        // Register Motion & Sensor Services
        let motion = MotionManager()
        register(type: MotionManagerProtocol.self, service: motion)

        // Register Purchase/Subscription Services
        let store = StoreManager.shared
        register(type: StoreManagerProtocol.self, service: store)

        // Register Alerts
        let notifications = NotificationManager()
        register(type: NotificationManagerProtocol.self, service: notifications)

        // Register Repositories
        let weatherRepo = WeatherRepository(networkManager: network)
        register(type: WeatherRepositoryProtocol.self, service: weatherRepo)

        let cropRepo = CropProblemRepository(dataManager: dataManager)
        register(type: CropProblemRepositoryProtocol.self, service: cropRepo)

        let userRepo = UserProfileRepository(keychainManager: keychain)
        register(type: UserProfileRepositoryProtocol.self, service: userRepo)
    }
}
