// Models/UserProfile.swift
// KrishiDrishti — Farmer profile model with UserDefaults persistence

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

    static let cropOptions  = ["Tomato","Wheat","Rice","Maize","Potato","Sugarcane",
                                "Cotton","Soybean","Onion","Mustard","Chilli","Groundnut"]
    static let stateOptions = ["Uttar Pradesh","Punjab","Haryana","Madhya Pradesh",
                                "Maharashtra","Bihar","Rajasthan","Andhra Pradesh",
                                "Karnataka","Tamil Nadu","Gujarat","West Bengal",
                                "Telangana","Odisha","Jharkhand","Chhattisgarh"]
    static let avatars      = ["👨‍🌾","👩‍🌾","🧑‍🌾","👴","👵","🧔"]

    var avatar: String       { UserProfile.avatars[safe: avatarIdx] ?? "👨‍🌾" }
    var displayName: String  { name.isEmpty ? "Farmer" : name }
    var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Good Morning 🌅" }
        if h < 17 { return "Hello 🙏" }
        return "Good Evening 🌇"
    }

    init() {
        let d = UserDefaults.standard
        name      = d.string(forKey: "kd_name")    ?? ""
        village   = d.string(forKey: "kd_village") ?? ""
        state     = d.string(forKey: "kd_state")   ?? "Uttar Pradesh"
        crops     = d.stringArray(forKey: "kd_crops") ?? ["Tomato","Wheat"]
        farmSize  = d.string(forKey: "kd_farm")    ?? ""
        phone     = d.string(forKey: "kd_phone")   ?? ""
        avatarIdx = d.integer(forKey: "kd_avatar")
    }

    func save() {
        let d = UserDefaults.standard
        d.set(name,      forKey: "kd_name")
        d.set(village,   forKey: "kd_village")
        d.set(state,     forKey: "kd_state")
        d.set(crops,     forKey: "kd_crops")
        d.set(farmSize,  forKey: "kd_farm")
        d.set(phone,     forKey: "kd_phone")
        d.set(avatarIdx, forKey: "kd_avatar")
    }
}

extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}
