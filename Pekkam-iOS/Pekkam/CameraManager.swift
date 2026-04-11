import Foundation
import AVFoundation
import UIKit

@MainActor
class CameraManager: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var capturedPhotoData: Data?
    @Published var isSessionRunning = false
    @Published var error: String?
    @Published var zoomFactor: CGFloat = 1.0
    @Published var flashMode: AVCaptureDevice.FlashMode = .off

    private let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private var currentCamera: AVCaptureDevice?
    private var photoContinuation: CheckedContinuation<AVCapturePhoto, Error>?

    // Available zoom levels for the current device
    var availableZoomFactors: [CGFloat] {
        guard let device = currentCamera else { return [1.0] }
        var factors: [CGFloat] = []
        // Ultra-wide at 0.5x if available
        if device.deviceType == .builtInTripleCamera || device.deviceType == .builtInDualWideCamera {
            factors.append(0.5)
        }
        factors.append(1.0)
        // 2x optical if available
        if device.deviceType == .builtInTripleCamera || device.deviceType == .builtInDualCamera {
            factors.append(2.0)
        }
        // 3x optical if available
        if device.deviceType == .builtInTripleCamera {
            factors.append(3.0)
        }
        // Always offer digital 5x if device supports it
        if device.maxAvailableVideoZoomFactor >= 5.0 && !factors.contains(5.0) {
            // skip to keep it simple
        }
        return factors.isEmpty ? [1.0] : factors
    }
    
    let previewLayer = AVCaptureVideoPreviewLayer()
    
    override init() {
        super.init()
        setupSession()
    }
    
    func setupSession() {
        captureSession.beginConfiguration()
        
        do {
            if captureSession.canSetSessionPreset(.photo) {
                captureSession.sessionPreset = .photo
            }
            
            guard let selectedCamera = selectBestCamera() else {
                // No camera available (e.g. simulator without camera)
                captureSession.commitConfiguration()
                return
            }
            currentCamera = selectedCamera

            let input = try AVCaptureDeviceInput(device: selectedCamera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }
            
            previewLayer.session = captureSession
            previewLayer.videoGravity = .resizeAspectFill
            
            captureSession.commitConfiguration()
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
                Task { @MainActor in
                    self.isSessionRunning = true
                }
            }
        } catch {
            self.error = "Failed to setup camera: \(error.localizedDescription)"
        }
    }
    
    private func selectBestCamera() -> AVCaptureDevice? {
        // Prefer triple camera, then dual wide, then wide angle, then any video device
        if let device = AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) {
            return device
        }
        if let device = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) {
            return device
        }
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            return device
        }
        // Fallback: any available video device (works on simulator too)
        return AVCaptureDevice.default(for: .video)
    }
    
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true
        settings.flashMode = flashMode
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func setZoom(_ factor: CGFloat) {
        guard let device = currentCamera else { return }
        let clamped = min(max(factor, device.minAvailableVideoZoomFactor), min(device.maxAvailableVideoZoomFactor, 10.0))
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = clamped
            device.unlockForConfiguration()
            zoomFactor = clamped
        } catch {
            self.error = "Zoom feilet: \(error.localizedDescription)"
        }
    }

    func cycleFlash() {
        switch flashMode {
        case .off:   flashMode = .on
        case .on:    flashMode = .auto
        case .auto:  flashMode = .off
        @unknown default: flashMode = .off
        }
    }
    
    func flipCamera() {
        guard let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput else { return }
        
        let newPosition: AVCaptureDevice.Position = currentInput.device.position == .back ? .front : .back
        
        captureSession.beginConfiguration()
        if let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) {
            do {
                let newInput = try AVCaptureDeviceInput(device: newDevice)
                captureSession.removeInput(currentInput)
                if captureSession.canAddInput(newInput) {
                    captureSession.addInput(newInput)
                    currentCamera = newDevice
                }
            } catch {
                self.error = "Failed to switch camera: \(error.localizedDescription)"
            }
        }
        captureSession.commitConfiguration()
    }
    
    func stopSession() {
        captureSession.stopRunning()
        isSessionRunning = false
    }
    
    // MARK: - AVCapturePhotoCaptureDelegate
    
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, 
                                didFinishProcessingPhoto photo: AVCapturePhoto, 
                                error: Error?) {
        if let error = error {
            Task { @MainActor in
                self.error = "Photo capture failed: \(error.localizedDescription)"
            }
            return
        }
        
        if let data = photo.fileDataRepresentation() {
            Task { @MainActor in
                self.capturedPhotoData = data
            }
        }
    }
}
