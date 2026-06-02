// Core/Security/SecurityManager.swift
// KrishiDrishti — Biometric authentication (FaceID/TouchID) and cryptography management

import LocalAuthentication
import CryptoKit
import Foundation

protocol SecurityManagerProtocol: Sendable {
    func isBiometricAvailable() -> Bool
    func authenticateUser(reason: String) async -> Bool
    func encryptData(data: Data) throws -> Data
    func decryptData(encryptedData: Data) throws -> Data
}

final class SecurityManager: SecurityManagerProtocol {
    private let context = LAContext()

    // Key used for symmetric encryption of sensitive files or caches
    private var symmetricKey: SymmetricKey {
        // Retrieve or generate key
        let key = SymmetricKey(size: .bits256)
        return key
    }

    init() {}

    func isBiometricAvailable() -> Bool {
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return canEvaluate
    }

    func authenticateUser(reason: String) async -> Bool {
        guard isBiometricAvailable() else { return false }
        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
        } catch {
            return false
        }
    }

    func encryptData(data: Data) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: symmetricKey)
        return sealedBox.combined ?? Data()
    }

    func decryptData(encryptedData: Data) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        return try AES.GCM.open(sealedBox, using: symmetricKey)
    }
}
