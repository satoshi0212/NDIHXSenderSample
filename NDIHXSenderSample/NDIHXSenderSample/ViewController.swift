import UIKit
import AVFoundation

class ViewController: UIViewController {

    private var ndiWrapper: NDIWrapper = NDIWrapper()
    private var videoProcessor: VideoProcessor = VideoProcessor()
    private var captureSession = AVCaptureSession()
    private var captureDeviceInput: AVCaptureDeviceInput!
    private var videoDataOutput: AVCaptureVideoDataOutput!
    private var device: AVCaptureDevice!
    private var isSending: Bool = false

    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var sendButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        captureSession.sessionPreset = .hd1920x1080
        device = AVCaptureDevice.default(for: .video)
        device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(VideoProcessor.defaultFPS))

        captureDeviceInput = try! AVCaptureDeviceInput(device: device)
        if captureSession.canAddInput(captureDeviceInput) {
            captureSession.addInput(captureDeviceInput)
        }

        videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] as [String: Any]
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
        previewLayer.connection?.videoOrientation = .landscapeRight
        previewLayer.frame = view.frame
        view.layer.insertSublayer(previewLayer, at: 0)

        sendButton = UIButton(frame: CGRect(x: 0, y: 0, width: 120, height: 40))
        sendButton.backgroundColor = .gray
        sendButton.layer.masksToBounds = true
        sendButton.setTitle("Send", for: .normal)
        sendButton.layer.cornerRadius = 18
        sendButton.layer.position = CGPoint(x: view.bounds.width / 2, y: view.bounds.height - 60)
        sendButton.addTarget(self, action: #selector(sendButton_action(sender:)), for: .touchUpInside)
        view.addSubview(sendButton)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
    }

    private func startSending() {
        guard !isSending else { return }
        ndiWrapper.start(UIDevice.current.name)
        sendButton.setTitle("Sending...", for: .normal)
        sendButton.backgroundColor = .blue
        isSending = true
    }

    private func stopSending() {
        guard isSending else { return }
        sendButton.setTitle("Send", for: .normal)
        sendButton.backgroundColor = .gray
        isSending = false
        ndiWrapper.stop()
    }

    @objc private func sendButton_action(sender: UIButton!) {
        if !isSending {
            startSending()
        } else {
            stopSending()
        }
    }

    private func send(sampleBuffer: CMSampleBuffer) {
        guard isSending else { return }

        let isKeyFrame = !sampleBuffer.getIsNotSync()
        let pts: CMTime = sampleBuffer.presentationTimeStamp
        let dts: CMTime = sampleBuffer.decodeTimeStamp

        ndiWrapper.sendHEVCCompressedVideo(
            sampleBuffer,
            isKeyFrame: isKeyFrame,
            pts: pts.seconds.isFinite ? (Int64)(pts.seconds.rounded() * 1000) : 0,
            dts: dts.seconds.isFinite ? (Int64)(dts.seconds.rounded() * 1000) : 0,
            fps: VideoProcessor.defaultFPS,
            width: Int32(VideoProcessor.defaultWidth),
            height: Int32(VideoProcessor.defaultHeight)
        )
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension ViewController : AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard
            CMSampleBufferDataIsReady(sampleBuffer),
            isSending,
            let formatDescription = sampleBuffer.formatDescription
        else {
            return
        }

        switch formatDescription.mediaType {
        case .video:
            videoProcessor.compressAndCallSendHandler(sampleBuffer, sendHandler: send(sampleBuffer:))
        default:
            break
        }
    }
}

// MARK: - Extensions

extension CMSampleBuffer {

    func getIsNotSync() -> Bool {
        guard
            let attachments = CMSampleBufferGetSampleAttachmentsArray(self, createIfNecessary: false) as? [[CFString: Any]],
            let value = attachments.first?[kCMSampleAttachmentKey_NotSync] as? Bool
        else {
            return false
        }
        return value
    }
}
