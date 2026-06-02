// Models/TreatmentStep.swift
// KrishiDrishti — Treatment checklist model

import Foundation
import SwiftUI

struct TreatmentStep: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var note: String

    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, note: String = "") {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.note = note
    }
}

@MainActor
final class TreatmentChecklist: ObservableObject {
    @Published var steps: [TreatmentStep]
    private let saveKey: String

    init(checklistID: String, initialSteps: [TreatmentStep]) {
        self.saveKey = "TreatmentChecklist_\(checklistID)"
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let saved = try? JSONDecoder().decode([TreatmentStep].self, from: data) {
            self.steps = saved
        } else {
            self.steps = initialSteps
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(steps) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }
}
