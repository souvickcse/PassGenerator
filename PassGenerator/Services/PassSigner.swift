import Foundation
import Security

/// Produces the detached PKCS#7/CMS `signature` file PassKit requires, using the
/// public CMSEncoder API in Security.framework so no third-party crypto is needed.
enum PassSigner {
    static func sign(manifestData: Data, p12Data: Data, p12Password: String, wwdrData: Data) throws -> Data {
        let identity = try importIdentity(p12Data: p12Data, password: p12Password)
        let wwdrCertificate = try parseCertificate(from: wwdrData)

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

    private static func importIdentity(p12Data: Data, password: String) throws -> SecIdentity {
        let options: [String: Any] = [kSecImportExportPassphrase as String: password]
        var rawItems: CFArray?
        let status = SecPKCS12Import(p12Data as CFData, options as CFDictionary, &rawItems)

        guard status == errSecSuccess,
              let items = rawItems as? [[String: Any]],
              let firstItem = items.first,
              let identityValue = firstItem[kSecImportItemIdentity as String] else {
            throw PassGeneratorError.invalidP12
        }

        // SecPKCS12Import hands back a CFTypeRef which is a SecIdentity for this key.
        return (identityValue as! SecIdentity)
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
