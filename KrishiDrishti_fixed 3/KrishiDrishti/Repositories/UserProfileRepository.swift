// Repositories/UserProfileRepository.swift
// KrishiDrishti — UserProfile data access coordinator using Keychain for sensitive records and UserDefaults for public fields

import Foundation

protocol UserProfileRepositoryProtocol: Sendable {
    func loadProfile() -> UserProfileData
    func saveProfile(_ profile: UserProfileData)
}

struct UserProfileData: Codable, Sendable {
    var name: String
    var village: String
    var state: String
    var crops: [String]
    var farmSize: String
    var phone: String
    var avatarIdx: Int

    init(
        name: String = "",
        village: String = "",
        state: String = "Uttar Pradesh",
        crops: [String] = ["Tomato", "Wheat"],
        farmSize: String = "",
        phone: String = "",
        avatarIdx: Int = 0
    ) {
        self.name = name
        self.village = village
        self.state = state
        self.crops = crops
        self.farmSize = farmSize
        self.phone = phone
        self.avatarIdx = avatarIdx
    }
}

final class UserProfileRepository: UserProfileRepositoryProtocol {
    private let keychainManager: KeychainManagerProtocol

    init(keychainManager: KeychainManagerProtocol = DIContainer.shared.resolve(type: KeychainManagerProtocol.self)) {
        self.keychainManager = keychainManager
    }

    func loadProfile() -> UserProfileData {
        let defaults = UserDefaults.standard

        let name = defaults.string(forKey: "kd_name") ?? ""
        let village = defaults.string(forKey: "kd_village") ?? ""
        let state = defaults.string(forKey: "kd_state") ?? "Uttar Pradesh"
        let crops = defaults.stringArray(forKey: "kd_crops") ?? ["Tomato", "Wheat"]
        let farmSize = defaults.string(forKey: "kd_farm") ?? ""
        let avatarIdx = defaults.integer(forKey: "kd_avatar")

        // Securely fetch phone number from Keychain
        var phone = ""
        if let phoneData = try? keychainManager.read(key: "kd_secure_phone"),
           let phoneStr = String(data: phoneData, encoding: .utf8) {
            phone = phoneStr
        }

        return UserProfileData(
            name: name,
            village: village,
            state: state,
            crops: crops,
            farmSize: farmSize,
            phone: phone,
            avatarIdx: avatarIdx
        )
    }

    func saveProfile(_ profile: UserProfileData) {
        let defaults = UserDefaults.standard

        defaults.set(profile.name, forKey: "kd_name")
        defaults.set(profile.village, forKey: "kd_village")
        defaults.set(profile.state, forKey: "kd_state")
        defaults.set(profile.crops, forKey: "kd_crops")
        defaults.set(profile.farmSize, forKey: "kd_farm")
        defaults.set(profile.avatarIdx, forKey: "kd_avatar")

        // Securely write phone number to Keychain
        if let phoneData = profile.phone.data(using: .utf8) {
            try? keychainManager.save(key: "kd_secure_phone", data: phoneData)
        } else {
            try? keychainManager.delete(key: "kd_secure_phone")
        }
    }
}
