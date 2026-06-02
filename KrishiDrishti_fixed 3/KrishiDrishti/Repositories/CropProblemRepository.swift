// Repositories/CropProblemRepository.swift
// KrishiDrishti — Crop diagnosis historical repository linking CoreData local manager

import Foundation

protocol CropProblemRepositoryProtocol: Sendable {
    func getHistory() async throws -> [CropProblem]
    func addDiagnosis(_ diagnosis: CropProblem) async throws
    func deleteDiagnosis(withId id: UUID) async throws
    func clearHistory() async throws
}

final class CropProblemRepository: CropProblemRepositoryProtocol {
    private let dataManager: DataManagerProtocol

    init(dataManager: DataManagerProtocol = DIContainer.shared.resolve(type: DataManagerProtocol.self)) {
        self.dataManager = dataManager
    }

    func getHistory() async throws -> [CropProblem] {
        try await dataManager.fetchAllCropProblems()
    }

    func addDiagnosis(_ diagnosis: CropProblem) async throws {
        try await dataManager.insertCropProblem(diagnosis)
    }

    func deleteDiagnosis(withId id: UUID) async throws {
        try await dataManager.deleteCropProblem(withId: id)
    }

    func clearHistory() async throws {
        try await dataManager.clearAllHistory()
    }
}
