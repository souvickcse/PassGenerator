import Foundation

enum PassStyle: String, CaseIterable, Identifiable {
    case generic
    case storeCard
    case coupon
    case eventTicket

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .generic: return "Generic"
        case .storeCard: return "Store Card"
        case .coupon: return "Coupon"
        case .eventTicket: return "Event Ticket"
        }
    }

    /// Key used to nest the style-specific field groups inside pass.json.
    var jsonKey: String {
        switch self {
        case .generic: return "generic"
        case .storeCard: return "storeCard"
        case .coupon: return "coupon"
        case .eventTicket: return "eventTicket"
        }
    }

    /// Whether a strip image is the conventional artwork for this style.
    var usesStripImage: Bool {
        switch self {
        case .storeCard, .coupon, .eventTicket: return true
        case .generic: return false
        }
    }

    /// Whether a thumbnail image is the conventional artwork for this style.
    var usesThumbnailImage: Bool {
        switch self {
        case .generic, .storeCard: return true
        case .coupon, .eventTicket: return false
        }
    }
}
