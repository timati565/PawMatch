import SwiftUI

struct PawMatchHeader: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "pawprint.fill")
                .font(.title2)
                .foregroundColor(.appAccent)
            Text("PawMatch")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.appAccent)
        }
    }
}
