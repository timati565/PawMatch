import SwiftUI

extension View {
    func cardStyle() -> some View {
        self
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    func standardPadding() -> some View {
        self.padding(.horizontal, 16)
    }
}
