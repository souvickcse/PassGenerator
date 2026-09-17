import Foundation
import CryptoKit

/// Builds pass.json, stages the pass bundle, signs the manifest, and zips it into a .pkpass.
@MainActor
enum PassPackager {
    static func generate(model: PassFormModel) throws -> URL {
        guard let iconData = model.iconData else {
            throw PassGeneratorError.missingRequiredData("icon.png")
        }
        guard let logoData = model.logoData else {
            throw PassGeneratorError.missingRequiredData("logo.png")
        }
        guard let p12Data = model.p12Data else {
            throw PassGeneratorError.missingRequiredData("Pass Type ID certificate (.p12)")
        }
        guard let wwdrData = model.wwdrData else {
            throw PassGeneratorError.missingRequiredData("WWDR certificate")
        }

        let fm = FileManager.default
        let workDir = fm.temporaryDirectory.appendingPathComponent("PassGenerator-\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: workDir, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: workDir) }

        // 1. pass.json
        let passJSON = model.buildPassJSON()
        let passData = try JSONSerialization.data(withJSONObject: passJSON, options: [.prettyPrinted, .sortedKeys])
        try passData.write(to: workDir.appendingPathComponent("pass.json"))

        // 2. Images (the same source file is used for @1x/@2x; PassKit accepts this,
        // it just won't be pixel-perfect on Retina displays).
        var imageFiles: [String: Data] = [
            "icon.png": iconData,
            "icon@2x.png": iconData,
            "logo.png": logoData,
            "logo@2x.png": logoData
        ]
        if let stripData = model.stripData {
            imageFiles["strip.png"] = stripData
            imageFiles["strip@2x.png"] = stripData
        }
        if let thumbnailData = model.thumbnailData {
            imageFiles["thumbnail.png"] = thumbnailData
            imageFiles["thumbnail@2x.png"] = thumbnailData
        }
        for (name, data) in imageFiles {
            try data.write(to: workDir.appendingPathComponent(name))
        }

        // 3. manifest.json — SHA-1 of every file in the bundle except the manifest/signature themselves.
        var manifest: [String: String] = ["pass.json": sha1Hex(passData)]
        for (name, data) in imageFiles {
            manifest[name] = sha1Hex(data)
        }
        let manifestData = try JSONSerialization.data(withJSONObject: manifest, options: [.sortedKeys])
        try manifestData.write(to: workDir.appendingPathComponent("manifest.json"))

        // 4. signature
        let signatureData = try PassSigner.sign(
            manifestData: manifestData,
            p12Data: p12Data,
            p12Password: model.p12Password,
            wwdrData: wwdrData
        )
        try signatureData.write(to: workDir.appendingPathComponent("signature"))

        // 5. Zip the bundle contents (not the folder itself) into a .pkpass.
        let safeName = model.serialNumber
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "/", with: "-")
        let outputURL = fm.temporaryDirectory.appendingPathComponent("\(safeName.isEmpty ? "pass" : safeName).pkpass")
        if fm.fileExists(atPath: outputURL.path) {
            try fm.removeItem(at: outputURL)
        }
        try zipDirectoryContents(workDir, to: outputURL)

        return outputURL
    }

    private static func sha1Hex(_ data: Data) -> String {
        Insecure.SHA1.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private static func zipDirectoryContents(_ directory: URL, to destination: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.currentDirectoryURL = directory
        process.arguments = ["-r", "-X", destination.path, "."]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw PassGeneratorError.zipFailed(output.isEmpty ? "zip exited with status \(process.terminationStatus)" : output)
        }
    }
}
