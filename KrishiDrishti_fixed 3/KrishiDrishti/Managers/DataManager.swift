// Managers/DataManager.swift
// KrishiDrishti — General data access object using Repository design pattern

import CoreData
import Foundation

protocol DataManagerProtocol: Sendable {
    func fetchAllCropProblems() async throws -> [CropProblem]
    func insertCropProblem(_ problem: CropProblem) async throws
    func deleteCropProblem(withId id: UUID) async throws
    func clearAllHistory() async throws
}

final class DataManager: DataManagerProtocol {
    private let persistenceController: PersistenceController

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    func fetchAllCropProblems() async throws -> [CropProblem] {
        let context = persistenceController.container.viewContext
        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "CropProblemEntity")
            let sortDescriptor = NSSortDescriptor(key: "scannedAt", ascending: false)
            request.sortDescriptors = [sortDescriptor]

            let results = try context.fetch(request)
            return results.compactMap { obj in
                guard let id = obj.value(forKey: "id") as? UUID,
                      let cropName = obj.value(forKey: "cropName") as? String,
                      let disease = obj.value(forKey: "disease") as? String,
                      let scientificName = obj.value(forKey: "scientificName") as? String,
                      let remedy = obj.value(forKey: "remedy") as? String,
                      let severityStr = obj.value(forKey: "severity") as? String,
                      let severity = Severity(rawValue: severityStr),
                      let confidence = obj.value(forKey: "confidence") as? Double,
                      let scannedAt = obj.value(forKey: "scannedAt") as? Date else {
                    return nil
                }

                let symptoms: [String]
                if let data = obj.value(forKey: "symptomsData") as? Data {
                    symptoms = (try? JSONDecoder().decode([String].self, from: data)) ?? []
                } else {
                    symptoms = []
                }

                return CropProblem(
                    id: id,
                    cropName: cropName,
                    disease: disease,
                    scientificName: scientificName,
                    remedy: remedy,
                    symptoms: symptoms,
                    severity: severity,
                    confidence: confidence,
                    scannedAt: scannedAt
                )
            }
        }
    }

    func insertCropProblem(_ problem: CropProblem) async throws {
        let backgroundContext = persistenceController.container.newBackgroundContext()
        try await backgroundContext.perform {
            let entity = NSEntityDescription.entity(forEntityName: "CropProblemEntity", in: backgroundContext)!
            let obj = NSManagedObject(entity: entity, insertInto: backgroundContext)

            obj.setValue(problem.id, forKey: "id")
            obj.setValue(problem.cropName, forKey: "cropName")
            obj.setValue(problem.disease, forKey: "disease")
            obj.setValue(problem.scientificName, forKey: "scientificName")
            obj.setValue(problem.remedy, forKey: "remedy")
            obj.setValue(problem.severity.rawValue, forKey: "severity")
            obj.setValue(problem.confidence, forKey: "confidence")
            obj.setValue(problem.scannedAt, forKey: "scannedAt")

            if let symptomsData = try? JSONEncoder().encode(problem.symptoms) {
                obj.setValue(symptomsData, forKey: "symptomsData")
            }

            try self.persistenceController.saveContext(backgroundContext)
        }
    }

    func deleteCropProblem(withId id: UUID) async throws {
        let backgroundContext = persistenceController.container.newBackgroundContext()
        try await backgroundContext.perform {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CropProblemEntity")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            try backgroundContext.execute(deleteRequest)
            try self.persistenceController.saveContext(backgroundContext)
        }
    }

    func clearAllHistory() async throws {
        let backgroundContext = persistenceController.container.newBackgroundContext()
        try await backgroundContext.perform {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CropProblemEntity")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            try backgroundContext.execute(deleteRequest)
            try self.persistenceController.saveContext(backgroundContext)
        }
    }
}
