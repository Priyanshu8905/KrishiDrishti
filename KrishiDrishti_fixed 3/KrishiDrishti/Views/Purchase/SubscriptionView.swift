// Views/Purchase/SubscriptionView.swift
// KrishiDrishti — Premium features activation page integrated with StoreKit 2 StoreManager

import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @StateObject private var purchaseManager = PurchaseManager()
    @Environment(\.dismiss) private var dismiss

    init() {}

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Card
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.greenSoft)
                                .frame(width: 80, height: 80)
                            Image(systemName: "crown.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(AppTheme.amber)
                        }

                        Text("Krishi Premium")
                            .font(.title)
                            .fontWeight(.black)

                        Text("Unlock advanced forecasting tools and automated advisory reminders.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 16)

                    // Features list
                    VStack(alignment: .leading, spacing: 16) {
                        featureRow(icon: "bell.badge.fill", title: "Real-time Push Alerts", desc: "Get notified immediately of sudden temperature drops or disease surges.")
                        featureRow(icon: "cloud.sun.rain.fill", title: "Extended Advisory Plans", desc: "Retrieve weekly weather predictions tailored specifically for your registered crops.")
                        featureRow(icon: "map.fill", title: "AR Field Infection Mapper", desc: "Unlock unlimited virtual crop indicators in the field mapping dashboard.")
                    }
                    .padding(20)
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: AppTheme.radius))
                    .padding(.horizontal, 16)

                    // Purchase State
                    if purchaseManager.isPremiumUnlocked {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(AppTheme.green)
                                Text("Premium Activated")
                                    .fontWeight(.bold)
                            }
                            Text("Thank you for supporting sustainable farming!")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(20)
                    } else {
                        VStack(spacing: 16) {
                            if purchaseManager.availableProducts.isEmpty {
                                // Fallback/Demo Mock purchase option if StoreKit simulator is unconfigured
                                Button {
                                    Task {
                                        purchaseManager.isPremiumUnlocked = true
                                    }
                                } label: {
                                    Text("Activate Demo Subscription - Free")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 52)
                                        .background(AppTheme.primaryGradient, in: RoundedRectangle(cornerRadius: 14))
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 16)
                            } else {
                                ForEach(purchaseManager.availableProducts) { product in
                                    Button {
                                        Task {
                                            try? await purchaseManager.purchase(product)
                                        }
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(product.displayName)
                                                    .fontWeight(.bold)
                                                Text(product.description)
                                                    .font(.caption)
                                            }
                                            Spacer()
                                            Text(product.displayPrice)
                                                .fontWeight(.black)
                                        }
                                        .padding()
                                        .foregroundStyle(.white)
                                        .background(AppTheme.green, in: RoundedRectangle(cornerRadius: 12))
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal, 16)
                                }
                            }

                            Button("Restore Purchases") {
                                Task {
                                    await purchaseManager.restore()
                                }
                            }
                            .font(.footnote)
                            .foregroundStyle(AppTheme.green)
                        }
                    }
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Premium Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(AppTheme.green)
                }
            }
            .task {
                await purchaseManager.loadProducts()
            }
        }
    }

    private func featureRow(icon: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AppTheme.green)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
