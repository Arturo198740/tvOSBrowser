//
//  HTTPSStreamer.m
//  Wrapper around FFAVPlayerController for streaming HTTPS links with optional headers/options.
//
//  Requires the AVPlayerTouch / FFAVPlayerController framework from imoreapps repo:
//    https://github.com/imoreapps/ffmpeg-avplayer-for-ios-tvos
//
//  Make sure to link the framework and import the module (or include headers).
//

#import "HTTPSStreamer.h"

#if __has_include(<tvOSAVPlayerTouch/tvOSAVPlayerTouch.h>)
@import tvOSAVPlayerTouch;
#elif __has_include("FFAVPlayerController.h")
#import "FFAVPlayerController.h"
#else
#warning "FFAVPlayerController headers not found — make sure tvOSAVPlayerTouch.framework is added to the target."
#endif

#if __has_include("AVOptions.h")
#import "AVOptions.h"
#endif

@interface HTTPSStreamer ()
{
#if __has_include(<tvOSAVPlayerTouch/tvOSAVPlayerTouch.h>) || __has_include("FFAVPlayerController.h")
    FFAVPlayerController *_player;
#endif
    UIView *_containerView;
    UIView *_playerView; // the drawable view returned by player
    BOOL _isPlaying;
}
@end

@implementation HTTPSStreamer

- (instancetype)initWithContainerView:(UIView *)containerView {
    self = [super init];
    if (self) {
        _containerView = containerView;
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
#if __has_include(<tvOSAVPlayerTouch/tvOSAVPlayerTouch.h>) || __has_include("FFAVPlayerController.h")
    _player = [[FFAVPlayerController alloc] init];
    _player.allowBackgroundPlayback = YES;
    _player.shouldAutoPlay = NO;
#endif
}

- (void)dealloc {
    [self stop];
#if __has_include(<tvOSAVPlayerTouch/tvOSAVPlayerTouch.h>) || __has_include("FFAVPLAYERController.h")
    _player = nil;
#endif
}

- (void)playURL:(NSURL *)url headers:(nullable NSDictionary<NSString*, NSString*> *)headers {
    if (!url) return;
    
#if __has_include(<tvOSAVPlayerTouch/tvOSAVPlayerTouch.h>) || __has_include("FFAVPlayerController.h")
    [self stop];
    
    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    options[AVOptionNameAVProbeSize] = @(256 * 1024); // 256KB
    
    if (headers && headers.count > 0) {
        options[AVOptionNameHttpHeader] = headers;
    }
    
    BOOL ok = [_player openMedia:url withOptions:options];
    if (!ok) {
        NSError *err = [NSError errorWithDomain:@"HTTPSStreamer" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"openMedia failed"}];
        [self reportError:err];
        return;
    }
    
    UIView *drawable = [_player drawableView];
    if (drawable) {
        _playerView = drawable;
        _playerView.frame = _containerView.bounds;
        _playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [_containerView addSubview:_playerView];
    }
    
    BOOL started = [_player play:0.0];
    if (!started) {
        [_player resume];
    }
    _isPlaying = YES;
    [self notifyStarted];
#else
    NSError *err = [NSError errorWithDomain:@"HTTPSStreamer" code:-2 userInfo:@{NSLocalizedDescriptionKey:@"FFAVPlayerController framework not linked or headers missing"}];
    [self reportError:err];
#endif
}

- (void)pause {
#if __has_include(<tvOSAVPlayerTouch/tvOSAVPlayerTouch.h>) || __has_include("FFAVPlayerController.h")
    if (_player) {
        [_player pause];
        _isPlaying = NO;
    }
#endif
}

- (void)resume {
#if __has_include(<tvOSAVPlayerTouch/tvOSAVPlayerTouch.h>) || __has_include("FFAVPlayerController.h")
    if (_player) {
        [_player resume];
        _isPlaying = YES;
    }
#endif
}

- (void)stop {
#if __has_include(<tvOSAVPlayerTouch/tvOSAVPlayerTouch.h>) || __has_include("FFAVPlayerController.h")
    if (_player) {
        [_player stop];
    }
#endif
    if (_playerView && _playerView.superview) {
        [_playerView removeFromSuperview];
    }
    _playerView = nil;
    _isPlaying = NO;
}

- (NSTimeInterval)currentTime {
#if __has_include(<tvOSAVPlayerTouch/tvOSAVPlayerTouch.h>) || __has_include("FFAVPlayerController.h")
    if (_player) return [_player currentPlaybackTime];
#endif
    return 0;
}

- (NSTimeInterval)duration {
#if __has_include(<tvOSAVPlayerTouch/tvOSAVPlayerTouch.h>) || __has_include("FFAVPlayerController.h")
    if (_player) return [_player duration];
#endif
    return 0;
}

- (UIView *)playerView {
    return _playerView;
}

#pragma mark - internal helpers

- (void)reportError:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(httpsStreamer:didFailWithError:)]) {
        [self.delegate httpsStreamer:self didFailWithError:error];
    }
    if (self.onError) self.onError(error);
}

- (void)notifyStarted {
    if ([self.delegate respondsToSelector:@selector(httpsStreamerDidStartPlayback:)]) {
        [self.delegate httpsStreamerDidStartPlayback:self];
    }
    if (self.onStarted) self.onStarted();
}

- (void)notifyFinished {
    if ([self.delegate respondsToSelector:@selector(httpsStreamerDidFinishPlayback:)]) {
        [self.delegate httpsStreamerDidFinishPlayback:self];
    }
    if (self.onFinished) self.onFinished();
}

@end
