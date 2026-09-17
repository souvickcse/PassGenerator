import Foundation

enum BarcodeFormat: String, CaseIterable, Identifiable {
    case qr = "PKBarcodeFormatQR"
    case pdf417 = "PKBarcodeFormatPDF417"
    case aztec = "PKBarcodeFormatAztec"
    case code128 = "PKBarcodeFormatCode128"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .qr: return "QR Code"
        case .pdf417: return "PDF417"
        case .aztec: return "Aztec"
        case .code128: return "Code 128"
        }
    }
}
