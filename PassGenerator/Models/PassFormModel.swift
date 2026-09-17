import Foundation
import SwiftUI

@MainActor
final class PassFormModel: ObservableObject {
    // MARK: Style
    @Published var style: PassStyle = .generic

    // MARK: Basic info
    @Published var organizationName: String = ""
    @Published var passDescription: String = ""
    @Published var passTypeIdentifier: String = ""
    @Published var teamIdentifier: String = ""
    @Published var serialNumber: String = UUID().uuidString

    // MARK: Colors
    @Published var backgroundColor: Color = .black
    @Published var foregroundColor: Color = .white
    @Published var labelColor: Color = .white

    // MARK: Fields
    @Published var headerFields: [PassFieldEntry] = []
    @Published var primaryFields: [PassFieldEntry] = [PassFieldEntry(key: "primary", label: "", value: "")]
    @Published var secondaryFields: [PassFieldEntry] = []
    @Published var auxiliaryFields: [PassFieldEntry] = []
    @Published var backFields: [PassFieldEntry] = []

    // MARK: Barcode
    @Published var barcodeEnabled: Bool = true
    @Published var barcodeFormat: BarcodeFormat = .qr
    @Published var barcodeMessage: String = ""
    @Published var barcodeAltText: String = ""

    // MARK: Images
    @Published var iconData: Data?
    @Published var logoData: Data?
    @Published var stripData: Data?
    @Published var thumbnailData: Data?

    // MARK: Certificates
    @Published var p12Data: Data?
    @Published var p12FileName: String = ""
    @Published var p12Password: String = ""
    @Published var wwdrData: Data?
    @Published var wwdrFileName: String = ""

    // MARK: Validation

    var missingRequiredFields: [String] {
        var missing: [String] = []
        if organizationName.trimmingCharacters(in: .whitespaces).isEmpty { missing.append("Organization Name") }
        if passDescription.trimmingCharacters(in: .whitespaces).isEmpty { missing.append("Description") }
        if passTypeIdentifier.trimmingCharacters(in: .whitespaces).isEmpty { missing.append("Pass Type Identifier") }
        if teamIdentifier.trimmingCharacters(in: .whitespaces).isEmpty { missing.append("Team Identifier") }
        if serialNumber.trimmingCharacters(in: .whitespaces).isEmpty { missing.append("Serial Number") }
        if iconData == nil { missing.append("Icon image") }
        if logoData == nil { missing.append("Logo image") }
        if p12Data == nil { missing.append("Pass certificate (.p12)") }
        if wwdrData == nil { missing.append("Apple WWDR certificate") }
        if barcodeEnabled && barcodeMessage.trimmingCharacters(in: .whitespaces).isEmpty { missing.append("Barcode message") }
        return missing
    }

    var canGenerate: Bool { missingRequiredFields.isEmpty }

    // MARK: pass.json

    func buildPassJSON() -> [String: Any] {
        var json: [String: Any] = [
            "formatVersion": 1,
            "passTypeIdentifier": passTypeIdentifier.trimmingCharacters(in: .whitespaces),
            "serialNumber": serialNumber.trimmingCharacters(in: .whitespaces),
            "teamIdentifier": teamIdentifier.trimmingCharacters(in: .whitespaces),
            "organizationName": organizationName,
            "description": passDescription,
            "backgroundColor": backgroundColor.passKitRGBString,
            "foregroundColor": foregroundColor.passKitRGBString,
            "labelColor": labelColor.passKitRGBString
        ]

        func fieldArray(_ entries: [PassFieldEntry]) -> [[String: String]] {
            entries.filter { $0.isValid }.map { $0.toDictionary() }
        }

        var styleDict: [String: Any] = [:]
        if !headerFields.isEmpty { styleDict["headerFields"] = fieldArray(headerFields) }
        if !primaryFields.isEmpty { styleDict["primaryFields"] = fieldArray(primaryFields) }
        if !secondaryFields.isEmpty { styleDict["secondaryFields"] = fieldArray(secondaryFields) }
        if !auxiliaryFields.isEmpty { styleDict["auxiliaryFields"] = fieldArray(auxiliaryFields) }
        if !backFields.isEmpty { styleDict["backFields"] = fieldArray(backFields) }
        json[style.jsonKey] = styleDict

        if barcodeEnabled, !barcodeMessage.trimmingCharacters(in: .whitespaces).isEmpty {
            var barcode: [String: Any] = [
                "format": barcodeFormat.rawValue,
                "message": barcodeMessage,
                "messageEncoding": "iso-8859-1"
            ]
            let trimmedAlt = barcodeAltText.trimmingCharacters(in: .whitespaces)
            if !trimmedAlt.isEmpty { barcode["altText"] = trimmedAlt }
            json["barcodes"] = [barcode]
            // Legacy key read by iOS versions prior to 9.
            json["barcode"] = barcode
        }

        return json
    }

    func regenerateSerialNumber() {
        serialNumber = UUID().uuidString
    }
}
