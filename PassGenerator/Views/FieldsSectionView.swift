import SwiftUI

/// Editable list of key/label/value rows for one PassKit field group
/// (headerFields, primaryFields, secondaryFields, auxiliaryFields, backFields).
struct FieldsSectionView: View {
    let title: String
    var tint: Color = .accentColor
    var docURL: URL? = nil
    @Binding var fields: [PassFieldEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tint)
                if let docURL {
                    DocInfoButton(url: docURL)
                }
                Spacer()
                Button {
                    fields.append(PassFieldEntry())
                } label: {
                    Label("Add Field", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderless)
                .tint(tint)
            }

            if fields.isEmpty {
                Text("No fields added").font(.caption).foregroundStyle(.secondary)
            } else {
                HStack {
                    Text("Key").font(.caption).foregroundStyle(.secondary).frame(width: 110, alignment: .leading)
                    Text("Label").font(.caption).foregroundStyle(.secondary)
                    Text("Value").font(.caption).foregroundStyle(.secondary)
                    Spacer().frame(width: 28)
                }
                ForEach($fields) { $field in
                    HStack {
                        TextField("e.g. balance", text: $field.key)
                            .frame(width: 110)
                        TextField("Shown label", text: $field.label)
                        TextField("Value", text: $field.value)
                        Button {
                            fields.removeAll { $0.id == field.id }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(.red)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(tint.opacity(0.06))
        )
        .textFieldStyle(.roundedBorder)
    }
}
