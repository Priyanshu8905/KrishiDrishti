// Managers/PersistenceController.swift
// KrishiDrishti — Thread-safe CoreData persistence layer with programmatic model description

import CoreData

final class PersistenceController: Sendable {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    // In-memory option for Unit Tests
    init(inMemory: Bool = false) {
        let model = Self.createManagedObjectModel()
        container = NSPersistentContainer(name: "KrishiDrishti", managedObjectModel: model)

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.url = URL(fileURLWithPath: "/dev/null")
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    private static func createManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let cropProblemEntity = NSEntityDescription()
        cropProblemEntity.name = "CropProblemEntity"
        cropProblemEntity.managedObjectClassName = "NSManagedObject"

        let id = NSAttributeDescription()
        id.name = "id"
        id.attributeType = .UUIDAttributeType
        id.isOptional = false

        let cropName = NSAttributeDescription()
        cropName.name = "cropName"
        cropName.attributeType = .stringAttributeType
        cropName.isOptional = false

        let disease = NSAttributeDescription()
        disease.name = "disease"
        disease.attributeType = .stringAttributeType
        disease.isOptional = false

        let scientificName = NSAttributeDescription()
        scientificName.name = "scientificName"
        scientificName.attributeType = .stringAttributeType
        scientificName.isOptional = false

        let remedy = NSAttributeDescription()
        remedy.name = "remedy"
        remedy.attributeType = .stringAttributeType
        remedy.isOptional = false

        let severity = NSAttributeDescription()
        severity.name = "severity"
        severity.attributeType = .stringAttributeType
        severity.isOptional = false

        let confidence = NSAttributeDescription()
        confidence.name = "confidence"
        confidence.attributeType = .doubleAttributeType
        confidence.isOptional = false

        let scannedAt = NSAttributeDescription()
        scannedAt.name = "scannedAt"
        scannedAt.attributeType = .dateAttributeType
        scannedAt.isOptional = false

        let symptomsData = NSAttributeDescription()
        symptomsData.name = "symptomsData"
        symptomsData.attributeType = .binaryDataAttributeType
        symptomsData.isOptional = true

        cropProblemEntity.properties = [
            id, cropName, disease, scientificName, remedy, severity, confidence, scannedAt, symptomsData
        ]

        model.entities = [cropProblemEntity]
        return model
    }

    func saveContext(_ context: NSManagedObjectContext) throws {
        if context.hasChanges {
            try context.save()
        }
    }
}
