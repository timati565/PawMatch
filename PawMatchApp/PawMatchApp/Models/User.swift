import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    let email: String
    let role: String?
    let onboardingAnswers: OnboardingAnswers?
    let onboardingCompleted: Bool?
    let ratingAvg: Double?
    let ratingCount: Int?
    let likesCount: Int?
    let matchesCount: Int?
    let petsCount: Int?
    let createdAt: Date?
    var name: String?
    
    enum CodingKeys: String, CodingKey {
        case id, email, role
        case onboardingAnswers = "onboarding_answers"
        case onboardingCompleted = "onboarding_completed"
        case ratingAvg = "rating_avg"
        case ratingCount = "rating_count"
        case likesCount = "likes_count"
        case matchesCount = "matches_count"
        case petsCount = "pets_count"
        case createdAt = "created_at"
        case name
    }
}

struct OnboardingAnswers: Codable {
    var housing: String?
    var activity: String?
    var otherPets: String?
    
    enum CodingKeys: String, CodingKey {
        case housing, activity
        case otherPets = "other_pets"
    }
}
