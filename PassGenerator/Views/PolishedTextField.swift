import SwiftUI

/// A filled, rounded text field with a leading icon and a colored focus ring —
/// used in place of the plain system `.roundedBorder` style throughout the form.
struct PolishedTextField: View {
    var icon: String? = nil
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var monospaced: Bool = false
    var tint: Color = .accentColor

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(isFocused ? tint : Color.secondary)
                    .frame(width: 16)
            }
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .textFieldStyle(.plain)
            .font(monospaced ? .system(.body, design: .monospaced) : .body)
            .focused($isFocused)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .textBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isFocused ? tint : Color.primary.opacity(0.12), lineWidth: isFocused ? 2 : 1)
        )
        .animation(.easeOut(duration: 0.15), value: isFocused)
    }
}
