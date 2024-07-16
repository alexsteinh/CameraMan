import SwiftUI
import AVFoundation

@MainActor struct CameraView: View {
    @State private var viewModel = CameraViewModel()
    @State private var showControls = false
    
    var body: some View {
        _CameraView(captureSession: viewModel.captureSession)
            .ignoresSafeArea()
            .onTapGesture {
                withAnimation(.snappy) {
                    showControls.toggle()
                }
            }
            .overlay(alignment: .bottom) {
                ZStack {
                    if showControls {
                        VStack {
                            ForEach(viewModel.devices, id: \.deviceType) { device in
                                Button(device.localizedName) {
                                    viewModel.selectDevice(device)
                                }
                            }
                        }
                        .padding()
                        .background(.regularMaterial, ignoresSafeAreaEdges: [])
                        .containerShape(RoundedRectangle(cornerRadius: 10))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .onAppear {
                viewModel.startSession()
            }
            .onDisappear {
                viewModel.stopSession()
            }
    }
}

@Observable @MainActor private final class CameraViewModel {
    let captureSession = AVCaptureSession()
    
    private var currentVideoInput: AVCaptureDeviceInput?
    private var isSessionConfigured = false
    private(set) var devices: [AVCaptureDevice] = []
    
    func startSession() {
        configureSession()
        DispatchQueue.global(qos: .userInteractive).async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }
    
    private func configureSession() {
        guard !isSessionConfigured else { return }
        isSessionConfigured = true
        
        let deviceTypes: [AVCaptureDevice.DeviceType] = [
            .builtInUltraWideCamera,
            .builtInWideAngleCamera,
            .builtInTelephotoCamera
        ]
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: .back
        )
        devices = discoverySession.devices
        
        if let defaultDevice = devices.first(where: { $0.deviceType == .builtInWideAngleCamera }) {
            selectDevice(defaultDevice)
        }
    }
    
    func selectDevice(_ device: AVCaptureDevice) {
        guard let videoInput = try? AVCaptureDeviceInput(device: device) else {
            return
        }
        
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        
        if let currentVideoInput {
            captureSession.removeInput(currentVideoInput)
            self.currentVideoInput = nil
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
            currentVideoInput = videoInput
        }
    }
    
    func stopSession() {
        DispatchQueue.global(qos: .userInteractive).async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }
}

private struct _CameraView: UIViewControllerRepresentable {
    let captureSession: AVCaptureSession
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = CameraViewController()
        viewController.captureSession = captureSession
        return viewController
    }
    
    func updateUIViewController(_ uiView: UIViewControllerType, context: Context) {}
}

private final class CameraViewController: UIViewController {
    var captureSession: AVCaptureSession?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let captureSession else {
            return
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
    }
}

#Preview {
    CameraView()
}
