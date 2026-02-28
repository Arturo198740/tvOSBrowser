//
//  AVExtractor.m
//  Simple DOM-based extractor for common stream patterns
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface AVExtractor : NSObject
+ (NSString *)extractPlayableURLFromWebView:(UIWebView *)webview;
@end

@implementation AVExtractor

+ (NSString *)extractPlayableURLFromWebView:(UIWebView *)webview {
    // Run a small JS in the UIWebView to find <video> src or common direct links
    NSString *js = @"(function(){ \
        var v = document.querySelector('video'); \
        if (v) { \
            var s = v.currentSrc || v.src; \
            if (s) return s; \
            var src = (v.querySelector('source')||{}).src; \
            if (src) return src; \
        } \
        var a = document.querySelector('a[href$=\".m3u8\"], a[href$=\".mp4\"], a[href$=\".ts\"]'); \
        if (a) return a.href; \
        var html = document.documentElement.innerHTML; \
        var match = html.match(/https?:\\\\/\\\\/[^\\\"'\\\\s]+\\.m3u8/); \
        if (match) return match[0]; \
        return ''; \
    })();";
    @try {
        NSString *maybeURL = [webview stringByEvaluatingJavaScriptFromString:js];
        if (maybeURL && maybeURL.length > 0) return maybeURL;
    } @catch (NSException *ex) {
        return nil;
    }
    return nil;
}

@end
