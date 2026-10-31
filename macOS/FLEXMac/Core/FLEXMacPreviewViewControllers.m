//
//  FLEXMacPreviewViewControllers.m
//  FLEX (macOS)
//

#import "FLEXMacPreviewViewControllers.h"
#import "FLEXMacObjectExplorerViewController.h"
#import "FLEXMacUtility.h"

#pragma mark - Image

@interface FLEXMacCheckerboardView : NSView
@end

@implementation FLEXMacCheckerboardView

- (void)drawRect:(NSRect)dirtyRect {
    CGFloat square = 8;
    [NSColor.whiteColor setFill];
    NSRectFill(dirtyRect);
    [[NSColor colorWithWhite:0.85 alpha:1] setFill];
    NSInteger startX = floor(NSMinX(dirtyRect) / square), endX = ceil(NSMaxX(dirtyRect) / square);
    NSInteger startY = floor(NSMinY(dirtyRect) / square), endY = ceil(NSMaxY(dirtyRect) / square);
    for (NSInteger x = startX; x < endX; x++) {
        for (NSInteger y = startY; y < endY; y++) {
            if ((x + y) % 2 == 0) {
                NSRectFill(NSMakeRect(x * square, y * square, square, square));
            }
        }
    }
}

@end

@interface FLEXMacImagePreviewViewController ()
@property (nonatomic) NSImage *image;
@property (nonatomic) NSScrollView *scrollView;
@end

@implementation FLEXMacImagePreviewViewController

+ (instancetype)previewForImage:(NSImage *)image title:(NSString *)title {
    FLEXMacImagePreviewViewController *preview = [self new];
    preview.image = image;
    preview.title = title ?: [NSString stringWithFormat:@"Image %g × %g", image.size.width, image.size.height];
    return preview;
}

- (void)loadView {
    NSImageView *imageView = [NSImageView imageViewWithImage:self.image];
    imageView.imageScaling = NSImageScaleNone;
    NSSize size = self.image.size;
    imageView.frame = NSMakeRect(0, 0, MAX(size.width, 1), MAX(size.height, 1));

    FLEXMacCheckerboardView *background = [[FLEXMacCheckerboardView alloc] initWithFrame:imageView.frame];
    [background addSubview:imageView];

    self.scrollView = [NSScrollView new];
    self.scrollView.hasVerticalScroller = YES;
    self.scrollView.hasHorizontalScroller = YES;
    self.scrollView.allowsMagnification = YES;
    self.scrollView.minMagnification = 0.1;
    self.scrollView.maxMagnification = 16;
    self.scrollView.backgroundColor = NSColor.windowBackgroundColor;
    self.scrollView.documentView = background;
    self.scrollView.frame = NSMakeRect(0, 0, 560, 600);
    self.view = self.scrollView;
}

- (NSArray<NSView *> *)flex_navigationAccessoryViews {
    return @[
        FLEXMacBarButton(@"minus.magnifyingglass", @"−", @"Zoom Out", self, @selector(zoomOut:)),
        FLEXMacBarButton(@"1.magnifyingglass", @"1×", @"Actual Size", self, @selector(actualSize:)),
        FLEXMacBarButton(@"plus.magnifyingglass", @"+", @"Zoom In", self, @selector(zoomIn:)),
        FLEXMacBarButton(@"doc.on.doc", @"Copy", @"Copy Image", self, @selector(copyImage:)),
        FLEXMacBarButton(@"info.circle", @"Explore", @"Explore NSImage", self, @selector(exploreImage:)),
    ];
}

- (void)zoomIn:(id)sender { self.scrollView.magnification *= 1.5; }
- (void)zoomOut:(id)sender { self.scrollView.magnification /= 1.5; }
- (void)actualSize:(id)sender { self.scrollView.magnification = 1; }

- (void)copyImage:(id)sender {
    [NSPasteboard.generalPasteboard clearContents];
    [NSPasteboard.generalPasteboard writeObjects:@[self.image]];
}

- (void)exploreImage:(id)sender {
    [self flex_push:[FLEXMacObjectExplorerViewController explorerForObject:self.image]];
}

@end

#pragma mark - Text

@interface FLEXMacTextViewController ()
@property (nonatomic, copy) NSString *text;
@property (nonatomic) NSTextView *textView;
@end

@implementation FLEXMacTextViewController

+ (instancetype)viewerWithText:(NSString *)text title:(NSString *)title {
    FLEXMacTextViewController *viewer = [self new];
    viewer.text = text ?: @"";
    viewer.title = title ?: @"Text";
    return viewer;
}

- (void)loadView {
    NSScrollView *scrollView = [NSTextView scrollableTextView];
    scrollView.frame = NSMakeRect(0, 0, 560, 600);
    self.textView = scrollView.documentView;
    self.textView.editable = NO;
    self.textView.selectable = YES;
    self.textView.richText = NO;
    self.textView.font = [FLEXMacUtility monospacedFontOfSize:12];
    self.textView.textContainerInset = NSMakeSize(8, 8);
    self.textView.string = self.text;
    self.view = scrollView;
}

- (NSView *)flex_preferredFirstResponder {
    return self.textView;
}

- (NSArray<NSView *> *)flex_navigationAccessoryViews {
    return @[FLEXMacBarButton(@"doc.on.doc", @"Copy", @"Copy All", self, @selector(copyAll:))];
}

- (void)copyAll:(id)sender {
    [FLEXMacUtility copyToPasteboard:self.text];
}

@end
