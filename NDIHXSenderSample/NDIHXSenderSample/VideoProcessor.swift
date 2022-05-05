import VideoToolbox

class VideoProcessor {

    public static let defaultWidth: Int32 = 1920
    public static let defaultHeight: Int32 = 1080
    public static let defaultBitrate: UInt32 = 2560 * 1000
    public static let defaultFPS: Float64 = 30

    private var attributes: [NSString: AnyObject] {
        let attributes: [NSString: AnyObject] = [
            kCVPixelBufferIOSurfacePropertiesKey: [:] as AnyObject,
            kCVPixelBufferMetalCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferWidthKey: NSNumber(value: VideoProcessor.defaultWidth),
            kCVPixelBufferHeightKey: NSNumber(value: VideoProcessor.defaultHeight)
        ]
        return attributes
    }

    private var properties: [NSString: NSObject] {
        let properties: [NSString: NSObject] = [
            kVTCompressionPropertyKey_RealTime: kCFBooleanTrue,
            kVTCompressionPropertyKey_AverageBitRate: Int(VideoProcessor.defaultBitrate) as NSObject,
            kVTCompressionPropertyKey_ExpectedFrameRate: NSNumber(value: VideoProcessor.defaultFPS),
            kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration: NSNumber(value: 0.1),
            kVTCompressionPropertyKey_AllowFrameReordering: kCFBooleanFalse,
        ]
        return properties
    }

    private var _compressionSession: VTCompressionSession?
    private var compressionSession: VTCompressionSession? {
        get {
            if _compressionSession == nil {
                guard
                    VTCompressionSessionCreate(
                        allocator: nil,
                        width: VideoProcessor.defaultWidth,
                        height: VideoProcessor.defaultHeight,
                        codecType: kCMVideoCodecType_HEVC,
                        encoderSpecification: nil,
                        imageBufferAttributes: attributes as CFDictionary?,
                        compressedDataAllocator: nil,
                        outputCallback: nil,
                        refcon: nil,
                        compressionSessionOut: &_compressionSession
                    ) == noErr,
                    let session = _compressionSession
                else {
                    print("Failed to create compression session.")
                    return nil
                }

                guard VTSessionSetProperties(session, propertyDictionary: properties as CFDictionary) == noErr else {
                    print("Failed to create compression session: VTSessionSetProperties")
                    return nil
                }

                guard VTCompressionSessionPrepareToEncodeFrames(session) == noErr else {
                    print("Failed to create compression session: VTCompressionSessionPrepareToEncodeFrames")
                    return nil
                }
            }
            return _compressionSession
        }
        set {
            if let session = _compressionSession {
                VTCompressionSessionInvalidate(session)
            }
            _compressionSession = newValue
        }
    }

    func compressAndCallSendHandler(_ sampleBuffer: CMSampleBuffer, sendHandler: @escaping (CMSampleBuffer) -> Void) {
        guard
            let compressionSession = compressionSession,
            let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else { return }

        let presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        VTCompressionSessionEncodeFrame(
            compressionSession,
            imageBuffer: imageBuffer,
            presentationTimeStamp: presentationTimeStamp,
            duration: sampleBuffer.duration,
            frameProperties: nil,
            infoFlagsOut: nil) { (status, _, resultSampleBuffer) in
                guard
                    status == noErr,
                    let resultSampleBuffer = resultSampleBuffer else {

                    print("Compression Failed for frame \(presentationTimeStamp)")
                    return
                }
                sendHandler(resultSampleBuffer)
        }
    }
}
