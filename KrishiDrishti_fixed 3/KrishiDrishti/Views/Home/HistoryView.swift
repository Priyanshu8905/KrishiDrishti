// Views/Home/HistoryView.swift
// KrishiDrishti — Scan history with filter

import SwiftUI

struct HistoryView: View {
    @ObservedObject var vm: ScannerViewModel
    @Binding var filter: ScanCategory
    @Environment(\.dismiss) private var dismiss
    @State private var tapped: CropProblem?

    private var filtered: [CropProblem] {
        switch filter {
        case .all:      return vm.scanHistory
        case .highRisk: return vm.scanHistory.filter { $0.severity == .high }
        case .healthy:  return vm.scanHistory.filter { $0.severity == .low }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if vm.scanHistory.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "clock.badge.questionmark").font(.system(size: 48))
                            .foregroundStyle(AppTheme.greenLight)
                        Text("No History Yet").font(.title3).fontWeight(.semibold)
                        Text("Your scans will appear here.").font(.subheadline).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(uiColor: .systemGroupedBackground))
                } else {
                    VStack(spacing: 10) {
                        Picker("Filter", selection: $filter) {
                            ForEach(ScanCategory.allCases, id: \.self) {
                                Text($0.rawValue).tag($0)
                            }
                        }
                        .pickerStyle(.segmented).padding(.horizontal, 16)

                        if filtered.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                    .font(.system(size: 36)).foregroundStyle(.secondary)
                                Text("No scans in \(filter.rawValue)")
                                    .font(.subheadline).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            List {
                                ForEach(filtered) { s in
                                    ScanRow(scan: s)
                                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                        .listRowBackground(Color.clear).listRowSeparator(.hidden)
                                        .onTapGesture { tapped = s }
                                }
                            }
                            .listStyle(.plain).scrollContentBackground(.hidden)
                            .background(Color(uiColor: .systemGroupedBackground))
                        }
                    }
                }
            }
            .navigationTitle("Scan History").navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !vm.scanHistory.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear") {
                            vm.scanHistory = []
                            OfflineCacheService.shared.saveScanHistory([])
                            dismiss()
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
        }
        .sheet(item: $tapped) { ResultDetailView(diagnosis: $0, vm: vm) }
    }
}
