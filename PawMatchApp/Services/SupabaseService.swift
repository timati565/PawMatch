
import Foundation
import Supabase

enum SupabaseServiceError: Error {
    case notAuthenticated
    case decodingError
    case unknown
}

class SupabaseService {
    static let shared = SupabaseService()
    let client: SupabaseClient

    private init() {
        
        let supabaseURL = URL(string: "https://rcrlsiznsfkjcjwsdxxf.supabase.co")!
        let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJjcmxzaXpuc2ZramNqd3NkeHhmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY0MjEyOTQsImV4cCI6MjA5MTk5NzI5NH0.1gu7LrD1ZfUShgI5ZzE6q4dbtkLLCqMJKTccpJuCMU8"
        client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
    }

    var currentUserID: UUID? {
        client.auth.currentUser?.id
    }

    
    func signUp(email: String, password: String, name: String, role: String) async throws {
        let metadata: [String: AnyJSON] = [
            "name": .string(name),
            "role": .string(role)
        ]
        let session = try await client.auth.signUp(email: email, password: password, data: metadata)
        
        let profile = User(
            id: session.user.id,
            email: email,
            role: role,
            onboardingAnswers: nil,
            onboardingCompleted: false,
            ratingAvg: nil,
            ratingCount: nil,
            likesCount: 0,
            matchesCount: 0,
            petsCount: 0,
            createdAt: Date()
        )
        _ = try await client.from("profiles").insert(profile).execute()
    }

    func signIn(email: String, password: String) async throws {
        _ = try await client.auth.signIn(email: email, password: password)
    }

    func signOut() async throws {
        _ = try await client.auth.signOut()
    }

    
    func fetchProfile() async throws -> User {
        guard let userID = currentUserID else { throw SupabaseServiceError.notAuthenticated }
        let profiles: [User] = try await client
            .from("profiles")
            .select()
            .eq("id", value: userID)
            .execute()
            .value
        
        if let existing = profiles.first {
            var user = existing
            user.name = client.auth.currentUser?.userMetadata["name"]?.stringValue
            return user
        } else {
            let role = client.auth.currentUser?.userMetadata["role"]?.stringValue ?? "adopter"
            let newUser = User(
                id: userID,
                email: client.auth.currentUser?.email ?? "",
                role: role,
                onboardingAnswers: nil,
                onboardingCompleted: false,
                ratingAvg: nil,
                ratingCount: nil,
                likesCount: 0,
                matchesCount: 0,
                petsCount: 0,
                createdAt: Date()
            )
            _ = try await client.from("profiles").insert(newUser).execute()
            var userWithName = newUser
            userWithName.name = client.auth.currentUser?.userMetadata["name"]?.stringValue
            return userWithName
        }
    }

    func updateOnboardingAnswers(_ answers: OnboardingAnswers) async throws {
        guard let userID = currentUserID else { throw SupabaseServiceError.notAuthenticated }
        _ = try await client
            .from("profiles")
            .update(["onboarding_answers": answers])
            .eq("id", value: userID)
            .execute()
    }

    
    func fetchPets(excludingSwipedPetIds: [UUID] = []) async throws -> [Pet] {
        let pets: [Pet] = try await client
            .from("pets")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
        return pets.filter { pet in
            !excludingSwipedPetIds.contains(pet.id) && pet.attributes?.status != "adopted"
        }
    }

    
    func addPet(_ pet: Pet) async throws {
        do {
            let response = try await client.from("pets").insert(pet).execute()
            print("✅ Supabase insert response: \(response.status)")
        } catch {
            print("❌ Supabase insert error: \(error)")
            throw error
        }
    }

    func updateDonations(petId: UUID, amount: Int) async throws {
        _ = try await client
            .from("pets")
            .update(["current_donations": amount])
            .eq("id", value: petId)
            .execute()
    }

    
    func fetchSwipedPetIds() async throws -> [UUID] {
        guard let userID = currentUserID else { throw SupabaseServiceError.notAuthenticated }
        let swipes: [Swipe] = try await client
            .from("swipes")
            .select("pet_id")
            .eq("user_id", value: userID)
            .execute()
            .value
        return swipes.map { $0.petId }
    }

    func recordSwipe(petId: UUID, action: Swipe.SwipeAction) async throws {
        guard let userID = currentUserID else { throw SupabaseServiceError.notAuthenticated }
        let swipe = Swipe(userId: userID, petId: petId, action: action)
        _ = try await client.from("swipes").insert(swipe).execute()
    }

    func checkMutualLike(userId: UUID, ownerId: UUID) async throws -> Bool {
        let swipes: [Swipe] = try await client
            .from("swipes")
            .select()
            .eq("user_id", value: ownerId)
            .eq("action", value: "LIKE")
            .execute()
            .value
        
        let myPets: [Pet] = try await client
            .from("pets")
            .select()
            .eq("shelter_id", value: userId)
            .execute()
            .value
        
        let myPetIds = Set(myPets.map { $0.id })
        return swipes.contains { myPetIds.contains($0.petId) }
    }

    
    func createMatch(userId: UUID, petId: UUID, shelterId: UUID) async throws {
        let match = Match(id: UUID(), userId: userId, petId: petId, shelterId: shelterId, createdAt: Date())
        _ = try await client.from("matches").insert(match).execute()
    }

    func fetchMatches() async throws -> [Match] {
        guard let userID = currentUserID else { throw SupabaseServiceError.notAuthenticated }
        return try await client
            .from("matches")
            .select()
            .or("user_id.eq.\(userID),shelter_id.eq.\(userID)")
            .order("created_at", ascending: false)
            .execute()
            .value
    }
    

    func submitShelterRating(matchId: UUID, rating: Int) async throws {
        _ = try await client
            .from("matches")
            .update(["shelter_rating": rating])
            .eq("id", value: matchId)
            .execute()
    }

    
    func fetchShelterRating(shelterId: UUID) async throws -> Double {
        
        struct RatingRow: Codable {
            let shelterRating: Int
            enum CodingKeys: String, CodingKey {
                case shelterRating = "shelter_rating"
            }
        }
        let rows: [RatingRow] = try await client
            .from("matches")
            .select("shelter_rating")
            .eq("shelter_id", value: shelterId)
            .execute()
            .value
        let ratings = rows.map { $0.shelterRating }
        guard !ratings.isEmpty else { return 0 }
        return Double(ratings.reduce(0, +)) / Double(ratings.count)
    }

    
    func fetchMessages(matchId: UUID) async throws -> [Message] {
        try await client
            .from("messages")
            .select()
            .eq("match_id", value: matchId)
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    func sendMessage(matchId: UUID, text: String) async throws {
        guard let userId = currentUserID else { throw SupabaseServiceError.notAuthenticated }
        let message = Message(id: UUID(), matchId: matchId, senderId: userId, text: text, createdAt: Date())
        _ = try await client.from("messages").insert(message).execute()
    }
}
