import Foundation

enum PassGeneratorError: LocalizedError {
    case missingRequiredData(String)
    case invalidP12
    case invalidWWDR
    case signingFailed(String)
    case zipFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingRequiredData(let field):
            return "Missing required data: \(field)"
        case .invalidP12:
            return "The certificate file (.p12) could not be read. Check the file and password and try again."
        case .invalidWWDR:
            return "The Apple WWDR certificate file could not be read. Make sure it's a valid .cer/.pem certificate."
        case .signingFailed(let reason):
            return "Signing the pass failed: \(reason)"
        case .zipFailed(let reason):
            return "Could not create the .pkpass archive: \(reason)"
        }
    }
}
