// Core/Security/KeychainManager.swift
// KrishiDrishti — Secure generic Keychain operations wrapper

import Foundation
import Security

protocol KeychainManagerProtocol: Sendable {
    func save(key: String, data: Data) throws
    func read(key: String) throws -> Data?
    func delete(key: String) throws
}

final class KeychainManager: KeychainManagerProtocol {
    init() {}

    func save(key: String, data: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        // Delete any existing items first
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            throw NSError(domain: "KeychainManager", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Failed to save item in Keychain"])
        }
    }

    func read(key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecItemNotFound {
            return nil
        }

        if status != errSecSuccess {
            throw NSError(domain: "KeychainManager", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Failed to read item from Keychain"])
        }

        return dataTypeRef as? Data
    }

    func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw NSError(domain: "KeychainManager", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Failed to delete item from Keychain"])
        }
    }
}
