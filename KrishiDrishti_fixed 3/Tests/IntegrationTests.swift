// Tests/IntegrationTests.swift
// KrishiDrishti Tests — Integration tests for database saving, repository calls, and viewmodel binding states

import XCTest
@testable import KrishiDrishti

@MainActor
final class KrishiDrishtiIntegrationTests: XCTestCase {

    var inMemoryPersistence: PersistenceController!
    var dataManager: DataManager!
    var cropRepository: CropProblemRepository!
    var scannerViewModel: ScannerViewModel!

    override func setUp() {
        super.setUp()
        // Initialize an in-memory database to prevent test contamination
        inMemoryPersistence = PersistenceController(inMemory: true)
        dataManager = DataManager(persistenceController: inMemoryPersistence)
        cropRepository = CropProblemRepository(dataManager: dataManager)

        let mockPredictionEngine = PredictionEngine()
        scannerViewModel = ScannerViewModel(
            predictionEngine: mockPredictionEngine,
            cropRepository: cropRepository
        )
    }

    override func tearDown() {
        inMemoryPersistence = nil
        dataManager = nil
        cropRepository = nil
        scannerViewModel = nil
        super.tearDown()
    }

    func testCoreDataInsertAndFetch() async throws {
        let originalCount = try await cropRepository.getHistory().count

        let diagnosis = CropProblem(
            cropName: "Tomato",
            disease: "Early Blight",
            scientificName: "Alternaria solani",
            remedy: "Spray fungicide",
            symptoms: ["spots", "yellow halo"],
            severity: .high,
            confidence: 0.95
        )

        try await cropRepository.addDiagnosis(diagnosis)

        let updatedHistory = try await cropRepository.getHistory()
        XCTAssertEqual(updatedHistory.count, originalCount + 1)
        XCTAssertEqual(updatedHistory.first?.disease, "Early Blight")
    }

    func testScannerViewModelCommitsDiagnosis() async throws {
        let diagnosis = CropProblem(
            cropName: "Wheat",
            disease: "Rust",
            scientificName: "Puccinia graminis",
            remedy: "Crop rotation",
            symptoms: ["orange spots"],
            severity: .medium,
            confidence: 0.88
        )

        scannerViewModel.commit(diagnosis)

        XCTAssertEqual(scannerViewModel.scanState, .diagnosed)
        XCTAssertEqual(scannerViewModel.currentDiagnosis?.disease, "Rust")
        XCTAssertEqual(scannerViewModel.scanHistory.first?.disease, "Rust")

        // Wait to verify DB persistence
        let dbHistory = try await cropRepository.getHistory()
        XCTAssertTrue(dbHistory.contains { $0.disease == "Rust" })
    }

    func testScannerViewModelDeletesDiagnosis() async throws {
        let diagnosis = CropProblem(
            cropName: "Potato",
            disease: "Late Blight",
            scientificName: "Phytophthora infestans",
            remedy: "Dry crop foliage",
            symptoms: ["leaf spot"],
            severity: .high,
            confidence: 0.92
        )

        scannerViewModel.commit(diagnosis)
        XCTAssertEqual(scannerViewModel.scanHistory.count, 1)

        let addedItem = try XCTUnwrap(scannerViewModel.scanHistory.first)
        scannerViewModel.deleteDiagnosis(withId: addedItem.id)

        XCTAssertEqual(scannerViewModel.scanHistory.count, 0)
    }
}
