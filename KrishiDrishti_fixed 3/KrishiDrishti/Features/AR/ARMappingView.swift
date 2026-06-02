// Views/AR/ARMappingView.swift
// KrishiDrishti — AR interface for tagging 3D disease anchors in local farm fields

import SwiftUI
import ARKit

struct ARMappingView: View {
    @StateObject private var sessionManager = ARSessionManager()
    @Environment(\.dismiss) private var dismiss

    init() {}

    var body: some View {
        NavigationStack {
            ZStack {
                ARViewContainer(sessionManager: sessionManager)
                    .ignoresSafeArea(edges: [.horizontal, .bottom])

                VStack {
                    // Tracking status indicator
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.white)
                        Text(sessionManager.sessionMessage)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.65), in: Capsule())
                    .padding(.top, 16)

                    Spacer()

                    // Action buttons
                    HStack {
                        Button {
                            sessionManager.startSession()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.headline)
                                .foregroundStyle(AppTheme.green)
                                .frame(width: 50, height: 50)
                                .background(.white, in: Circle())
                                .shadow(radius: 4)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        if sessionManager.anchorPlaced {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.white)
                                Text("Infection Tagged")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(AppTheme.green, in: Capsule())
                            .shadow(radius: 4)
                        } else {
                            Text("Tap screen to tag infection")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(.black.opacity(0.5), in: Capsule())
                        }

                        Spacer()

                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.headline)
                                .foregroundStyle(.red)
                                .frame(width: 50, height: 50)
                                .background(.white, in: Circle())
                                .shadow(radius: 4)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("AR Field Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.green)
                }
            }
            .onAppear {
                sessionManager.startSession()
            }
            .onDisappear {
                sessionManager.pauseSession()
            }
        }
    }
}
