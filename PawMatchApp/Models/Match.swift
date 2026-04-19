import Foundation

struct Match: Codable, Identifiable, Hashable {
    let id: UUID
    let userId: UUID
    let petId: UUID
    let shelterId: UUID
    let createdAt: Date
    var shelterRating: Int?
    var pet: Pet?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case petId = "pet_id"
        case shelterId = "shelter_id"
        case createdAt = "created_at"
        case shelterRating = "shelter_rating"
    }
    
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Match, rhs: Match) -> Bool {
        lhs.id == rhs.id
    }
}
