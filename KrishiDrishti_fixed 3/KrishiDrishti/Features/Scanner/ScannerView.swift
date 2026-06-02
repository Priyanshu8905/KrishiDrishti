// Views/Scanner/ScannerView.swift
// KrishiDrishti — Native camera-first scanner

import SwiftUI

struct ScannerView: View {
    @ObservedObject var vm: ScannerViewModel
    @Binding var isPresented: Bool

    @State private var showPhotoPicker = false
    @State private var showCamera      = false
    @State private var appeared        = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                VStack(spacing: 28) {
                    Spacer()

                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [AppTheme.greenLight.opacity(0.15), AppTheme.greenSoft],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 200, height: 200)
                        VStack(spacing: 8) {
                            Text("🌱").font(.system(size: 72))
                            if vm.scanState == .scanning {
                                ProgressView().tint(AppTheme.green).scaleEffect(1.2)
                            }
                        }
                    }
                    .scaleEffect(appeared ? 1 : 0.8)
                    .opacity(appeared ? 1 : 0)

                    VStack(spacing: 8) {
                        Text(statusTitle).font(.title2).fontWeight(.black)
                        Text(statusSubtitle)
                            .font(.subheadline).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center).padding(.horizontal, 32)
                    }
                    .opacity(appeared ? 1 : 0)

                    Spacer()

                    VStack(spacing: 12) {
                        // Gallery — uses PHPickerViewController (no iCloud / HEIC errors)
                        Button {
                            guard vm.scanState == .idle else { return }
                            showPhotoPicker = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "photo.on.rectangle.angled").font(.headline)
                                Text("Choose from Gallery").font(.headline).fontWeight(.semibold)
                            }
                            .foregroundStyle(AppTheme.green)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.greenSoft,
                                        in: RoundedRectangle(cornerRadius: AppTheme.radius))
                            .overlay(RoundedRectangle(cornerRadius: AppTheme.radius)
                                .stroke(AppTheme.green.opacity(0.4), lineWidth: 1.5))
                        }
                        .disabled(vm.scanState != .idle)
                        .buttonStyle(.plain)

                        // Camera
                        Button {
                            guard vm.scanState == .idle else { return }
                            showCamera = true
                        } label: {
                            HStack(spacing: 10) {
                                if vm.scanState == .scanning {
                                    ProgressView().tint(.white).scaleEffect(0.9)
                                    Text("Analysing…").font(.headline).fontWeight(.black)
                                } else if vm.scanState == .diagnosed {
                                    Image(systemName: "checkmark.circle.fill").font(.headline)
                                    Text("Opening Result…").font(.headline).fontWeight(.black)
                                } else {
                                    Image(systemName: "camera.fill").font(.headline)
                                    Text("Take a Photo").font(.headline).fontWeight(.black)
                                }
                                Spacer()
                                if vm.scanState == .idle {
                                    Image(systemName: "arrow.right.circle.fill").font(.title3)
                                }
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20).padding(.vertical, 18)
                            .background(RoundedRectangle(cornerRadius: AppTheme.radius)
                                .fill(AppTheme.primaryGradient)
                                .shadow(color: AppTheme.green.opacity(0.5), radius: 16, y: 8))
                        }
                        .disabled(vm.scanState != .idle)
                        .buttonStyle(.plain)
                        .animation(.spring(response: 0.35), value: vm.scanState)
                    }
                    .padding(.horizontal, 24).padding(.bottom, 40)
                    .opacity(appeared ? 1 : 0)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { vm.reset(); isPresented = false } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .frame(width: 32, height: 32)
                            .background(Color(uiColor: .secondarySystemBackground), in: Circle())
                    }.buttonStyle(.plain)
                }
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("Crop Scanner").font(.headline)
                        Text("Take or upload a crop photo")
                            .font(.system(size: 10)).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPickerView(onImage: { image in
                Task { await vm.analyzeImage(image) }
            }, isPresented: $showPhotoPicker)
            .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(isPresented: $showCamera) { image in
                Task { await vm.analyzeImage(image) }
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $vm.showResult) {
            if let dx = vm.currentDiagnosis {
                ResultDetailView(diagnosis: dx, vm: vm).onDisappear { vm.reset() }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
    }

    private var statusTitle: String {
        switch vm.scanState {
        case .idle:      return "Ready to Scan"
        case .scanning:  return "Analysing…"
        case .diagnosed: return "Done!"
        default:         return "Ready to Scan"
        }
    }
    private var statusSubtitle: String {
        switch vm.scanState {
        case .idle:      return "Take a photo or upload from your gallery to identify crop diseases"
        case .scanning:  return "Vision AI is classifying your crop…"
        case .diagnosed: return "Analysis complete — opening result"
        default:         return ""
        }
    }
}
