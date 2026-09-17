import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var model = PassFormModel()

    @State private var isGenerating = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    @State private var successPath = ""
    @State private var didCopySerialNumber = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                SectionCard(title: "Pass Type", systemImage: "square.stack.3d.up.fill", tint: .indigo) {
                    styleSection
                }
                SectionCard(title: "Pass Details", systemImage: "doc.text.fill", tint: .blue) {
                    basicInfoSection
                }
                SectionCard(title: "Colors", systemImage: "paintpalette.fill", tint: .pink) {
                    colorSection
                }
                SectionCard(title: "Images", systemImage: "photo.fill", tint: .orange) {
                    imagesSection
                }
                SectionCard(title: "Fields", systemImage: "list.bullet.rectangle.fill", tint: .green) {
                    fieldsSection
                }
                SectionCard(title: "Barcode", systemImage: "qrcode", tint: .teal) {
                    barcodeSection
                }
                SectionCard(title: "Signing Certificates", systemImage: "checkmark.seal.fill", tint: .red) {
                    certificatesSection
                }

                generateSection
            }
            .padding(24)
        }
        .frame(minWidth: 700, idealWidth: 760, minHeight: 780, idealHeight: 900)
        .background(
            LinearGradient(
                colors: [Color.indigo.opacity(0.08), Color(nsColor: .windowBackgroundColor)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .alert("Couldn't Create Pass", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Pass Created", isPresented: $showingSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Saved to \(successPath)")
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LinearGradient(colors: [.indigo, .purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 52, height: 52)
                Image(systemName: "wallet.pass.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Pass Generator")
                    .font(.largeTitle.bold())
                Text("Build a signed Apple Wallet (.pkpass) file")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.bottom, 4)
    }

    // MARK: Style

    private var styleSection: some View {
        Picker("Pass Type", selection: $model.style) {
            ForEach(PassStyle.allCases) { style in
                Text(style.displayName).tag(style)
            }
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        .tint(.indigo)
    }

    // MARK: Basic info

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            LabeledField(title: "Organization Name", required: true) {
                PolishedTextField(icon: "building.2.fill", placeholder: "Acme Corp", text: $model.organizationName, tint: .blue)
            }
            LabeledField(title: "Description", required: true) {
                PolishedTextField(icon: "text.alignleft", placeholder: "Shown as the pass's accessibility description", text: $model.passDescription, tint: .blue)
            }
            LabeledField(title: "Pass Type Identifier", required: true, docURL: AppleDocs.passTypeIdentifier) {
                PolishedTextField(icon: "tag.fill", placeholder: "pass.com.yourcompany.passname", text: $model.passTypeIdentifier, monospaced: true, tint: .blue)
            }
            LabeledField(title: "Team Identifier", required: true, docURL: AppleDocs.teamIdentifier) {
                PolishedTextField(icon: "person.badge.key.fill", placeholder: "10-character Apple Developer Team ID", text: $model.teamIdentifier, monospaced: true, tint: .blue)
            }
            LabeledField(title: "Serial Number", required: true) {
                HStack(spacing: 10) {
                    PolishedTextField(icon: "number", placeholder: "Unique per pass", text: $model.serialNumber, monospaced: true, tint: .blue)
                    Button {
                        copySerialNumber()
                    } label: {
                        Image(systemName: didCopySerialNumber ? "checkmark" : "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                    .tint(didCopySerialNumber ? .green : .blue)
                    .help("Copy serial number")
                    Button {
                        model.regenerateSerialNumber()
                    } label: {
                        Label("New", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                }
            }
        }
    }

    // MARK: Colors

    private var colorSection: some View {
        HStack(spacing: 28) {
            ColorPicker("Background", selection: $model.backgroundColor, supportsOpacity: false)
            ColorPicker("Foreground", selection: $model.foregroundColor, supportsOpacity: false)
            ColorPicker("Label", selection: $model.labelColor, supportsOpacity: false)
            Spacer()
        }
        .fontWeight(.medium)
    }

    // MARK: Images

    private var imagesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            ImagePickerRow(title: "Icon", subtitle: "Required · shown in notifications and Wallet list", required: true, data: $model.iconData)
            ImagePickerRow(title: "Logo", subtitle: "Required · shown at the top of the pass", required: true, data: $model.logoData)
            if model.style.usesStripImage {
                ImagePickerRow(title: "Strip", subtitle: "Optional · background artwork", data: $model.stripData)
            }
            if model.style.usesThumbnailImage {
                ImagePickerRow(title: "Thumbnail", subtitle: "Optional · shown beside the primary fields", data: $model.thumbnailData)
            }
        }
    }

    // MARK: Fields

    private var fieldsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            FieldsSectionView(title: "Header Fields", tint: .green, fields: $model.headerFields)
            FieldsSectionView(title: "Primary Fields", tint: .green, fields: $model.primaryFields)
            FieldsSectionView(title: "Secondary Fields", tint: .green, fields: $model.secondaryFields)
            FieldsSectionView(title: "Auxiliary Fields", tint: .green, fields: $model.auxiliaryFields)
            FieldsSectionView(title: "Back Fields", tint: .green, fields: $model.backFields)
        }
    }

    // MARK: Barcode

    private var barcodeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Include Barcode", isOn: $model.barcodeEnabled)
                .tint(.teal)
                .fontWeight(.medium)
            if model.barcodeEnabled {
                Picker("Format", selection: $model.barcodeFormat) {
                    ForEach(BarcodeFormat.allCases) { format in
                        Text(format.displayName).tag(format)
                    }
                }
                .pickerStyle(.segmented)
                .tint(.teal)
                LabeledField(title: "Message", required: true) {
                    PolishedTextField(icon: "qrcode", placeholder: "Encoded value, e.g. a member ID", text: $model.barcodeMessage, tint: .teal)
                }
                LabeledField(title: "Alt Text") {
                    PolishedTextField(icon: "textformat", placeholder: "Optional text shown under the barcode", text: $model.barcodeAltText, tint: .teal)
                }
            }
        }
    }

    // MARK: Certificates

    private var certificatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upload your Pass Type ID certificate (exported as .p12) and Apple's WWDR intermediate certificate.")
                .font(.caption)
                .foregroundStyle(.secondary)

            FilePickerRow(title: "Pass Certificate (.p12)", subtitle: "Exported from Keychain Access", required: true, docURL: AppleDocs.buildingAPass, data: $model.p12Data, fileName: $model.p12FileName)
            LabeledField(title: "Certificate Password") {
                PolishedTextField(icon: "key.fill", placeholder: "Leave blank if the .p12 has no password", text: $model.p12Password, isSecure: true, tint: .red)
            }
            FilePickerRow(title: "Apple WWDR Certificate", subtitle: "Worldwide Developer Relations intermediate certificate", required: true, docURL: AppleDocs.wwdrCertificate, data: $model.wwdrData, fileName: $model.wwdrFileName)
        }
    }

    // MARK: Generate

    private var generateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !model.missingRequiredFields.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Missing: \(model.missingRequiredFields.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.orange.opacity(0.12))
                )
            }
            HStack {
                Button {
                    generate()
                } label: {
                    HStack(spacing: 8) {
                        if isGenerating {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "wallet.pass.fill")
                        }
                        Text(isGenerating ? "Generating…" : "Generate .pkpass…")
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
                .controlSize(.large)
                .disabled(!model.canGenerate || isGenerating)
                Spacer()
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 20)
    }

    private func copySerialNumber() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(model.serialNumber, forType: .string)
        didCopySerialNumber = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            didCopySerialNumber = false
        }
    }

    private func generate() {
        isGenerating = true
        defer { isGenerating = false }
        do {
            let tempURL = try PassPackager.generate(model: model)
            defer { try? FileManager.default.removeItem(at: tempURL) }

            let panel = NSSavePanel()
            panel.title = "Save Pass"
            panel.nameFieldStringValue = tempURL.lastPathComponent
            if let pkpassType = UTType(filenameExtension: "pkpass") {
                panel.allowedContentTypes = [pkpassType]
            }

            if panel.runModal() == .OK, let destination = panel.url {
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.copyItem(at: tempURL, to: destination)
                successPath = destination.path
                showingSuccess = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

/// A card container with a colored icon badge and title, used to visually group each section of the form.
private struct SectionCard<Content: View>: View {
    let title: String
    let systemImage: String
    let tint: Color
    var docURL: URL? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(tint.gradient)
                        .frame(width: 30, height: 30)
                    Image(systemName: systemImage)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Text(title)
                    .font(.headline)
                if let docURL {
                    DocInfoButton(url: docURL)
                }
            }
            content
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(tint.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }
}

/// A titled row with an optional required-marker wrapped around a control (usually a TextField).
private struct LabeledField<Content: View>: View {
    let title: String
    var required: Bool = false
    var docURL: URL? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 3) {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.4)
                    .foregroundStyle(.secondary)
                if required {
                    Text("*").font(.system(size: 11, weight: .semibold)).foregroundStyle(.red)
                }
                if let docURL {
                    DocInfoButton(url: docURL)
                }
            }
            content
        }
    }
}

#Preview {
    ContentView()
}
