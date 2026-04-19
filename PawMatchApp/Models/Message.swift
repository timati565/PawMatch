import Foundation

struct Message: Codable, Identifiable {
    let id: UUID
    let matchId: UUID
    let senderId: UUID
    let text: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case matchId = "match_id"
        case senderId = "sender_id"
        case text
        case createdAt = "created_at"
    }
}
