//
//  ViewController.m
//  Browser
//
//  Created by Steven Troughton-Smith on 20/09/2015.
//  Copyright © 2015 High Caffeine Content. All rights reserved.
//

#import "ViewController.h"
#import <GameController/GameController.h>

// Integration imports (added)
#import "ViewController+AVIntegration.h"
#import "AVExtractor.h"

typedef struct _Input
{
	CGFloat x;
	CGFloat y;
} Input;


@interface ViewController ()
{
	UIView *cursorView;
	Input input;
	NSString *temporaryURL;
}

@property UIWebView *webview;
@property (strong) CADisplayLink *link;
@property (strong, nonatomic) GCController *controller;
@property BOOL cursorMode;
@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	cursorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 64, 64)];
	cursorView.center = CGPointMake(CGRectGetMidX([UIScreen mainScreen].bounds), CGRectGetMidY([UIScreen mainScreen].bounds));
	cursorView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Cursor"]];
	cursorView.hidden = YES;
	
	self.webview = [[UIWebView alloc] initWithFrame:[UIScreen mainScreen].bounds];
	[self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.apple.com"]]];
	
	[self.view addSubview:self.webview];
	[self.view addSubview:cursorView];
	
	self.link = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateCursor)];
	[self.link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
	
	self.webview.scrollView.bounces = YES;
	self.webview.scrollView.panGestureRecognizer.allowedTouchTypes = @[ @(UITouchTypeIndirect) ];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupController) name:GCControllerDidConnectNotification object:nil];
}

-(void)toggleMode
{
	self.cursorMode = !self.cursorMode;
	
	if (self.cursorMode)
	{
		self.webview.scrollView.scrollEnabled = NO;
		self.webview.userInteractionEnabled = NO;
		cursorView.hidden = NO;
	}
	else
	{
		self.webview.scrollView.scrollEnabled = YES;
		self.webview.userInteractionEnabled = YES;
		cursorView.hidden = YES;
	}
}

- (void)alertTextFieldDidChange:(UITextField *)sender
{
	UIAlertController *alertController = (UIAlertController *)self.presentedViewController;
	if (alertController)
	{
		UITextField *urlField = alertController.textFields.firstObject;
		temporaryURL = urlField.text;
	}
}

-(void)pressesEnded:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event
{
	
	if (presses.anyObject.type == UIPressTypeMenu)
	{
		if (self.presentedViewController)
		{
			[self dismissViewControllerAnimated:YES completion:nil];
		}
		else
			[self.webview goBack];
	}
	else if (presses.anyObject.type == UIPressTypeSelect)
	{
		/* Gross. */
		CGPoint point = [self.webview convertPoint:cursorView.frame.origin toView:nil];
		[self.webview stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.elementFromPoint(%i, %i).click()", (int)point.x, (int)point.y]];
	}
	
	else if (presses.anyObject.type == UIPressTypePlayPause)
	{
		// Try to auto-detect a playable URL in the page and present the player
		NSString *maybeURL = [AVExtractor extractPlayableURLFromWebView:self.webview];
		if (maybeURL && maybeURL.length > 0) {
			[self presentAVPlayerWithURLString:maybeURL];
			return;
		}
		
		// Fallback: show address input alert (original behaviour)
		UIAlertController *alertController = [UIAlertController
											  alertControllerWithTitle:@"Enter Address"
											  message:@""
											  preferredStyle:UIAlertControllerStyleAlert];
		
		[alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
		 {
			 textField.keyboardType = UIKeyboardTypeURL;
			 textField.placeholder = @"www.apple.com";
			 [textField addTarget:self
						   action:@selector(alertTextFieldDidChange:)
				 forControlEvents:UIControlEventEditingChanged];

		 }];
		
		UIAlertAction *okAction = [UIAlertAction
								   actionWithTitle:@"OK"
								   style:UIAlertActionStyleDefault
								   handler:^(UIAlertAction *action)
								   {
									   [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@", temporaryURL]]]];
									   temporaryURL = nil;
								   }];
		
		[alertController addAction:okAction];
		
		[self presentViewController:alertController animated:YES completion:nil];
	}
	else if (presses.anyObject.type == UIPressTypeUpArrow)
	{
		[self toggleMode];
	}
}


#pragma mark - Cursor Input

-(void)setupController
{
	self.controller = [GCController controllers].firstObject;
	
	if (!self.controller)
		return;
	
	self.controller.playerIndex = 0;
	
	if (self.controller.microGamepad)
	{
		self.controller.microGamepad.valueChangedHandler = ^(GCMicroGamepad *gamepad, float x, float y) {
			// use dpad for movement
		};
		
		self.controller.microGamepad.reportsAbsoluteDpadValues = NO;
	}
	else if (self.controller.extendedGamepad)
	{
		// handle extended controller if needed
	}
	
	if (self.controller.microGamepad.dpad)
		self.controller.microGamepad.dpad.valueChangedHandler = ^(GCControllerDirectionPad *pad, float x, float y) {
			input.x = x;
			input.y = -y;
		};
}

-(void)updateCursor
{
	CGFloat delta = 5.0;
	
	if (!self.cursorMode)
		return;
	
	if (input.x != 0)
		cursorView.transform = CGAffineTransformTranslate(cursorView.transform, pow(2,delta*fabs(input.x))*(input.x>0?1:-1), 0);
	
	if (input.y != 0)
		cursorView.transform = CGAffineTransformTranslate(cursorView.transform, 0, pow(2,delta*fabs(input.y))*(input.y>0?1:-1));

}

@end
