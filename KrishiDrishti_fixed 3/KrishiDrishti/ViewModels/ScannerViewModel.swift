// ViewModels/ScannerViewModel.swift
// KrishiDrishti — Scanner logic with persistent history (online + offline)

import SwiftUI
import AVFoundation

final class ScannerViewModel: ObservableObject {

    @Published var scanState:        ScanState = .idle
    @Published var currentDiagnosis: CropProblem?
    @Published var scanHistory:      [CropProblem] = []
    @Published var showResult        = false
    @Published var isSpeaking        = false
    @Published var selectedLang:     SupportedLanguage = .english
    @Published var hapticFlash:      Severity?

    private let synth    = AVSpeechSynthesizer()
    private var synthDel: SynthDelegate?
    private var player:   AVAudioPlayer?

    private let hMed  = UIImpactFeedbackGenerator(style: .medium)
    private let hHvy  = UIImpactFeedbackGenerator(style: .heavy)
    private let hNote = UINotificationFeedbackGenerator()

    init() {
        // Load persisted history only from the device; production builds should not seed fake diagnoses.
        scanHistory = OfflineCacheService.shared.loadScanHistory()
        hMed.prepare(); hHvy.prepare(); hNote.prepare()
        let d = SynthDelegate(vm: self); synthDel = d; synth.delegate = d
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    // MARK: - Analyse from PhotosPicker (safe, works online & offline)
    func analyzePickedImage(_ image: UIImage) async {
        guard scanState == .idle else { return }
        await MainActor.run { scanState = .scanning }
        // Vision framework classification — 100% offline, no API needed
        let (label, conf) = await VisionAnalysisService.shared.classify(image: image)
        let dx = CropProblem.diagnose(label: label, confidence: conf)
        await commit(dx)
    }

    // MARK: - Demo scan (no photo needed)
    func simulateScan() async {
        guard scanState == .idle else { return }
        await MainActor.run { scanState = .scanning }
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        let s = CropProblem.sampleHistory.randomElement()!
        await commit(CropProblem(
            cropName: s.cropName, disease: s.disease,
            scientificName: s.scientificName, remedy: s.remedy,
            symptoms: s.symptoms, severity: s.severity,
            confidence: Double.random(in: 0.82...0.97)
        ))
    }

    @MainActor
    func commit(_ dx: CropProblem) {
        currentDiagnosis = dx
        scanHistory.insert(dx, at: 0)
        // Persist updated history for offline access
        OfflineCacheService.shared.saveScanHistory(scanHistory)
        fireHaptic(dx.severity)
        scanState = .diagnosed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.showResult = true }
    }

    func reset() {
        stopSpeaking()
        scanState = .idle
        showResult = false
        currentDiagnosis = nil
        hapticFlash = nil
    }

    // MARK: - Voice (Sarvam AI online, AVSpeech offline)
    func speak(_ dx: CropProblem) {
        if isSpeaking { stopSpeaking(); return }
        let script = makeScript(dx)
        Task {
            let isOnline = NetworkMonitor.shared.isConnected
            if isOnline && SarvamTTSService.shared.isConfigured,
               let pcm = await SarvamTTSService.shared.synthesize(text: script) {
                await MainActor.run {
                    do {
                        self.player = try AVAudioPlayer(data: pcm)
                        self.player?.play()
                        self.isSpeaking = true
                    } catch { self.avSpeak(script) }
                }
            } else {
                // Offline fallback — AVSpeechSynthesizer works without internet
                await MainActor.run { self.avSpeak(script) }
            }
        }
    }

    func stopSpeaking() {
        synth.stopSpeaking(at: .immediate)
        player?.stop(); player = nil; isSpeaking = false
    }

    private func avSpeak(_ text: String) {
        guard !synth.isSpeaking else { return }
        let utt = AVSpeechUtterance(string: text)
        utt.voice = AVSpeechSynthesisVoice(language: selectedLang.rawValue)
                 ?? AVSpeechSynthesisVoice(language: "en-US")
        utt.rate = 0.42; utt.pitchMultiplier = 1.05; utt.volume = 1.0
        isSpeaking = true
        synth.speak(utt)
    }

    private func makeScript(_ dx: CropProblem) -> String {
        let steps = dx.remedy.components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .enumerated()
            .map { i, s in "Step \(i+1). \(s.trimmingCharacters(in: CharacterSet.decimalDigits.union(.init(charactersIn: ". "))))" }
            .joined(separator: ". ")
        return "\(dx.severity.spokenPrefix). Crop: \(dx.cropName). Disease: \(dx.disease). Confidence \(String(format: "%.0f", dx.confidence*100)) percent. \(steps)."
    }

    // MARK: - Haptics
    private func fireHaptic(_ sev: Severity) {
        hapticFlash = sev
        switch sev {
        case .low:
            hNote.notificationOccurred(.success)
        case .medium:
            hMed.impactOccurred(intensity: 0.75)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) { self.hMed.impactOccurred(intensity: 0.75) }
        case .high:
            hHvy.impactOccurred(intensity: 1.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { self.hHvy.impactOccurred(intensity: 1.0) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) {
                self.hHvy.impactOccurred(intensity: 1.0)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) { self.hNote.notificationOccurred(.error) }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { self.hapticFlash = nil }
    }
}

private final class SynthDelegate: NSObject, AVSpeechSynthesizerDelegate {
    weak var vm: ScannerViewModel?
    init(vm: ScannerViewModel) { self.vm = vm }
    func speechSynthesizer(_: AVSpeechSynthesizer, didFinish _: AVSpeechUtterance) {
        DispatchQueue.main.async { self.vm?.isSpeaking = false }
    }
    func speechSynthesizer(_: AVSpeechSynthesizer, didCancel _: AVSpeechUtterance) {
        DispatchQueue.main.async { self.vm?.isSpeaking = false }
    }
}
