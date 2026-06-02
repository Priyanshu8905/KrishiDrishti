// Views/Home/HomeView.swift
// KrishiDrishti — Root tab view (iOS-native, camera-enabled)

import SwiftUI

enum AppTab: Hashable { case field, bot }
enum ScanCategory: String, CaseIterable, Hashable {
    case all = "All", highRisk = "High Risk", healthy = "Healthy"
}

// MARK: - Root
struct HomeView: View {
    @StateObject private var vm      = ScannerViewModel()
    @StateObject private var weather = WeatherService()
    @StateObject private var profile = UserProfile()
    @StateObject private var network = NetworkMonitor.shared
    @State private var selectedTab: AppTab = .field

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(vm: vm, weather: weather, profile: profile, network: network, selectedTab: $selectedTab)
                .tabItem { Label("Field", systemImage: "house.fill") }
                .tag(AppTab.field)
            BotView(weather: weather, profile: profile)
                .tabItem { Label("KrishiBot", systemImage: "brain.filled.head.profile") }
                .tag(AppTab.bot)
        }
        .tint(AppTheme.green)
        .onAppear { weather.start() }
    }
}

// MARK: - Dashboard
struct DashboardView: View {
    @ObservedObject var vm:      ScannerViewModel
    @ObservedObject var weather: WeatherService
    @ObservedObject var profile: UserProfile
    @ObservedObject var network: NetworkMonitor
    @Binding var selectedTab: AppTab

    @State private var tapped: CropProblem?
    @State private var appeared       = false
    @State private var showProfile    = false
    @State private var showHistory    = false
    @State private var historyFilter: ScanCategory = .all
    @State private var showPhotoPicker = false
    @State private var showCamera     = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    greetingCard
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)

                    weatherCard
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)

                    advisoryCard
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)

                    statsRow
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)

                    recentSection
                        .padding(.horizontal, 16)
                        .padding(.bottom, 120) // clearance for the bottom bar
                }
                .padding(.top, 12)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Krishi Drishti")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.green)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showProfile = true } label: {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AppTheme.green)
                    }
                    .buttonStyle(.plain)
                }
            }
            .overlay(alignment: .bottom) { analyzeBar }
        }
        .sheet(isPresented: $vm.showResult) {
            if let dx = vm.currentDiagnosis {
                ResultDetailView(diagnosis: dx, vm: vm).onDisappear { vm.reset() }
            }
        }
        .sheet(isPresented: $showProfile)  { ProfileView(profile: profile) }
        .sheet(isPresented: $showHistory)  { HistoryView(vm: vm, filter: $historyFilter) }
        .sheet(item: $tapped)              { ResultDetailView(diagnosis: $0, vm: vm) }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPickerView(onImage: { image in
                Task { await vm.analyzePickedImage(image) }
            }, isPresented: $showPhotoPicker)
            .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(isPresented: $showCamera) { image in
                Task { await vm.analyzePickedImage(image) }
            }
            .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(0.15)) { appeared = true }
        }
    }

    // MARK: - Greeting Card
    private var greetingCard: some View {
        HStack(spacing: 14) {
            Text(profile.avatar)
                .font(.system(size: 50))
                .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 3) {
                Text(profile.greeting)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .kerning(0.5)
                Text(profile.displayName)
                    .font(.title3)
                    .fontWeight(.bold)
                    .lineLimit(1)
                if !profile.village.isEmpty || !profile.state.isEmpty {
                    HStack(spacing: 3) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.green)
                        Text([profile.village, profile.state]
                            .filter { !$0.isEmpty }
                            .joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: 8)

            if !profile.crops.isEmpty {
                VStack(alignment: .trailing, spacing: 4) {
                    ForEach(profile.crops.prefix(2), id: \.self) { c in
                        Text("🌱 \(c)")
                            .font(.system(size: 10))
                            .fontWeight(.medium)
                            .foregroundStyle(AppTheme.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(AppTheme.greenSoft, in: Capsule())
                            .lineLimit(1)
                    }
                    if profile.crops.count > 2 {
                        Text("+\(profile.crops.count - 2) more")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
                .fixedSize(horizontal: true, vertical: false)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
        .contentShape(Rectangle())
        .onTapGesture { showProfile = true }
        .opacity(appeared ? 1 : 0)
    }

    // MARK: - Weather Card
    @ViewBuilder private var weatherCard: some View {
        if weather.isLoading {
            HStack(spacing: 12) {
                ProgressView().tint(AppTheme.green)
                Text("Getting weather for your field…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Color(uiColor: .secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: AppTheme.radiusLg))

        } else if let w = weather.weather {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: AppTheme.radiusLg)
                    .fill(LinearGradient(
                        colors: w.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing))
                    .shadow(color: (w.gradientColors.first ?? .blue).opacity(0.35),
                            radius: 12, y: 6)

                HStack(alignment: .center, spacing: 0) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.8))
                            Text(w.locationName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.white.opacity(0.85))
                                .lineLimit(1)
                        }
                        Text(w.sourceLabel)
                            .font(.system(size: 11))
                            .fontWeight(.bold)
                            .foregroundStyle(.white.opacity(0.75))

                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(String(format: "%.0f°", w.temperature))
                                .font(.system(size: 48, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                            Text("C")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white.opacity(0.7))
                                .offset(y: -4)
                        }

                        Text(w.condition)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white.opacity(0.9))

                        HStack(spacing: 14) {
                            wStat(icon: "humidity.fill",
                                  val: "\(w.humidity)%",
                                  lbl: "Humidity")
                            wStat(icon: "wind",
                                  val: "\(Int(w.windSpeed)) km/h",
                                  lbl: "Wind")
                        }
                    }
                    Spacer()
                    Image(systemName: w.sfSymbol)
                        .font(.system(size: 56))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(20)
            }
            .fixedSize(horizontal: false, vertical: true) // grows with content, no clipping
            .opacity(appeared ? 1 : 0)

        } else {
            HStack(spacing: 10) {
                Image(systemName: "cloud.slash").foregroundStyle(.secondary)
                Text(weather.errorMsg ?? "Weather unavailable")
                    .font(.subheadline).foregroundStyle(.secondary)
                Spacer()
                Button("Retry") { weather.start() }
                    .font(.caption).fontWeight(.bold).foregroundStyle(AppTheme.green)
            }
            .padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: AppTheme.radius))
        }
    }

    private func wStat(icon: String, val: String, lbl: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon).font(.caption2).foregroundStyle(.white.opacity(0.7))
            Text(val).font(.caption).fontWeight(.bold).foregroundStyle(.white)
            Text(lbl).font(.system(size: 8)).foregroundStyle(.white.opacity(0.6))
        }
    }

    // MARK: - Advisory Card
    @ViewBuilder private var advisoryCard: some View {
        if let w = weather.weather {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(w.riskColor.opacity(0.12))
                        .frame(width: 42, height: 42)
                    Image(systemName: w.riskIcon)
                        .font(.body)
                        .foregroundStyle(w.riskColor)
                }
                .flexibleFrame(minWidth: 42, maxWidth: 42)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Advisory")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .kerning(0.4)
                    Text(w.advisory(for: profile.crops))
                        .font(.subheadline)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true) // wraps properly
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: AppTheme.radius))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radius)
                    .stroke(w.riskColor.opacity(0.2), lineWidth: 1)
            )
            .opacity(appeared ? 1 : 0)
        }
    }

    // MARK: - Stats Row
    private var statsRow: some View {
        HStack(spacing: 10) {
            Button { historyFilter = .all; showHistory = true } label: {
                StatBox(val: "\(vm.scanHistory.count)",
                        lbl: "Scans",
                        icon: "camera.fill",
                        col: AppTheme.green)
            }.buttonStyle(.plain)

            Button { historyFilter = .highRisk; showHistory = true } label: {
                StatBox(val: "\(vm.scanHistory.filter { $0.severity == .high }.count)",
                        lbl: "High Risk",
                        icon: "exclamationmark.circle.fill",
                        col: .red)
            }.buttonStyle(.plain)

            Button { historyFilter = .healthy; showHistory = true } label: {
                StatBox(val: "\(vm.scanHistory.filter { $0.severity == .low }.count)",
                        lbl: "Healthy",
                        icon: "checkmark.seal.fill",
                        col: .green)
            }.buttonStyle(.plain)
        }
        .opacity(appeared ? 1 : 0)
    }

    // MARK: - Recent Scans
    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recent Scans").font(.headline).fontWeight(.bold)
                Spacer()
                if !vm.scanHistory.isEmpty {
                    Button {
                        historyFilter = .all; showHistory = true
                    } label: {
                        Text("See All")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.green)
                    }
                }
            }

            if vm.scanHistory.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "camera.macro")
                        .font(.system(size: 44))
                        .foregroundStyle(AppTheme.green.opacity(0.5))
                    Text("No scans yet")
                        .font(.subheadline).fontWeight(.semibold)
                    Text("Tap Analyze Crop below to get started")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
                .background(Color(uiColor: .secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: AppTheme.radius))
            } else {
                VStack(spacing: 8) {
                    ForEach(vm.scanHistory.prefix(5)) { scan in
                        ScanRow(scan: scan).onTapGesture { tapped = scan }
                    }
                }
            }
        }
        .opacity(appeared ? 1 : 0)
    }

    // MARK: - Bottom Analyze Bar
    private var analyzeBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 10) {

                // Gallery
                Button {
                    guard vm.scanState == .idle else { return }
                    showPhotoPicker = true
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 20))
                        Text("Gallery")
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(AppTheme.green)
                    .frame(width: 72, height: 56)
                    .background(Color(uiColor: .secondarySystemGroupedBackground),
                                in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(AppTheme.green.opacity(0.25), lineWidth: 1))
                }
                .disabled(vm.scanState != .idle)
                .buttonStyle(.plain)

                // Camera / Analyze
                Button {
                    guard vm.scanState == .idle else { return }
                    showCamera = true
                } label: {
                    HStack(spacing: 8) {
                        if vm.scanState == .scanning {
                            ProgressView().tint(.white).scaleEffect(0.85)
                            Text("Analysing…")
                                .font(.headline).fontWeight(.black)
                        } else {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 17, weight: .semibold))
                            Text("Analyze Crop")
                                .font(.headline).fontWeight(.black)
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppTheme.primaryGradient)
                            .shadow(color: AppTheme.green.opacity(0.4), radius: 10, y: 5)
                    )
                }
                .disabled(vm.scanState != .idle)
                .buttonStyle(.plain)
                .animation(.spring(response: 0.3), value: vm.scanState)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 24) // safe area breathing room
            .background(.ultraThinMaterial)
        }
    }
}

// MARK: - Helper
private extension View {
    func flexibleFrame(minWidth: CGFloat, maxWidth: CGFloat) -> some View {
        self.frame(minWidth: minWidth, maxWidth: maxWidth)
    }
}
