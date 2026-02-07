//AppMode
import Foundation

enum AppMode: String, CaseIterable, Identifiable {
    case slice = "Slice Mode"
    case listening = "Listening Mode"

    var id: String { rawValue }
}
