// Models/UserProfile.swift
// KrishiDrishti — Upgraded Farmer profile model coordinating updates via Repository pattern

import SwiftUI
import Combine

final class UserProfile: ObservableObject {
    @Published var name: String      { didSet { save() } }
    @Published var village: String   { didSet { save() } }
    @Published var state: String     { didSet { save() } }
    @Published var crops: [String]   { didSet { save() } }
    @Published var farmSize: String  { didSet { save() } }
    @Published var phone: String     { didSet { save() } }
    @Published var avatarIdx: Int    { didSet { save() } }

    static let cropOptions  = [
        "Tomato", "Wheat", "Rice", "Maize", "Potato", "Sugarcane",
        "Cotton", "Soybean", "Onion", "Mustard", "Chilli", "Groundnut"
    ]
    static let stateOptions = [
        "Uttar Pradesh", "Punjab", "Haryana", "Madhya Pradesh",
        "Maharashtra", "Bihar", "Rajasthan", "Andhra Pradesh",
        "Karnataka", "Tamil Nadu", "Gujarat", "West Bengal",
        "Telangana", "Odisha", "Jharkhand", "Chhattisgarh"
    ]
    static let avatars = ["👨‍🌾", "👩‍🌾", "🧑‍🌾", "👴", "👵", "🧔"]

    var avatar: String { UserProfile.avatars[safe: avatarIdx] ?? "👨‍🌾" }
    var displayName: String { name.isEmpty ? "Farmer" : name }
    var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Good Morning 🌅" }
        if h < 17 { return "Hello 🙏" }
        return "Good Evening 🌇"
    }

    private let repository: UserProfileRepositoryProtocol

    init(repository: UserProfileRepositoryProtocol = DIContainer.shared.resolve(type: UserProfileRepositoryProtocol.self)) {
        self.repository = repository

        let data = repository.loadProfile()
        self.name = data.name
        self.village = data.village
        self.state = data.state
        self.crops = data.crops
        self.farmSize = data.farmSize
        self.phone = data.phone
        self.avatarIdx = data.avatarIdx
    }

    func save() {
        let data = UserProfileData(
            name: name,
            village: village,
            state: state,
            crops: crops,
            farmSize: farmSize,
            phone: phone,
            avatarIdx: avatarIdx
        )
        repository.saveProfile(data)
    }
}

extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}
