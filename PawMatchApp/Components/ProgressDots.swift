import SwiftUI

struct ProgressDots: View {
    let totalSteps: Int
    let currentStep: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Circle()
                    .fill(index == currentStep ? Color.appAccent : Color.white.opacity(0.2))
                    .frame(width: 8, height: 8)
            }
        }
    }
}
