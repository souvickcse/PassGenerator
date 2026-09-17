import Foundation
import Security

/// Produces the detached PKCS#7/CMS `signature` file PassKit requires, using the
/// public CMSEncoder API in Security.framework so no third-party crypto is needed.
enum PassSigner {
    static func sign(manifestData: Data, p12Data: Data, p12Password: String, wwdrData: Data) throws -> Data {
        let wwdrCertificate = try parseCertificate(from: wwdrData)

        return try withImportedIdentity(p12Data: p12Data, password: p12Password) { identity in
            var maybeEncoder: CMSEncoder?
            CMSEncoderCreate(&maybeEncoder)
            guard let encoder = maybeEncoder else {
                throw PassGeneratorError.signingFailed("Could not create a CMS encoder")
            }

            var status = CMSEncoderAddSigners(encoder, identity)
            guard status == errSecSuccess else {
                throw PassGeneratorError.signingFailed("Could not add the signer identity (OSStatus \(status))")
            }

            status = CMSEncoderAddSupportingCerts(encoder, wwdrCertificate)
            guard status == errSecSuccess else {
                throw PassGeneratorError.signingFailed("Could not attach the WWDR certificate (OSStatus \(status))")
            }

            // Only include the signer's own certificate plus the WWDR cert we added above —
            // not a full trust-evaluated chain and not the root.
            CMSEncoderSetCertificateChainMode(encoder, .signerOnly)
            CMSEncoderSetHasDetachedContent(encoder, true)

            // Wallet requires the signature to carry a signing-time attribute — without it,
            // installing the pass fails with "Signature must contain a signing date".
            status = CMSEncoderAddSignedAttributes(encoder, .attrSigningTime)
            guard status == errSecSuccess else {
                throw PassGeneratorError.signingFailed("Could not add the signing time (OSStatus \(status))")
            }

            status = manifestData.withUnsafeBytes { rawBuffer -> OSStatus in
                guard let baseAddress = rawBuffer.baseAddress else { return errSecParam }
                return CMSEncoderUpdateContent(encoder, baseAddress, manifestData.count)
            }
            guard status == errSecSuccess else {
                throw PassGeneratorError.signingFailed("Could not hand off manifest data to sign (OSStatus \(status))")
            }

            var maybeEncoded: CFData?
            status = CMSEncoderCopyEncodedContent(encoder, &maybeEncoded)
            guard status == errSecSuccess, let encoded = maybeEncoded else {
                throw PassGeneratorError.signingFailed("Could not finalize the signature (OSStatus \(status))")
            }

            return encoded as Data
        }
    }

    /// Imports the .p12 via a throwaway, file-backed keychain rather than `SecPKCS12Import`,
    /// keeps that keychain alive for the duration of `body`, and always tears it down after.
    ///
    /// `SecPKCS12Import` has a long-documented compatibility gap: it rejects some otherwise
    /// valid, correctly-passworded .p12 files (including ones Keychain Access and `security
    /// import` open without issue). Real-world tools like Fastlane work around this exact gap
    /// the same way, by importing into a temporary keychain via `SecItemImport` and then
    /// reading the resulting `SecIdentity` back out.
    ///
    /// A freshly-imported key also carries an ACL that blocks non-interactive use (signing
    /// would fail with `errSecInternalComponent`/-2070) unless its partition list is granted
    /// access — the same `security set-key-partition-list` step CI pipelines use for codesigning.
    private static func withImportedIdentity<T>(
        p12Data: Data,
        password: String,
        _ body: (SecIdentity) throws -> T
    ) throws -> T {
        let keychainPath = NSTemporaryDirectory() + "PassGenerator-\(UUID().uuidString).keychain"
        var keychain: SecKeychain?
        let keychainPassword = UUID().uuidString
        var status = SecKeychainCreate(
            keychainPath,
            UInt32(keychainPassword.utf8.count),
            keychainPassword,
            false,
            nil,
            &keychain
        )
        guard status == errSecSuccess, let tempKeychain = keychain else {
            throw PassGeneratorError.invalidP12
        }
        defer {
            SecKeychainDelete(tempKeychain)
            try? FileManager.default.removeItem(atPath: keychainPath)
        }

        var keyParams = SecItemImportExportKeyParameters(
            version: UInt32(SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION),
            flags: SecKeyImportExportFlags(rawValue: 0),
            passphrase: Unmanaged.passUnretained(password as CFString),
            alertTitle: nil,
            alertPrompt: nil,
            accessRef: nil,
            keyUsage: nil,
            keyAttributes: nil
        )
        var inputFormat = SecExternalFormat.formatPKCS12
        var itemType = SecExternalItemType.itemTypeAggregate
        status = SecItemImport(
            p12Data as CFData,
            "p12" as CFString,
            &inputFormat,
            &itemType,
            SecItemImportExportFlags(rawValue: 0),
            &keyParams,
            tempKeychain,
            nil
        )
        guard status == errSecSuccess else {
            throw PassGeneratorError.invalidP12
        }

        try grantPartitionListAccess(keychainPath: keychainPath, keychainPassword: keychainPassword)

        let query: [String: Any] = [
            kSecClass as String: kSecClassIdentity,
            kSecMatchSearchList as String: [tempKeychain],
            kSecReturnRef as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var identityRef: CFTypeRef?
        status = SecItemCopyMatching(query as CFDictionary, &identityRef)
        guard status == errSecSuccess, let identityValue = identityRef else {
            throw PassGeneratorError.invalidP12
        }

        return try body(identityValue as! SecIdentity)
    }

    private static func grantPartitionListAccess(keychainPath: String, keychainPassword: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        process.arguments = [
            "set-key-partition-list", "-S", "apple-tool:,apple:,codesign:",
            "-s", "-k", keychainPassword, keychainPath
        ]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw PassGeneratorError.signingFailed("Could not authorize the imported key for signing")
        }
    }

    /// Accepts a certificate as raw DER (the usual ".cer" download) or as PEM text
    /// ("-----BEGIN CERTIFICATE-----...") since both show up in the wild.
    private static func parseCertificate(from data: Data) throws -> SecCertificate {
        if let certificate = SecCertificateCreateWithData(nil, data as CFData) {
            return certificate
        }

        if let text = String(data: data, encoding: .utf8),
           text.contains("-----BEGIN CERTIFICATE-----") {
            let base64 = text
                .replacingOccurrences(of: "-----BEGIN CERTIFICATE-----", with: "")
                .replacingOccurrences(of: "-----END CERTIFICATE-----", with: "")
                .components(separatedBy: .newlines)
                .joined()
            if let derData = Data(base64Encoded: base64),
               let certificate = SecCertificateCreateWithData(nil, derData as CFData) {
                return certificate
            }
        }

        throw PassGeneratorError.invalidWWDR
    }
}
