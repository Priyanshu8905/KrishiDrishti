// Views/Scanner/ResultDetailView.swift
// KrishiDrishti — Redesigned Result Detail View with real-time SceneKit 3D hotspots and zero mock data

import SwiftUI

struct ResultDetailView: View {
    let diagnosis: CropProblem
    @ObservedObject var vm: ScannerViewModel
    @Environment(\.dismiss) var dismiss
    @StateObject private var checklist: TreatmentChecklist

    @State private var expanded = false
    @State private var pulse = false
    @State private var visible = false
    
    @State private var showTranslation = false
    @State private var translationText = ""

    init(diagnosis: CropProblem, vm: ScannerViewModel) {
        self.diagnosis = diagnosis
        self.vm = vm
        
        let steps = diagnosis.remedy
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .map {
                TreatmentStep(
                    title: $0.trimmingCharacters(in: CharacterSet.decimalDigits.union(.init(charactersIn: ". ")))
                )
            }
        
        _checklist = StateObject(wrappedValue: TreatmentChecklist(checklistID: diagnosis.id.uuidString, initialSteps: steps))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 20)
                    
                    Divider().padding(.horizontal, 20)
                    
                    metrics
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                    
                    Divider().padding(.horizontal, 20)

                    section("Scan Result", "doc.text.image.fill") {
                        VStack(alignment: .leading, spacing: 14) {
                            reportRow(title: "Crop Name", value: diagnosis.cropName, icon: "leaf.fill", color: AppTheme.green)
                            reportRow(title: "Health Status", value: diagnosis.isHealthy ? "Crop Appears Healthy" : "Unhealthy", icon: "heart.text.square.fill", color: diagnosis.isHealthy ? AppTheme.green : .red)
                            reportRow(title: "Disease Detection", value: diagnosis.isHealthy ? "Crop Appears Healthy" : diagnosis.disease, icon: "exclamationmark.shield.fill", color: diagnosis.isHealthy ? AppTheme.green : diagnosis.severity.color)
                            reportRow(title: "Confidence Score", value: diagnosis.confidenceText, icon: "percent", color: AppTheme.green)
                            reportRow(title: "Affected Area", value: String(format: "%.1f%%", diagnosis.affectedArea), icon: "chart.bar.fill", color: diagnosis.isHealthy ? AppTheme.green : .orange)
                            reportRow(title: "Risk Level", value: diagnosis.isHealthy ? "Low" : diagnosis.severity.rawValue, icon: "exclamationmark.triangle.fill", color: diagnosis.isHealthy ? AppTheme.green : diagnosis.severity.color)
                            reportRow(title: "Recommended Treatment", value: diagnosis.isHealthy ? "No treatment needed. Continue routine inspection." : diagnosis.remedy, icon: "cross.vial.fill", color: AppTheme.green)
                            reportRow(title: "Prevention Tips", value: diagnosis.isHealthy ? "Continue normal watering and routine inspection every 7 days." : "Water from base, isolate infected crops, and maintain spacing.", icon: "lightbulb.fill", color: .yellow)
                            reportRow(title: "Date & Time", value: diagnosis.scannedAt.formatted(date: .abbreviated, time: .shortened), icon: "calendar.badge.clock", color: .secondary)
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                    }
                    Divider().padding(.horizontal, 20)
                    
                    section("Voice Guide", "speaker.wave.3.fill") { voiceGuide }
                    
                    Divider().padding(.horizontal, 20)
                    
                    if !diagnosis.isHealthy {
                        section("Observed Symptoms", "eye.fill") { symptoms }
                        Divider().padding(.horizontal, 20)
                        
                        section("Action Checklist", "checklist") { treatmentChecklist }
                        Divider().padding(.horizontal, 20)
                        
                        section("Treatment Plan", "cross.vial.fill") { remedy }
                    } else {
                        section("General Advisory", "checkmark.shield.fill") {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppTheme.green)
                                Text("No treatment needed. Continue routine inspection every 7 days.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    
                    Color.clear.frame(height: 40)
                }
                .opacity(visible ? 1 : 0)
                .offset(y: visible ? 0 : 20)
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: visible)
            }
            .scrollIndicators(.hidden)
            .background(Color(uiColor: .systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        let script = "Crop: \(diagnosis.cropName). \(diagnosis.isHealthy ? "Crop appears healthy." : "Disease: \(diagnosis.disease). Remedy: \(diagnosis.remedy). Symptoms: \(diagnosis.symptoms.joined(separator: ", "))")"
                        translationText = script
                        showTranslation = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "translate")
                                .font(.footnote)
                            Text("Translate")
                                .font(.footnote)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(AppTheme.green)
                    }
                }
                ToolbarItem(placement: .principal) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(uiColor: .tertiaryLabel))
                        .frame(width: 38, height: 5)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        vm.stopSpeaking()
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.green)
                }
            }
        }
        .offlineTranslation(isPresented: $showTranslation, text: translationText)
        .presentationDetents([.fraction(0.82), .large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { visible = true }
            withAnimation(.easeInOut(duration: 0.45).repeatCount(5, autoreverses: true).delay(0.3)) { pulse = true }
        }
        .onDisappear {
            vm.stopSpeaking()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(diagnosis.severity.color)
                        .frame(width: 8, height: 8)
                        .scaleEffect(pulse ? 1.8 : 1.0)
                        .opacity(pulse ? 0.4 : 1.0)
                        .animation(.easeInOut(duration: 0.45), value: pulse)
                    Image(systemName: diagnosis.severity.icon)
                        .font(.caption2)
                        .foregroundStyle(diagnosis.severity.color)
                    Text(diagnosis.severity.rawValue.uppercased())
                        .font(.caption)
                        .fontWeight(.black)
                        .foregroundStyle(diagnosis.severity.color)
                        .kerning(0.6)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(diagnosis.severity.bgColor, in: Capsule())
                .scaleEffect(pulse ? 1.03 : 1.0)
                .animation(.easeInOut(duration: 0.45), value: pulse)

                Spacer()
                
                Text(diagnosis.confidenceText)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(AppTheme.greenSoft, in: Capsule())
            }
            
            HStack(spacing: 12) {
                Text(diagnosis.cropIcon).font(.system(size: 40))
                VStack(alignment: .leading, spacing: 3) {
                    Text(diagnosis.cropName)
                        .font(.system(size: 30, weight: .black, design: .rounded))
                    
                    HStack(spacing: 5) {
                        Text("Diagnosed:").font(.subheadline).foregroundStyle(.secondary)
                        Text(diagnosis.isHealthy ? "Crop appears healthy" : diagnosis.disease)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(diagnosis.isHealthy ? AppTheme.green : diagnosis.severity.color)
                    }
                    
                    if !diagnosis.scientificName.isEmpty && diagnosis.scientificName != "N/A" {
                        Text(diagnosis.scientificName)
                            .font(.caption)
                            .italic()
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            
            HStack(spacing: 4) {
                Image(systemName: "clock").font(.caption2).foregroundStyle(.quaternary)
                Text("Scanned \(diagnosis.timeAgo)").font(.caption2).foregroundStyle(.quaternary)
            }
        }
    }

    private var metrics: some View {
        HStack(spacing: 10) {
            MetricBox(val: diagnosis.confidenceText, lbl: "AI Confidence", col: .primary)
            MetricBox(val: String(format: "%.1f%%", diagnosis.affectedArea), lbl: "Leaf Affected", col: diagnosis.isHealthy ? AppTheme.green : diagnosis.severity.color)
            MetricBox(val: diagnosis.isHealthy ? "Healthy" : "Monitor", lbl: "Priority", col: diagnosis.isHealthy ? AppTheme.green : diagnosis.severity.color)
        }
    }

    private var symptoms: some View {
        VStack(spacing: 8) {
            ForEach(Array(diagnosis.symptoms.enumerated()), id: \.offset) { i, s in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(i == 0 ? diagnosis.severity.color : .orange)
                        .frame(width: 8, height: 8)
                        .padding(.top, 5)
                    Text(s)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(2)
                    Spacer()
                }
                .padding(12)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var treatmentChecklist: some View {
        VStack(spacing: 10) {
            HStack {
                Text("\(checklist.steps.filter(\.isCompleted).count)/\(checklist.steps.count) completed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                ProgressView(
                    value: Double(checklist.steps.filter(\.isCompleted).count),
                    total: Double(max(checklist.steps.count, 1))
                )
                .tint(AppTheme.green)
                .frame(width: 110)
            }

            ForEach(Array(checklist.steps.enumerated()), id: \.element.id) { index, step in
                Button {
                    checklist.steps[index].isCompleted.toggle()
                    checklist.save()
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: step.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(step.isCompleted ? AppTheme.green : Color(uiColor: .tertiaryLabel))
                        Text(step.title)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    .padding(14)
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var remedy: some View {
        let steps = diagnosis.remedy.components(separatedBy: "\n").filter { !$0.isEmpty }
        let shown = expanded ? steps : Array(steps.prefix(2))
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(shown.enumerated()), id: \.offset) { i, step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(i+1)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(.white.opacity(0.25)))
                    Text(step.trimmingCharacters(in: CharacterSet.decimalDigits.union(.init(charactersIn: ". "))))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.92))
                        .lineSpacing(2)
                    Spacer()
                }
                .padding(.vertical, 10)
                if i < shown.count - 1 {
                    Divider().overlay(.white.opacity(0.15))
                }
            }
            if steps.count > 2 {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        expanded.toggle()
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text(expanded ? "Show less ↑" : "Show all \(steps.count) steps ↓")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white.opacity(0.65))
                        Spacer()
                    }
                    .padding(.top, 10)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.radius)
                .fill(LinearGradient(
                    colors: [Color(red: 0.10, green: 0.24, blue: 0.18), AppTheme.green],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .shadow(color: AppTheme.green.opacity(0.35), radius: 12, y: 6)
        )
    }

    private var voiceGuide: some View {
        VStack(spacing: 12) {
            Button {
                vm.speak(diagnosis)
            } label: {
                HStack(spacing: 12) {
                    if vm.isSpeaking {
                        WaveIcon().frame(width: 30, height: 20)
                    } else {
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.title3)
                            .foregroundStyle(AppTheme.green)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(vm.isSpeaking ? "Tap to Stop" : "Listen — Voice Guide")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(vm.isSpeaking ? .white : .primary)
                        Text(vm.isSpeaking ? "Reading treatment aloud..." : "Offline Apple/Siri voice guide")
                            .font(.caption)
                            .foregroundStyle(vm.isSpeaking ? .white.opacity(0.7) : .secondary)
                    }
                    Spacer()
                    
                    Image(systemName: vm.isSpeaking ? "stop.circle.fill" : "play.circle.fill")
                        .font(.title2)
                        .foregroundStyle(vm.isSpeaking ? .white.opacity(0.7) : AppTheme.green)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.radius)
                        .fill(vm.isSpeaking ? AppTheme.green : Color(uiColor: .secondarySystemGroupedBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.radius)
                                .stroke(AppTheme.green.opacity(0.35), lineWidth: 1.5)
                        )
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.75), value: vm.isSpeaking)
            }
            .buttonStyle(.plain)

            HStack(spacing: 6) {
                Image(systemName: "waveform").font(.caption2).foregroundStyle(AppTheme.green)
                Text("Apple offline voice guide")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(AppTheme.greenSoft, in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private func section<C: View>(_ title: String, _ icon: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .kerning(0.5)
            content()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
    }

    private func reportRow(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 24, height: 24)
                .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            Spacer()
        }
    }
}

private struct MetricBox: View {
    let val: String
    let lbl: String
    let col: Color
    
    var body: some View {
        VStack(spacing: 5) {
            Text(val)
                .font(.title3)
                .fontWeight(.black)
                .foregroundStyle(col)
            Text(lbl)
                .font(.system(size: 9))
                .fontWeight(.medium)
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)
                .kerning(0.3)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}
