import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// A labeled row that lets the user choose a PNG for one of the pass's images (icon, logo, strip, thumbnail).
struct ImagePickerRow: View {
    let title: String
    let subtitle: String
    var required: Bool = false
    @Binding var data: Data?

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(title)
                    if required {
                        Text("*").foregroundStyle(.red)
                    }
                }
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: 40, height: 40)
                if let data, let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .cornerRadius(4)
                } else {
                    Image(systemName: "photo")
                        .foregroundStyle(.orange)
                }
            }

            Button {
                pickImage()
            } label: {
                Label(data == nil ? "Choose…" : "Change…", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.bordered)
            .tint(.orange)

            if data != nil {
                Button {
                    data = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.red)
            }
        }
    }

    private func pickImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        if panel.runModal() == .OK, let url = panel.url {
            data = try? Data(contentsOf: url)
        }
    }
}
