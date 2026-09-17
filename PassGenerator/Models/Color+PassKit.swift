import SwiftUI
import AppKit

extension Color {
    /// Renders as the "rgb(r, g, b)" string format PassKit expects in pass.json.
    var passKitRGBString: String {
        let nsColor = NSColor(self).usingColorSpace(.deviceRGB) ?? NSColor(self)
        let r = Int(round(nsColor.redComponent * 255))
        let g = Int(round(nsColor.greenComponent * 255))
        let b = Int(round(nsColor.blueComponent * 255))
        return "rgb(\(r), \(g), \(b))"
    }
}
