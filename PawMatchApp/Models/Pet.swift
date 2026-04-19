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
    let type: String?
    let description: String?
    let imageUrls: [String]?
    let donationGoal: Int?
    var currentDonations: Int?
    let attributes: PetAttributes?
    let createdAt: Date?
    var matchPercentage: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, age, breed, type, description
        case shelterId = "shelter_id"
        case imageUrls = "image_urls"
        case donationGoal = "donation_goal"
        case currentDonations = "current_donations"
        case attributes, createdAt = "created_at"
    }

    
    init(id: UUID = UUID(),
         shelterId: UUID? = nil,
         name: String? = nil,
         age: Int? = nil,
         breed: String? = nil,
         type: String? = nil,
         description: String? = nil,
         imageUrls: [String]? = nil,
         donationGoal: Int? = nil,
         currentDonations: Int? = nil,
         attributes: PetAttributes? = nil,
         createdAt: Date? = nil,
         matchPercentage: Int? = nil) {
        self.id = id
        self.shelterId = shelterId
        self.name = name
        self.age = age
        self.breed = breed
        self.type = type
        self.description = description
        self.imageUrls = imageUrls
        self.donationGoal = donationGoal
        self.currentDonations = currentDonations
        self.attributes = attributes
        self.createdAt = createdAt
        self.matchPercentage = matchPercentage
    }
}
