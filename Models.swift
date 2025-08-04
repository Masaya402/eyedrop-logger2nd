import Foundation

enum EyeDropType: String, CaseIterable, Identifiable, Codable {
    case typeA = "Type A"
    case typeB = "Type B"
    case typeC = "Type C"
    
    var id: String { rawValue }
}

struct EyeDropEntry: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let type: EyeDropType
}
