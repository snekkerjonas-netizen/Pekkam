import Foundation
import AVFoundation
import UIKit

@MainActor
class CameraManager: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var capturedPhotoData: Data?
    @Published var isSessionRunning = false
    @Published var error: String?
    
    private let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private var currentCamera: AVCaptureDevice?
    private var photoContinuation: CheckedContinuation<AVCapturePhoto, Error>?
    
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
            
            let selectedCamera = selectBestCamera()
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
    
    private func selectBestCamera() -> AVCaptureDevice {
        // Prefer triple camera, then dual wide, then wide
        if let device = AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) {
            return device
        }
        if let device = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) {
            return device
        }
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) 
            ?? AVCaptureDevice.default(for: .video)\!
    }
    
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true
        photoOutput.capturePhoto(with: settings, delegate: self)
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
