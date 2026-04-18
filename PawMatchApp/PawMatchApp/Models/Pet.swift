import Foundation

struct PetAttributes: Codable {
    let requiresSpace: Bool?
    let catFriendly: Bool?
    let status: String?
}

struct Pet: Identifiable, Codable {
    let id: UUID
    let shelterId: UUID?
    let name: String?
    let age: Int?
    let breed: String?
    let description: String?
    let imageUrls: [String]?
    let donationGoal: Int?
    var currentDonations: Int?
    let attributes: PetAttributes?
    let createdAt: Date?
    var matchPercentage: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, age, breed, description
        case shelterId = "shelter_id"
        case imageUrls = "image_urls"
        case donationGoal = "donation_goal"
        case currentDonations = "current_donations"
        case attributes, createdAt = "created_at"
    }
}
