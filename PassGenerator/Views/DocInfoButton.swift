import SwiftUI
import AppKit

/// A small "ⓘ" button shown next to fields that map directly to an Apple PassKit
/// concept. Clicking it opens Apple's own documentation for that field/topic.
struct DocInfoButton: View {
    let url: URL
    var help: String = "Open Apple's documentation for this field"

    var body: some View {
        Button {
            NSWorkspace.shared.open(url)
        } label: {
            Image(systemName: "info.circle")
                .font(.system(size: 11))
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.secondary)
        .help(help)
    }
}

/// Apple documentation links referenced from the form. Centralized here so URLs
/// are easy to audit/update in one place.
enum AppleDocs {
    /// The core "Pass" reference — documents organizationName, description, passTypeIdentifier,
    /// teamIdentifier, serialNumber, and the three colors directly on one page.
    static let pass = URL(string: "https://developer.apple.com/documentation/walletpasses/pass")!
    static let organizationName = pass
    static let description = pass
    static let passTypeIdentifier = pass
    static let teamIdentifier = pass
    static let serialNumber = pass
    static let backgroundColor = pass
    static let foregroundColor = pass
    static let labelColor = pass

    /// Covers headerFields/primaryFields/secondaryFields/auxiliaryFields/backFields.
    static let passFields = URL(string: "https://developer.apple.com/documentation/walletpasses/passfields")!
    static let headerFields = passFields
    static let primaryFields = passFields
    static let secondaryFields = passFields
    static let auxiliaryFields = passFields
    static let backFields = passFields

    static let barcodes = URL(string: "https://developer.apple.com/documentation/walletpasses/pass/barcodes-data.dictionary")!

    /// Directory structure and image files (icon/logo/strip/thumbnail).
    static let creatingSource = URL(string: "https://developer.apple.com/documentation/walletpasses/creating-the-source-for-a-pass")!

    /// The manifest/signature/certificate signing process.
    static let buildingAPass = URL(string: "https://developer.apple.com/documentation/walletpasses/building-a-pass")!

    /// Apple's PKI page hosting the downloadable WWDR intermediate certificate.
    static let wwdrCertificate = URL(string: "https://www.apple.com/certificateauthority/")!
}
