import SwiftUI

struct SplashView: View {
    @State private var isActive = false

    private static let splashImages = [
        "SplashMecatol",
        "SplashWarComing",
        "SplashMonument"
    ]

    @State private var selectedImage = splashImages.randomElement()!

    var body: some View {
        if !isActive {
            ZStack(alignment: .bottom) {
                Image(selectedImage)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.6)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(height: 200)
                .ignoresSafeArea()
            }
            .transition(.opacity)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    withAnimation(.easeOut(duration: 0.8)) {
                        isActive = true
                    }
                }
            }
        }
    }
}
