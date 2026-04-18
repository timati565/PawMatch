// MessagesViewModel.swift
import SwiftUI

@MainActor
class MessagesViewModel: ObservableObject {
    @Published var matches: [Match] = []
    @Published var activeMatch: Match?
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var showRatingSheet = false

    private let service = SupabaseService.shared

    var currentUserId: UUID? {
        service.currentUserID
    }

    func loadMatches() async {
        do {
            var loadedMatches = try await service.fetchMatches()
            for i in loadedMatches.indices {
                let pets: [Pet] = try await service.client
                    .from("pets")
                    .select()
                    .eq("id", value: loadedMatches[i].petId)
                    .execute()
                    .value
                loadedMatches[i].pet = pets.first
            }
            matches = loadedMatches
        } catch {
            print("Load matches error: \(error)")
        }
    }

    func selectMatch(_ match: Match) {
        activeMatch = match
        Task { await loadMessages(for: match) }
    }

    func loadMessages(for match: Match) async {
        do {
            messages = try await service.fetchMessages(matchId: match.id)
        } catch {
            print("Load messages error: \(error)")
        }
    }

    func sendMessage(text: String) async {
        guard let match = activeMatch else { return }
        do {
            try await service.sendMessage(matchId: match.id, text: text)
            await loadMessages(for: match)
        } catch {
            print("Send message error: \(error)")
        }
    }

    func submitRating(for match: Match, rating: Int) async {
        do {
            try await service.submitShelterRating(matchId: match.id, rating: rating)
        } catch {
            print("Ошибка отправки рейтинга: \(error)")
        }
    }
}
