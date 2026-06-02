// Models/TreatmentStep.swift
// KrishiDrishti — Treatment checklist model

import Foundation
import SwiftUI

public struct TreatmentStep: Identifiable, Codable, Hashable {
    public let id: UUID
    public var title: String
    public var isCompleted: Bool
    public var note: String

    public init(id: UUID = UUID(), title: String, isCompleted: Bool = false, note: String = "") {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.note = note
    }
}

@MainActor
public final class TreatmentChecklist: ObservableObject {
    @Published public var steps: [TreatmentStep]
    private let saveKey: String

    public init(checklistID: String, initialSteps: [TreatmentStep]) {
        self.saveKey = "TreatmentChecklist_\(checklistID)"
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let saved = try? JSONDecoder().decode([TreatmentStep].self, from: data) {
            self.steps = saved
        } else {
            self.steps = initialSteps
        }
    }

    public func save() {
        if let data = try? JSONEncoder().encode(steps) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }
}
