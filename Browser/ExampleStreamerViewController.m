//
//  ExampleStreamerViewController.m
//  Example quick-launch for HTTPSStreamer
//

#import "ExampleStreamerViewController.h"

@interface ExampleStreamerViewController ()
{
    HTTPSStreamer *_streamer;
    UIView *_playerContainer;
    BOOL _didShowMenu;
}
@end

@implementation ExampleStreamerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    // Player container fills the view
    _playerContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    _playerContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _playerContainer.backgroundColor = [UIColor blackColor];
    [self.view addSubview:_playerContainer];
    
    // Tap to re-open menu
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showStreamMenu)];
    [self.view addGestureRecognizer:tap];
    
    // Stop playback button in top-right
    UIButton *stopBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    stopBtn.frame = CGRectMake(self.view.bounds.size.width - 120, 30, 100, 44);
    stopBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    [stopBtn setTitle:@"Stop" forState:UIControlStateNormal];
    [stopBtn addTarget:self action:@selector(stopPlayback) forControlEvents:UIControlEventPrimaryActionTriggered];
    [self.view addSubview:stopBtn];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!_didShowMenu) {
        _didShowMenu = YES;
        // show menu on first appearance
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self showStreamMenu];
        });
    }
}

#pragma mark - Menu

- (void)showStreamMenu {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Quick Launch Streams" message:@"Select a site to stream" preferredStyle:UIAlertControllerStyleActionSheet];
    
    NSArray<NSDictionary*> *presets = @[
        @{@"title": @"HD Rezka", @"url": @"https://rezka.ag"},
        @{@"title": @"Kinogo.la", @"url": @"https://kinogo.la"},
        @{@"title": @"Zona.plus", @"url": @"https://w140.zona.plus"},
        @{@"title": @"Lord2025film", @"url": @"https://lord2025film.ru"},
        @{@"title": @"Kinovuzma", @"url": @"https://kinovuzma.online"}
    ];
    
    for (NSDictionary *p in presets) {
        NSString *title = p[@"title"];
        NSString *url = p[@"url"];
        [alert addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self playURLString:url];
        }]];
    }
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Enter URL..." style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self promptForCustomURL];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    // For iPad/tvOS use popover presentation if needed
    alert.popoverPresentationController.sourceView = self.view;
    alert.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds), 1, 1);
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)promptForCustomURL {
    UIAlertController *urlAlert = [UIAlertController alertControllerWithTitle:@"Enter URL" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [urlAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"https://";
        textField.keyboardType = UIKeyboardTypeURL;
    }];
    [urlAlert addAction:[UIAlertAction actionWithTitle:@"Play" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *text = urlAlert.textFields.firstObject.text;
        if (text.length > 0) {
            [self playURLString:text];
        }
    }]];
    [urlAlert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:urlAlert animated:YES completion:nil];
}

#pragma mark - Playback

- (void)playURLString:(NSString *)urlString {
    if (!urlString) return;
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        // try adding https
        url = [NSURL URLWithString:[@"https://" stringByAppendingString:urlString]];
    }
    if (!url) {
        [self showError:@"Invalid URL"];
        return;
    }
    
    // initialize streamer if needed
    if (!_streamer) {
        _streamer = [[HTTPSStreamer alloc] initWithContainerView:_playerContainer];
        _streamer.delegate = self;
        __weak typeof(self) wself = self;
        _streamer.onError = ^(NSError *err){
            __strong typeof(wself) s = wself;
            [s showError:err.localizedDescription ?: @"Playback error"];
        };
    } else {
        // stop previous before playing new
        [_streamer stop];
    }
    
    // Example headers — you can modify or remove these
    NSDictionary *headers = @{ @"User-Agent": @"EagleBrowser/1.0", @"Referer": @"https://google.com" };
    
    [_streamer playURL:url headers:headers];
}

- (void)stopPlayback {
    if (_streamer) {
        [_streamer stop];
    }
}

#pragma mark - HTTPSStreamerDelegate

- (void)httpsStreamerDidStartPlayback:(HTTPSStreamer *)streamer {
    NSLog(@"Streamer started playback");
}

- (void)httpsStreamer:(HTTPSStreamer *)streamer didFailWithError:(NSError *)error {
    [self showError:error.localizedDescription ?: @"Playback failed"];
}

- (void)httpsStreamerDidFinishPlayback:(HTTPSStreamer *)streamer {
    NSLog(@"Streamer finished playback");
}

#pragma mark - Helpers

- (void)showError:(NSString *)msg {
    if (!msg) msg = @"Unknown error";
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Error" message:msg preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)dealloc {
    [_streamer stop];
    _streamer = nil;
}

@end
