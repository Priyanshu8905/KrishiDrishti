// Views/Scanner/CameraView.swift
// KrishiDrishti — Custom AVFoundation camera controller with real-time Vision crop tracking, auto-focus, and stabilization

import SwiftUI
import AVFoundation
import Vision

struct CameraView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onImage: (UIImage) -> Void
    var onSelectGallery: (() -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> CustomCameraViewController {
        let controller = CustomCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: CustomCameraViewController, context: Context) {}

    final class Coordinator: NSObject, CustomCameraViewControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func cameraController(_ controller: CustomCameraViewController, didCapture image: UIImage) {
            parent.onImage(image)
            parent.isPresented = false
        }

        func cameraControllerDidCancel(_ controller: CustomCameraViewController) {
            parent.isPresented = false
        }

        func cameraControllerDidSelectGallery(_ controller: CustomCameraViewController) {
            parent.isPresented = false
            parent.onSelectGallery?()
        }
    }
}

// MARK: - CustomCameraViewControllerDelegate
protocol CustomCameraViewControllerDelegate: AnyObject {
    func cameraController(_ controller: CustomCameraViewController, didCapture image: UIImage)
    func cameraControllerDidCancel(_ controller: CustomCameraViewController)
    func cameraControllerDidSelectGallery(_ controller: CustomCameraViewController)
}

// MARK: - CustomCameraViewController Implementation
final class CustomCameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    weak var delegate: CustomCameraViewControllerDelegate?

    private let captureSession = AVCaptureSession()
    private var videoInput: AVCaptureDeviceInput?
    private let videoOutput = AVCaptureVideoDataOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer!

    private let sessionQueue = DispatchQueue(label: "com.krishidrishti.camera.session", qos: .userInitiated)
    private var isSessionConfigured = false

    // UI Overlay Elements
    private let overlayView = UIView()
    private let scanLine = UIView()
    private let boundingBoxView = UIView()
    private let instructionLabel = UILabel()
    private let statusLabel = UILabel()
    private let captureButton = UIButton()
    private let flashButton = UIButton()
    private let closeButton = UIButton()
    private let galleryButton = UIButton()
    private let zoomSlider = UISlider()

    private var frameCounter = 0
    private var autoCaptureCounter = 0
    private var isCapturing = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        checkPermissionsAndConfigure()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sessionQueue.async {
            if self.isSessionConfigured && !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
        startScanLineAnimation()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sessionQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
        setupOverlayAndFrame()
    }

    // MARK: - UI Setup
    private func setupUI() {
        // Preview Layer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        // Bounding Box Overlay (Scanning Frame)
        boundingBoxView.layer.borderColor = UIColor.systemGreen.cgColor
        boundingBoxView.layer.borderWidth = 3.0
        boundingBoxView.layer.cornerRadius = 24
        boundingBoxView.backgroundColor = .clear
        boundingBoxView.layer.shadowColor = UIColor.systemGreen.cgColor
        boundingBoxView.layer.shadowOpacity = 0.5
        boundingBoxView.layer.shadowRadius = 8
        view.addSubview(boundingBoxView)

        // Instruction Label
        instructionLabel.text = "Place Crop Inside Frame"
        instructionLabel.textColor = .white.withAlphaComponent(0.85)
        instructionLabel.font = .systemFont(ofSize: 14, weight: .bold)
        instructionLabel.textAlignment = .center
        view.addSubview(instructionLabel)

        // Scanline animation overlay
        scanLine.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.8)
        scanLine.layer.cornerRadius = 1.5
        view.addSubview(scanLine)

        // Status HUD Label
        statusLabel.font = .systemFont(ofSize: 14, weight: .bold)
        statusLabel.textColor = .white
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        statusLabel.layer.cornerRadius = 10
        statusLabel.clipsToBounds = true
        statusLabel.text = "Scanning crop..."
        view.addSubview(statusLabel)

        // Capture Button (Native Shutter Button Style)
        captureButton.backgroundColor = .white
        captureButton.layer.cornerRadius = 38
        captureButton.layer.borderWidth = 5
        captureButton.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
        captureButton.addTarget(self, action: #selector(handleManualCapture), for: .touchUpInside)
        view.addSubview(captureButton)

        // Flash Button
        flashButton.setImage(UIImage(systemName: "bolt.fill"), for: .normal)
        flashButton.tintColor = .white
        flashButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        flashButton.layer.cornerRadius = 24
        flashButton.addTarget(self, action: #selector(toggleFlash), for: .touchUpInside)
        view.addSubview(flashButton)

        // Close Button
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        closeButton.layer.cornerRadius = 22
        closeButton.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)
        view.addSubview(closeButton)

        // Gallery Button
        galleryButton.setImage(UIImage(systemName: "photo.on.rectangle"), for: .normal)
        galleryButton.tintColor = .white
        galleryButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        galleryButton.layer.cornerRadius = 24
        galleryButton.addTarget(self, action: #selector(handleGalleryTap), for: .touchUpInside)
        view.addSubview(galleryButton)

        // Zoom Slider
        zoomSlider.minimumValue = 1.0
        zoomSlider.maximumValue = 5.0
        zoomSlider.value = 1.0
        zoomSlider.tintColor = .systemGreen
        zoomSlider.addTarget(self, action: #selector(handleZoomSlider(_:)), for: .valueChanged)
        view.addSubview(zoomSlider)

        // Constraints / Layout
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        flashButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        galleryButton.translatesAutoresizingMaskIntoConstraints = false
        zoomSlider.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.widthAnchor.constraint(equalToConstant: 240),
            statusLabel.heightAnchor.constraint(equalToConstant: 44),

            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),

            zoomSlider.bottomAnchor.constraint(equalTo: captureButton.topAnchor, constant: -32),
            zoomSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            zoomSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.widthAnchor.constraint(equalToConstant: 76),
            captureButton.heightAnchor.constraint(equalToConstant: 76),

            flashButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            flashButton.trailingAnchor.constraint(equalTo: captureButton.leadingAnchor, constant: -40),
            flashButton.widthAnchor.constraint(equalToConstant: 48),
            flashButton.heightAnchor.constraint(equalToConstant: 48),

            galleryButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            galleryButton.leadingAnchor.constraint(equalTo: captureButton.trailingAnchor, constant: 40),
            galleryButton.widthAnchor.constraint(equalToConstant: 48),
            galleryButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    private func setupOverlayAndFrame() {
        let frameSize: CGFloat = 260
        let cutoutRect = CGRect(
            x: (view.bounds.width - frameSize) / 2,
            y: (view.bounds.height - frameSize) / 2,
            width: frameSize,
            height: frameSize
        )

        // Setup background dimming overlay with cutout
        overlayView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        overlayView.frame = view.bounds
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        let path = UIBezierPath(rect: view.bounds)
        let cutoutPath = UIBezierPath(roundedRect: cutoutRect, cornerRadius: 24)
        path.append(cutoutPath)
        path.usesEvenOddFillRule = true

        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.fillRule = .evenOdd
        overlayView.layer.mask = maskLayer

        if overlayView.superview == nil {
            view.insertSubview(overlayView, belowSubview: statusLabel)
        }

        boundingBoxView.frame = cutoutRect
        instructionLabel.frame = CGRect(
            x: cutoutRect.minX,
            y: cutoutRect.minY + 20,
            width: cutoutRect.width,
            height: 30
        )
    }

    private func startScanLineAnimation() {
        let frameSize: CGFloat = 260
        let cutoutRect = CGRect(
            x: (view.bounds.width - frameSize) / 2,
            y: (view.bounds.height - frameSize) / 2,
            width: frameSize,
            height: frameSize
        )

        scanLine.layer.removeAllAnimations()
        scanLine.frame = CGRect(x: cutoutRect.minX, y: cutoutRect.minY, width: cutoutRect.width, height: 3)
        scanLine.layer.shadowColor = UIColor.systemGreen.cgColor
        scanLine.layer.shadowOpacity = 0.8
        scanLine.layer.shadowRadius = 4

        UIView.animate(withDuration: 1.5, delay: 0.0, options: [.repeat, .autoreverse], animations: {
            self.scanLine.frame.origin.y = cutoutRect.maxY - 3
        }, completion: nil)
    }

    // MARK: - AVFoundation Configuration
    private func checkPermissionsAndConfigure() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.configureSession()
                } else {
                    self.handleNoPermission()
                }
            }
        default:
            handleNoPermission()
        }
    }

    private func configureSession() {
        sessionQueue.async {
            self.captureSession.beginConfiguration()

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                self.captureSession.commitConfiguration()
                return
            }

            do {
                try device.lockForConfiguration()
                if device.isFocusModeSupported(.continuousAutoFocus) {
                    device.focusMode = .continuousAutoFocus
                }
                if device.isExposureModeSupported(.continuousAutoExposure) {
                    device.exposureMode = .continuousAutoExposure
                }
                device.unlockForConfiguration()

                let input = try AVCaptureDeviceInput(device: device)
                if self.captureSession.canAddInput(input) {
                    self.captureSession.addInput(input)
                    self.videoInput = input
                }

                self.videoOutput.alwaysDiscardsLateVideoFrames = true
                self.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.krishidrishti.camera.framequeue"))
                if self.captureSession.canAddOutput(self.videoOutput) {
                    self.captureSession.addOutput(self.videoOutput)
                }

                if let connection = self.videoOutput.connection(with: .video) {
                    if connection.isVideoStabilizationSupported {
                        connection.preferredVideoStabilizationMode = .auto
                    }
                }

                self.captureSession.commitConfiguration()
                self.isSessionConfigured = true
                self.captureSession.startRunning()
            } catch {
                self.captureSession.commitConfiguration()
            }
        }
    }

    private func handleNoPermission() {
        DispatchQueue.main.async {
            self.statusLabel.text = "Camera access denied. Please enable in Settings."
        }
    }

    // MARK: - Handlers & Actions
    @objc private func handleDismiss() {
        delegate?.cameraControllerDidCancel(self)
    }

    @objc private func toggleFlash() {
        guard let device = videoInput?.device, device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            if device.torchMode == .on {
                device.torchMode = .off
                flashButton.tintColor = .white
            } else {
                try device.setTorchModeOn(level: 1.0)
                flashButton.tintColor = .systemYellow
            }
            device.unlockForConfiguration()
        } catch {}
    }

    @objc private func handleZoomSlider(_ sender: UISlider) {
        guard let device = videoInput?.device else { return }
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = CGFloat(sender.value)
            device.unlockForConfiguration()
        } catch {}
    }

    @objc private func handleManualCapture() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        isCapturing = true
    }

    @objc private func handleGalleryTap() {
        delegate?.cameraControllerDidSelectGallery(self)
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard !isCapturing else {
            if let image = imageFromSampleBuffer(sampleBuffer) {
                DispatchQueue.main.async {
                    self.delegate?.cameraController(self, didCapture: image)
                }
            }
            isCapturing = false
            return
        }

        frameCounter += 1
        guard frameCounter % 5 == 0 else { return }

        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let request = VNGenerateAttentionBasedSaliencyImageRequest { [weak self] request, error in
            guard let self = self else { return }
            guard let results = request.results as? [VNSaliencyImageObservation],
                  let salientObs = results.first,
                  let bounds = salientObs.salientObjects?.first?.boundingBox else {
                DispatchQueue.main.async {
                    self.statusLabel.text = "Scanning crop..."
                }
                return
            }

            DispatchQueue.main.async {
                // Check if crop center is inside scanning frame area (centered 260x260 frame)
                let center = CGPoint(x: bounds.midX, y: 1.0 - bounds.midY)
                let isInFrame = center.x > 0.15 && center.x < 0.85 && center.y > 0.15 && center.y < 0.85

                if isInFrame {
                    self.autoCaptureCounter += 1
                    if self.autoCaptureCounter > 15 { // quick focus triggers capture
                        self.statusLabel.text = "Crop detected"
                        self.isCapturing = true
                        self.autoCaptureCounter = 0
                    } else {
                        self.statusLabel.text = "Hold steady..."
                    }
                } else {
                    self.statusLabel.text = "Place crop inside green frame"
                    self.autoCaptureCounter = 0
                }
            }
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: imageBuffer, orientation: .up, options: [:])
        try? handler.perform([request])
    }

    private func imageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
