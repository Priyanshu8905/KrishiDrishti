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

final class SecurityManager: SecurityManagerProtocol, @unchecked Sendable {

    private var symmetricKey: SymmetricKey {
        SymmetricKey(size: .bits256)
    }

    init() {}

    func isBiometricAvailable() -> Bool {
        var error: NSError?
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    func authenticateUser(reason: String) async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else { return false }
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
