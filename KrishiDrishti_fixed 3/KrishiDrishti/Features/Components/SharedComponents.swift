// Views/Components/SharedComponents.swift
// KrishiDrishti — Reusable UI components

import SwiftUI

// MARK: - ScanRow
struct ScanRow: View {
    let scan: CropProblem
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(scan.severity.bgColor).frame(width: 52, height: 52)
                Text(scan.cropIcon).font(.title2)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(scan.cropName).font(.subheadline).fontWeight(.semibold)
                Text(scan.disease).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                Text(scan.timeAgo).font(.caption2).foregroundStyle(.tertiary)
            }
            Spacer()
            Text(scan.severity.rawValue).font(.caption2).fontWeight(.black)
                .foregroundStyle(scan.severity.color)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(scan.severity.bgColor, in: Capsule())
            Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: AppTheme.radius))
        .shadow(color: .black.opacity(0.04), radius: 5, y: 2)
    }
}

// MARK: - StatBox
struct StatBox: View {
    let val, lbl, icon: String; let col: Color
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.title2).foregroundStyle(col)
            Text(val).font(.title2).fontWeight(.black)
            Text(lbl).font(.system(size: 9)).fontWeight(.medium).foregroundStyle(.secondary)
                .textCase(.uppercase).kerning(0.3).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: AppTheme.radius))
        .shadow(color: col.opacity(0.1), radius: 6, y: 3)
    }
}

struct SetupStatusRow: View {
    let title: String
    let subtitle: String
    let isReady: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isReady ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(isReady ? AppTheme.green : AppTheme.amber)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline).fontWeight(.semibold)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(isReady ? "Ready" : "Optional")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(isReady ? AppTheme.green : AppTheme.amber)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((isReady ? AppTheme.greenSoft : AppTheme.severityBg(.medium)), in: Capsule())
        }
    }
}

// MARK: - FlowTags
struct FlowTags: View {
    let items: [String]
    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(items, id: \.self) { item in
                Text("🌱 \(item)").font(.system(size: 11)).fontWeight(.medium)
                    .foregroundStyle(AppTheme.green)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(AppTheme.greenSoft, in: Capsule())
            }
        }
    }
}

// MARK: - FlowLayout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let w = proposal.width ?? 300; var x: CGFloat = 0; var y: CGFloat = 0; var rH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > w { x = 0; y += rH + spacing; rH = 0 }
            x += s.width + spacing; rH = max(rH, s.height)
        }
        return CGSize(width: w, height: y + rH)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX; var y = bounds.minY; var rH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > bounds.maxX { x = bounds.minX; y += rH + spacing; rH = 0 }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing; rH = max(rH, s.height)
        }
    }
}

// MARK: - WaveIcon (voice animation)
struct WaveIcon: View {
    @State private var h: [CGFloat] = [0.3, 0.8, 1.0, 0.6, 0.4]
    var body: some View {
        HStack(spacing: 3) {
            ForEach(h.indices, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2).fill(Color.white)
                    .frame(width: 3, height: 20 * h[i])
                    .animation(.easeInOut(duration: Double.random(in: 0.3...0.55))
                        .repeatForever(autoreverses: true).delay(Double(i) * 0.07), value: h[i])
            }
        }
        .onAppear { for i in h.indices { h[i] = CGFloat.random(in: 0.25...1.0) } }
    }
}

// MARK: - HighSunlightTheme
struct HighSunlightTheme {
    static let background = Color.black
    static let primary    = Color.yellow
    static let accent     = Color.orange
}

extension View {
    func highSunlightStyle() -> some View {
        self.tint(HighSunlightTheme.accent)
            .font(.system(.body, design: .rounded))
            .environment(\.colorScheme, .dark)
    }
}
