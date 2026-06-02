// Views/Bot/BotView.swift
// KrishiDrishti — KrishiBot chat UI (Gemini + offline fallback)

import SwiftUI
import PhotosUI

struct BotView: View {
    @ObservedObject var weather: WeatherService
    @ObservedObject var profile: UserProfile
    @StateObject private var network = NetworkMonitor.shared
    @StateObject private var bot = KrishiBotVM()
    @FocusState  private var focused: Bool
    @State private var selectedPhoto: PhotosPickerItem?

    private let green  = AppTheme.green
    private let lgreen = AppTheme.greenSoft

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                messageList
                Divider()
                if !focused && !bot.thinking { photoPrompt }
                inputBar
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("KrishiBot 🌾")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(network.isConnected ? (GeminiService.shared.isConfigured ? Color.green : Color.orange) : Color.gray)
                            .frame(width: 7, height: 7)
                        Text(network.isConnected
                             ? (GeminiService.shared.isConfigured ? "Hybrid AI" : "Offline-first")
                             : "No Internet")
                            .font(.caption2).fontWeight(.semibold).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let img  = UIImage(data: data) { bot.analyzePhoto(img) }
                await MainActor.run { selectedPhoto = nil }
            }
        }
        .onAppear { sync() }
        .onReceive(weather.$weather) { _ in sync() }
        .onChange(of: profile.crops) { _, _ in sync() }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(bot.messages) { msg in BotBubble(msg: msg).id(msg.id) }
                    if bot.thinking { TypingBubble().id("typing") }
                    Color.clear.frame(height: 4).id("bottom")
                }
                .padding(.horizontal, 14).padding(.top, 14)
            }
            .onChange(of: bot.messages.count) { _, _ in withAnimation { proxy.scrollTo("bottom", anchor: .bottom) } }
            .onChange(of: bot.thinking)       { _, _ in withAnimation { proxy.scrollTo("bottom", anchor: .bottom) } }
        }
    }

    private var photoPrompt: some View {
        PhotosPicker(selection: $selectedPhoto, matching: .images) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(AppTheme.primaryGradient)
                    Image(systemName: "photo.fill").font(.system(size: 16, weight: .semibold)).foregroundStyle(.white)
                }.frame(width: 42, height: 42)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Upload a crop photo").font(.subheadline).fontWeight(.semibold).foregroundStyle(green)
                    Text("KrishiBot will analyze it instantly").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 18).padding(.vertical, 12).background(lgreen)
        }.buttonStyle(.plain)
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Image(systemName: "photo.fill").font(.system(size: 18, weight: .semibold)).foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(AppTheme.primaryGradient)
                        .shadow(color: green.opacity(0.4), radius: 8, y: 4))
            }.disabled(bot.thinking)

            TextField("Ask anything about your crops…", text: $bot.input, axis: .vertical)
                .font(.subheadline).lineLimit(1...4)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
                .focused($focused)

            Button { bot.sendText(); focused = false } label: {
                Image(systemName: "arrow.up.circle.fill").font(.system(size: 34))
                    .foregroundStyle(bot.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                     ? Color(uiColor: .systemGray3) : green)
            }
            .disabled(bot.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || bot.thinking)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private func sync() {
        bot.currentWeather = weather.weather
        bot.farmerCrops    = profile.crops
        bot.farmerName     = profile.displayName
    }
}

// MARK: - BotBubble
struct BotBubble: View {
    let msg: BotMsg
    @State private var chartOn = false
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if msg.role == .bot {
                ZStack {
                    Circle().fill(AppTheme.primaryGradient)
                    Text("🌾").font(.system(size: 14))
                }.frame(width: 32, height: 32).shadow(color: AppTheme.green.opacity(0.3), radius: 4, y: 2)
            }
            VStack(alignment: msg.role == .bot ? .leading : .trailing, spacing: 8) {
                if let img = msg.image {
                    Image(uiImage: img).resizable().scaledToFill()
                        .frame(maxWidth: 220, maxHeight: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                if !msg.text.isEmpty {
                    Text(LocalizedStringKey(msg.text)).font(.subheadline).lineSpacing(3)
                        .foregroundStyle(msg.role == .bot ? Color.primary : Color.white)
                        .padding(.horizontal, 14).padding(.vertical, 11)
                        .background(
                            msg.role == .bot
                                ? Color(uiColor: .secondarySystemGroupedBackground)
                                : AppTheme.green,
                            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                        )
                        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                }
                if let c = msg.chart { BotChartView(chart: c, on: chartOn) }
            }
            .frame(maxWidth: 320, alignment: msg.role == .bot ? .leading : .trailing)
            if msg.role == .user { Spacer(minLength: 0) }
        }
        .frame(maxWidth: .infinity, alignment: msg.role == .bot ? .leading : .trailing)
        .onAppear { withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) { chartOn = true } }
    }
}

// MARK: - BotChartView
struct BotChartView: View {
    let chart: BotChart; let on: Bool
    private var maxVal: Double { chart.bars.map(\.value).max() ?? 1 }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(chart.title).font(.system(size: 10)).fontWeight(.semibold)
                .foregroundStyle(.secondary).textCase(.uppercase).kerning(0.4)
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(chart.bars.enumerated()), id: \.element.id) { i, bar in
                    VStack(spacing: 4) {
                        Text("\(Int(bar.value))\(chart.unit)").font(.system(size: 9)).fontWeight(.bold)
                        RoundedRectangle(cornerRadius: 5).fill(bar.color)
                            .frame(maxWidth: .infinity).frame(height: on ? CGFloat(bar.value / maxVal) * 82 : 2)
                            .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(Double(i) * 0.07), value: on)
                        Text(bar.label).font(.system(size: 8)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }.frame(maxWidth: .infinity)
                }
            }.frame(height: 108)
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(Color(uiColor: .separator).opacity(0.3), lineWidth: 0.5))
    }
}

// MARK: - Typing indicator
struct TypingBubble: View {
    @State private var phase = 0
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack {
                Circle().fill(AppTheme.primaryGradient)
                Text("🌾").font(.system(size: 14))
            }.frame(width: 32, height: 32)
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle().fill(Color(uiColor: .tertiaryLabel)).frame(width: 7, height: 7)
                        .scaleEffect(phase == i ? 1.45 : 1.0)
                        .animation(.easeInOut(duration: 0.38).repeatForever().delay(Double(i) * 0.13), value: phase)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(Color(uiColor: .secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            Spacer()
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 380_000_000)
                await MainActor.run {
                    withAnimation { phase = (phase + 1) % 3 }
                }
            }
        }
    }
}
