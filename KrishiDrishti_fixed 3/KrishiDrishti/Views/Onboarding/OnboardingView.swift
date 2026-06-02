// Views/Onboarding/OnboardingView.swift
// KrishiDrishti — First-launch onboarding

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var page = 0

    private let pages: [(icon: String, title: String, body: String)] = [
        ("🌱", "Welcome to\nKrishi Drishti",
         "Your AI-powered crop doctor.\nDetect diseases, get treatment advice and weather alerts — all in one place."),
        ("📷", "Scan Any Crop",
         "Upload a photo from your gallery.\nOur Vision AI identifies diseases instantly — even offline."),
        ("🤖", "Ask KrishiBot",
         "Ask anything about your crops.\nFertilizer doses, spray timing, soil health — get expert answers in seconds."),
        ("🌤️", "Live Weather Alerts",
         "Real-time disease risk based on your local weather.\nKnow exactly when to spray and when to hold."),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.greenSoft, Color.white],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        PageCard(page: pages[i]).tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)

                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? AppTheme.green : AppTheme.green.opacity(0.25))
                            .frame(width: i == page ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: page)
                    }
                }
                .padding(.bottom, 24)

                // CTA button
                Button {
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        hasSeenOnboarding = true
                    }
                } label: {
                    Text(page < pages.count - 1 ? "Next" : "Get Started 🌱")
                        .font(.headline).fontWeight(.black)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(AppTheme.primaryGradient, in: RoundedRectangle(cornerRadius: AppTheme.radius))
                        .shadow(color: AppTheme.green.opacity(0.4), radius: 12, y: 6)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }
}

private struct PageCard: View {
    let page: (icon: String, title: String, body: String)

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Text(page.icon)
                .font(.system(size: 90))
                .shadow(color: .black.opacity(0.08), radius: 10, y: 6)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.green)

                Text(page.body)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }
            Spacer()
        }
    }
}
