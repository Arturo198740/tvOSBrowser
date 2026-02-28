//
//  ViewController+AVIntegration.m
//  tvOSBrowser + FFmpeg-AVPlayer integration
//

#import "ViewController.h"
#import "PlayerViewController.h" // from imoreapps demo

@implementation ViewController (AVIntegration)

- (void)presentAVPlayerWithURLString:(NSString *)urlString {
    if (urlString.length == 0) return;
    NSURL *mediaURL = [NSURL URLWithString:urlString];
    if (!mediaURL) return;

    PlayerViewController *playerVC = [[PlayerViewController alloc] init];
    playerVC.mediaURL = mediaURL;
    // optional: set avFormatName or other PlayerViewController properties here
    playerVC.modalPresentationStyle = UIModalPresentationFullScreen;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:playerVC animated:YES completion:nil];
    });
}

@end
