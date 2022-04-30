#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface NDIWrapper : NSObject

+ (void)initialize;
- (void)start:(NSString *)name;
- (void)stop;
- (void)sendHEVCCompressedVideo:(CMSampleBufferRef)sampleBuffer isKeyFrame:(bool)isKeyFrame pts:(long long)pts dts:(long long)dts fps:(double)fps width:(int)width height:(int)height;

@end
