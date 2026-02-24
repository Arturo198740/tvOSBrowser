//
//  HTTPSStreamer.h
//  Simple wrapper around FFAVPlayerController to stream HTTPS links with custom HTTP headers.
//
//  Usage:
//    HTTPSStreamer *s = [[HTTPSStreamer alloc] initWithContainerView:containerView];
//    s.delegate = self; // or use blocks
//    [s playURL:[NSURL URLWithString:@"https://example.com/stream.mp4"] headers:@{ @"User-Agent": @"MyAgent/1.0", @"Referer": @"https://example.com" }];
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HTTPSStreamerDelegate;

@interface HTTPSStreamer : NSObject

@property (nonatomic, weak, nullable) id<HTTPSStreamerDelegate> delegate;

// optional blocks you can set instead of delegate
@property (nonatomic, copy, nullable) void (^onStarted)(void);
@property (nonatomic, copy, nullable) void (^onError)(NSError *error);
@property (nonatomic, copy, nullable) void (^onFinished)(void);

// Designated init. containerView is where video drawable view will be inserted.
- (instancetype)initWithContainerView:(UIView *)containerView NS_DESIGNATED_INITIALIZER;

// Play a URL. headers can be nil or an NSDictionary/NSString per AVOptionNameHttpHeader usage.
- (void)playURL:(NSURL *)url headers:(nullable NSDictionary<NSString*, NSString*> *)headers;

// Basic controls
- (void)pause;
- (void)resume;
- (void)stop;

// Get current playback time/duration (if available)
- (NSTimeInterval)currentTime;
- (NSTimeInterval)duration;

- (nullable UIView *)playerView; // the underlying drawable view (if available)

@end


@protocol HTTPSStreamerDelegate <NSObject>

@optional
- (void)httpsStreamerDidStartPlayback:(HTTPSStreamer *)streamer;
- (void)httpsStreamer:(HTTPSStreamer *)streamer didFailWithError:(NSError *)error;
- (void)httpsStreamerDidFinishPlayback:(HTTPSStreamer *)streamer;

@end

NS_ASSUME_NONNULL_END
