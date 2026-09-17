import SwiftUI
import AppKit

/// A labeled row that lets the user choose an arbitrary file (used for the .p12 certificate and the WWDR certificate).
struct FilePickerRow: View {
    let title: String
    let subtitle: String
    var required: Bool = false
    @Binding var data: Data?
    @Binding var fileName: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill((data == nil ? Color.red : Color.green).opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: data == nil ? "lock.doc" : "checkmark.seal.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(data == nil ? Color.red : Color.green)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(title)
                    if required {
                        Text("*").foregroundStyle(.red)
                    }
                }
                Text(fileName.isEmpty ? subtitle : fileName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                pickFile()
            } label: {
                Label(data == nil ? "Choose…" : "Change…", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.bordered)
            .tint(.red)

            if data != nil {
                Button {
                    data = nil
                    fileName = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.red)
            }
        }
    }

    private func pickFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        // Certificate files show up with a variety of extensions/UTIs (.p12, .pfx, .cer, .pem, .crt),
        // so we accept any file rather than restricting content types.
        if panel.runModal() == .OK, let url = panel.url {
            data = try? Data(contentsOf: url)
            fileName = url.lastPathComponent
        }
    }
}
