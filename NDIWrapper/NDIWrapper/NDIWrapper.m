#import "NDIWrapper.h"
#import "Processing.NDI.Lib.h"
#import "Processing.NDI.Advanced.h"

@implementation NDIWrapper {
    NDIlib_send_instance_t my_ndi_send;
}

+ (void)initialize {
    NDIlib_initialize();
}

- (void)start:(NSString *)name {
    if (my_ndi_send) {
        my_ndi_send = nil;
    }
    NDIlib_send_create_t options;
    options.p_ndi_name = [name cStringUsingEncoding:NSUTF8StringEncoding];
    options.p_groups = NULL;
    options.clock_video = false;
    options.clock_audio = false;
    my_ndi_send = NDIlib_send_create(&options);
    if (!my_ndi_send) {
        NSLog(@"ERROR: Failed to create sender");
    } else {
        NSLog(@"Successfully created sender");
    }
}

- (void)stop {
    if (my_ndi_send) {
        NDIlib_send_destroy(my_ndi_send);
        my_ndi_send = nil;
    }
    NSLog(@"Stoped sender");
}

- (void)sendHEVCCompressedVideo:(CMSampleBufferRef)sampleBuffer
                     isKeyFrame:(bool)isKeyFrame
                            pts:(long long)pts
                            dts:(long long)dts
                            fps:(double)fps
                          width:(int)width
                         height:(int)height {
    if (!my_ndi_send) {
        NSLog(@"ERROR: NDI instance is nil");
        return;
    }

    OSStatus status;

    NSMutableData *avcData = [NSMutableData data];
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t totalLength;
    char *dataPointer;
    status = CMBlockBufferGetDataPointer(dataBuffer, 0, NULL, &totalLength, &dataPointer);
    if (status != noErr) {
        NSLog(@"ERROR: CMBlockBufferGetDataPointer return %d", status);
        return;
    }

    const char bytes[] = {0, 0, 0, 1}; // Header
    NSData *byteHeader = [NSData dataWithBytes:bytes length:4];

    size_t bufferOffset = 0;
    static const int AVCCHeaderLength = 4;
    while (bufferOffset < totalLength - AVCCHeaderLength) {
      // Read the NAL unit length
      uint32_t NALUnitLength = 0;
      memcpy(&NALUnitLength, dataPointer + bufferOffset, AVCCHeaderLength);

      // Convert the length value from Big-endian to Little-endian
      NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);

      NSData *data = [[NSData alloc] initWithBytes:(dataPointer + bufferOffset + AVCCHeaderLength) length:NALUnitLength];

      NSMutableData *fullAVCData = [NSMutableData dataWithData:byteHeader];
      [fullAVCData appendData:data];
      [avcData appendData:fullAVCData];

      bufferOffset += AVCCHeaderLength + NALUnitLength;
    }

    // EXTRA DATA
    NSMutableData *extraData = [NSMutableData data];
    unsigned long parameterCount;
    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
    status = CMVideoFormatDescriptionGetHEVCParameterSetAtIndex(formatDescription, 0, NULL, NULL, &parameterCount, NULL);
    if (status != noErr) {
        NSLog(@"ERROR: CMVideoFormatDescriptionGetHEVCParameterSetAtIndex return %d", status);
        return;
    }

    if (isKeyFrame && parameterCount >= 3) {
        for (int index = 0; index < 3; index++) {
            const uint8_t *parameter;
            size_t parameterSize;
            if (noErr == CMVideoFormatDescriptionGetHEVCParameterSetAtIndex(formatDescription, index, &parameter, &parameterSize, NULL, NULL)) {
                NSData *parameterBody = [NSData dataWithBytes:parameter length:parameterSize];
                [extraData appendData:byteHeader];
                [extraData appendData:parameterBody];
            }
        }
    }

    uint32_t packet_size = sizeof(NDIlib_compressed_packet_t) + (uint32_t)[avcData length] + (uint32_t)[extraData length];
    NDIlib_compressed_packet_t *p_packet = (NDIlib_compressed_packet_t *)malloc(packet_size);
    p_packet->version = NDIlib_compressed_packet_version_0;
    p_packet->fourCC = NDIlib_FourCC_type_HEVC;
    p_packet->pts = pts;
    p_packet->dts = dts;
    p_packet->flags = isKeyFrame ? NDIlib_compressed_packet_flags_keyframe : NDIlib_compressed_packet_flags_none;
    p_packet->data_size = (uint32_t)[avcData length];
    p_packet->extra_data_size = (uint32_t)[extraData length];

    uint8_t *p_dst_hevc_data = (uint8_t *)(1 + p_packet);
    memcpy(p_dst_hevc_data, [avcData bytes], [avcData length]);
    if ([extraData length] > 0) {
        uint8_t *p_dst_extra_data = p_dst_hevc_data + [avcData length];
        memcpy(p_dst_extra_data, [extraData bytes], [extraData length]);
    }

    NDIlib_video_frame_v2_t video_frame = { 0 };
    video_frame.xres = width;
    video_frame.yres = height;
    video_frame.frame_rate_N = [self getFrameRateN:fps];
    video_frame.frame_rate_D = [self getFrameRateD:fps];
    video_frame.FourCC = (NDIlib_FourCC_video_type_e)NDIlib_FourCC_type_HEVC_highest_bandwidth;
    video_frame.picture_aspect_ratio = round((video_frame.yres / video_frame.xres) * 1000) / 1000;
    video_frame.p_metadata = NULL;

    video_frame.frame_format_type = NDIlib_frame_format_type_progressive;
    video_frame.p_data = (unsigned char *)p_packet;
    video_frame.data_size_in_bytes = packet_size;

    NDIlib_send_send_video_async_v2(my_ndi_send, &video_frame);
}

- (int)getFrameRateN:(float)fps {
    if (fps == 20.0) {
        return 20000;
    } else if (fps == 24.0) {
        return 24000;
    } else if (fps == 29.97) {
        return 30000;
    } else if (fps == 30.0) {
        return 30000;
    } else if (fps == 59.94) {
        return 60000;
    } else if (fps == 60.0) {
        return 60000;
    } else {
        return 30000; // defalut
    }
}

- (int)getFrameRateD:(float)fps {
    if (fps == 29.97) {
        return 1001;
    } else if (fps == 59.94) {
        return 1001;
    } else {
        return 1000;
    }
}

@end
