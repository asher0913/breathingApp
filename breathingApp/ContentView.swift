import SwiftUI
import AVFoundation

// MARK: - CameraManager
class CameraManager: ObservableObject {
    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var videoDeviceInput: AVCaptureDeviceInput?
    
    // 是否正在检测
    @Published var isDetecting: Bool = false
    
    init() {
        configureSession()
    }
    
    // 配置 AVCaptureSession
    private func configureSession() {
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                        for: .video,
                                                        position: .front) ??
                                AVCaptureDevice.default(.builtInWideAngleCamera,
                                                        for: .video,
                                                        position: .back)
        else {
            print("cannot access camera")
            return
        }
        
        do {
            let deviceInput = try AVCaptureDeviceInput(device: videoDevice)
            if captureSession.canAddInput(deviceInput) {
                captureSession.addInput(deviceInput)
                self.videoDeviceInput = deviceInput
            }
        } catch {
            print("cannot create input device：\(error.localizedDescription)")
        }
    }
    
    // 启动捕捉会话
    func startSession() {
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .background).async {
                self.captureSession.startRunning()
                DispatchQueue.main.async {
                    self.isDetecting = true
                }
            }
        }
    }
    
    // 停止捕捉会话
    func stopSession() {
        if captureSession.isRunning {
            DispatchQueue.global(qos: .background).async {
                self.captureSession.stopRunning()
                DispatchQueue.main.async {
                    self.isDetecting = false
                }
            }
        }
    }
    
    // 提供 captureSession 供 CameraPreview 使用
    func getCaptureSession() -> AVCaptureSession {
        return captureSession
    }
}

// MARK: - CameraPreview
// SwiftUI 中使用 UIViewRepresentable 来封装相机预览
struct CameraPreview: UIViewRepresentable {
    @ObservedObject var cameraManager: CameraManager
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: cameraManager.getCaptureSession())
        previewLayer.videoGravity = .resizeAspectFill
        
        // 将 previewLayer 填充到父视图
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        
        // 让视图在布局更新时更新 previewLayer 的布局
        context.coordinator.previewLayer = previewLayer
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // 在布局更新时，重新设置 previewLayer 的 frame
        context.coordinator.previewLayer?.frame = uiView.bounds
    }
    
    // 创建一个 Coordinator 来持有 AVCaptureVideoPreviewLayer 的引用，方便在 updateUIView 中更新
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}

// MARK: - ContentView
struct ContentView: View {
    @ObservedObject var cameraManager = CameraManager()
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.5), Color.green.opacity(0.5)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                // 相机预览
                ZStack {
                    CameraPreview(cameraManager: cameraManager)
                        .aspectRatio(3/4, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        .padding()
                    
                    // 当前是否正在检测
                    if cameraManager.isDetecting {
                        Text("breathe detecting...")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(10)
                            .padding()
                    }
                }
                
                Spacer()
                
                // 按钮组
                HStack(spacing: 50) {
                    Button(action: {
                        cameraManager.startSession()
                    }) {
                        Text("START")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 120, height: 44)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        cameraManager.stopSession()
                    }) {
                        Text("END")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 120, height: 44)
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                }
                .padding(.bottom, 50)
            }
        }
    }
}

// MARK: - 预览
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
