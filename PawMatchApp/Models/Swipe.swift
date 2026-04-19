import Foundation

struct Swipe: Codable {
    let userId: UUID
    let petId: UUID
    let action: SwipeAction
    let createdAt: Date?
    
    init(userId: UUID, petId: UUID, action: SwipeAction) {
        self.userId = userId
        self.petId = petId
        self.action = action
        self.createdAt = nil
    }
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case petId = "pet_id"
        case action
        case createdAt = "created_at"
    }
    
    enum SwipeAction: String, Codable {
        case like = "LIKE"
        case pass = "PASS"
    }
}
