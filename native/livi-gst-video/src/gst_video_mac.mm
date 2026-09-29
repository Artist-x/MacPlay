#include <gst/gst.h>
#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#include <math.h>

static NSWindow *macplayWindow;
static double mpAspect = 16.0 / 9.0;
static double mpWidth = 1920, mpHeight = 1080;
static double mpPanelWidth = 1920, mpPanelHeight = 1080;
static bool mpDefaultFullscreen = false;
static bool mpEnteringFullscreen = false;
static bool mpHideAfterFullscreen = false;

@interface MacPlayVideoWindow : NSWindow
@end
@implementation MacPlayVideoWindow
- (BOOL)canBecomeKeyWindow { return YES; }
- (BOOL)canBecomeMainWindow { return YES; }
@end

// GStreamer's Cocoa GL window requests Regular even when rendering into our
// existing view. Keep the receiver an agent application with no extra Dock icon.
@interface MacPlayVideoApplication : NSApplication
@end
@implementation MacPlayVideoApplication
- (BOOL)setActivationPolicy:(NSApplicationActivationPolicy)policy {
  if (policy == NSApplicationActivationPolicyRegular)
    policy = NSApplicationActivationPolicyAccessory;
  return [super setActivationPolicy:policy];
}
@end

// Convert the physical screen's safe rectangle into the content view's space.
// Intersecting avoids subtracting the notch twice when AppKit already reserves it.
static NSRect mpUsableBounds(NSView *view) {
  NSRect bounds = view.bounds;
  NSWindow *window = view.window;
  if (!(window.styleMask & NSWindowStyleMaskFullScreen)) return bounds;
  if (@available(macOS 12.0, *)) {
    NSScreen *screen = window.screen;
    if (screen) {
      NSEdgeInsets insets = screen.safeAreaInsets;
      NSRect safeScreen = screen.frame;
      safeScreen.origin.x += insets.left;
      safeScreen.origin.y += insets.bottom;
      safeScreen.size.width -= insets.left + insets.right;
      safeScreen.size.height -= insets.top + insets.bottom;
      // AppKit can already size fullscreen content to the notch-safe rectangle.
      // In that case converting through window coordinates can remove another
      // point because of the fullscreen frame's border offset.
      if (bounds.size.width<=safeScreen.size.width && bounds.size.height<=safeScreen.size.height)
        return bounds;
      NSRect safeWindow = [window convertRectFromScreen:safeScreen];
      bounds = NSIntersectionRect(bounds, [view convertRect:safeWindow fromView:nil]);
    }
  }
  return bounds;
}

static NSRect mpVideoRect(NSView *view, double aspect) {
  NSRect bounds = mpUsableBounds(view);
  if (bounds.size.width <= 0 || bounds.size.height <= 0) return NSZeroRect;
  double width = fmin(bounds.size.width, bounds.size.height * aspect);
  double height = width / aspect;
  return NSMakeRect(bounds.origin.x + (bounds.size.width - width) / 2.0,
                    bounds.origin.y + (bounds.size.height - height) / 2.0,
                    width, height);
}

static void mpSetWindowAspect(double aspect) {
  mpAspect = isfinite(aspect) && aspect > 0 ? aspect : 16.0 / 9.0;
  if (!macplayWindow) return;
  [macplayWindow setContentAspectRatio:NSMakeSize(mpAspect, 1.0)];
  if (macplayWindow.styleMask & NSWindowStyleMaskFullScreen) return;

  if (mpEnteringFullscreen) return;
  NSScreen *screen = [NSScreen screens].firstObject;
  if (!screen) return;
  // The desktop's backingScaleFactor can describe a scaled render buffer,
  // not the panel. Map physical video pixels through the physical panel size.
  NSSize fixed = NSMakeSize(mpWidth * screen.frame.size.width / mpPanelWidth,
                            mpHeight * screen.frame.size.height / mpPanelHeight);
  [macplayWindow setContentSize:fixed];
  NSRect visible = screen.visibleFrame, frame = macplayWindow.frame;
  [macplayWindow setFrameOrigin:NSMakePoint(NSMidX(visible)-frame.size.width/2,
                                           NSMidY(visible)-frame.size.height/2)];
}

static void mpLogWindow() {
  NSView *view = macplayWindow.contentView;
  NSRect video = mpVideoRect(view, mpAspect);
  NSLog(@"[MacPlay window] fullscreen=%d movable=%d resizable=%d content=%.3fx%.3f video=%.3fx%.3f pixels=%.0fx%.0f panel=%.0fx%.0f",
        !!(macplayWindow.styleMask & NSWindowStyleMaskFullScreen), macplayWindow.isMovable,
        !!(macplayWindow.styleMask & NSWindowStyleMaskResizable), view.bounds.size.width,
        view.bounds.size.height, video.size.width, video.size.height,
        mpWidth, mpHeight, mpPanelWidth, mpPanelHeight);
}

@interface MacPlayWindowDelegate : NSObject <NSWindowDelegate>
@end
@implementation MacPlayWindowDelegate
- (void)windowDidEnterFullScreen:(NSNotification *)notification {
  (void)notification; mpEnteringFullscreen = false; mpLogWindow();
}
- (void)windowDidFailToEnterFullScreen:(NSWindow *)window {
  (void)window; mpEnteringFullscreen = false;
  NSLog(@"[MacPlay window] failed to enter fullscreen");
}
- (void)windowDidExitFullScreen:(NSNotification *)notification {
  (void)notification; mpSetWindowAspect(mpAspect); mpLogWindow();
  if (mpHideAfterFullscreen) {mpHideAfterFullscreen=false;[macplayWindow orderOut:nil];}
}
@end
static MacPlayWindowDelegate *mpWindowDelegate;

// Layer-hosted GStreamer views need an explicit initial Retina contentsScale;
// waiting only for a backing-properties change can leave a 1x render surface.
static void mpApplyRenderScale(NSView *view) {
  static NSHashTable *loggedLayers;
  if ([view.layer isKindOfClass:[CAOpenGLLayer class]] && view.window) {
    CGFloat scale=view.window.backingScaleFactor;
    CGFloat old=view.layer.contentsScale;
    if (scale>0 && fabs(old-scale)>0.001) {
      view.layer.contentsScale=scale;
      [view setWantsBestResolutionOpenGLSurface:YES];
      [view setNeedsDisplay:YES];
      NSLog(@"[MacPlay render] contentsScale %.3f -> %.3f",old,scale);
    }
    if (!loggedLayers) loggedLayers=[[NSHashTable alloc] initWithOptions:NSPointerFunctionsWeakMemory capacity:8];
    if (![loggedLayers containsObject:view.layer]) {
      [loggedLayers addObject:view.layer];
      NSLog(@"[MacPlay render] contentsScale=%.3f surface=%.0fx%.0f",
            view.layer.contentsScale,view.bounds.size.width*view.layer.contentsScale,
            view.bounds.size.height*view.layer.contentsScale);
    }
  }
  for (NSView *child in view.subviews) mpApplyRenderScale(child);
}

@interface MacPlayRenderHostView : NSView
@end
@implementation MacPlayRenderHostView
- (void)didAddSubview:(NSView *)subview {
  [super didAddSubview:subview];mpApplyRenderScale(subview);
}
- (void)viewDidMoveToWindow {
  [super viewDidMoveToWindow];mpApplyRenderScale(self);
}
- (void)viewDidChangeBackingProperties {
  [super viewDidChangeBackingProperties];mpApplyRenderScale(self);
}
@end

extern "C" void macplay_configure_window(double width, double height,
    double panelWidth, double panelHeight, bool fullscreen) {
  if (!isfinite(width) || !isfinite(height) || !isfinite(panelWidth) ||
      !isfinite(panelHeight) || width <= 0 || height <= 0 ||
      panelWidth <= 0 || panelHeight <= 0) return;
  mpWidth=width; mpHeight=height; mpPanelWidth=panelWidth; mpPanelHeight=panelHeight;
  mpDefaultFullscreen=fullscreen;
  mpSetWindowAspect(width/height);
}

// Clip view: sized to the content rectangle
@interface LIVIClipView : NSView {
@public
  NSView* _gl;  // the GL sink's render target (child view)
  double _cropL, _cropT, _visW, _visH, _tierW, _tierH;  // content region in tier px
@private
  BOOL _relayoutPending;
  BOOL _inLiveResize;
  BOOL _userHidden;
}
- (void)relayout;
- (void)setUserHidden:(BOOL)hidden;
@end

@implementation LIVIClipView
- (NSView*)hitTest:(NSPoint)point {
  return nil;
}

- (void)relayout {
  NSView* sv = [self superview];
  if (!sv) return;
  NSRect available = mpUsableBounds(sv);
  const double ww = available.size.width;
  const double wh = available.size.height;
  if (ww <= 0 || wh <= 0) return;

  // No content region yet: fill the window, child fills the clip view.
  if (_visW <= 0 || _visH <= 0 || _tierW <= 0 || _tierH <= 0) {
    [self setFrame:available];
    [_gl setFrame:self.bounds];
    return;
  }

  // Contain the content AR into the window; the clip view IS that content rect.
  const double scale = fmin(ww / _visW, wh / _visH);
  const double cdw = _visW * scale;
  const double cdh = _visH * scale;
  [self setFrame:NSMakeRect(available.origin.x + (ww - cdw) / 2.0,
                           available.origin.y + (wh - cdh) / 2.0, cdw, cdh)];

  [_gl setFrame:NSMakeRect(-_cropL * scale, -_cropT * scale, _tierW * scale, _tierH * scale)];
  mpApplyRenderScale(_gl);
}

- (void)superviewResized:(NSNotification*)note {
  (void)note;
  // While the window is in an interactive live resize the plane is hidden
  if (_inLiveResize) return;
  if (_relayoutPending) return;
  _relayoutPending = YES;
  dispatch_async(dispatch_get_main_queue(), ^{
    self->_relayoutPending = NO;
    [self relayout];
  });
}

// Logical visibility (cluster shown/hidden)
- (void)setUserHidden:(BOOL)hidden {
  _userHidden = hidden;
  if (!_inLiveResize) [self setHidden:hidden];
}

- (void)windowWillStartLiveResize:(NSNotification*)note {
  (void)note;
  _inLiveResize = YES;
  [self setHidden:YES];
}

- (void)windowDidEndLiveResize:(NSNotification*)note {
  (void)note;
  _inLiveResize = NO;
  [self setHidden:_userHidden];
  [self relayout];
}
@end

extern "C" guintptr livi_attach_view(guintptr parent, void** outView) {
  *outView = nullptr;
  NSView* p = (NSView*)(void*)parent;
  if (!p) return parent;

  LIVIClipView* clip = [[LIVIClipView alloc] initWithFrame:[p bounds]];
  clip->_gl = nullptr;
  clip->_cropL = clip->_cropT = clip->_visW = clip->_visH = clip->_tierW = clip->_tierH = 0;
  [clip setWantsLayer:YES];
  clip.layer.backgroundColor = CGColorGetConstantColor(kCGColorBlack);
  clip.layer.masksToBounds = YES;
  [p addSubview:clip positioned:NSWindowBelow relativeTo:nil];

  NSView* gl = [[MacPlayRenderHostView alloc] initWithFrame:[clip bounds]];
  [gl setWantsLayer:YES];
  [clip addSubview:gl];
  clip->_gl = gl;

  // Re-lay-out whenever the window (content view) resizes.
  [p setPostsFrameChangedNotifications:YES];
  [[NSNotificationCenter defaultCenter] addObserver:clip
                                           selector:@selector(superviewResized:)
                                               name:NSViewFrameDidChangeNotification
                                             object:p];

  // Suspend the plane during an interactive window drag-resize
  NSWindow* win = [p window];
  if (win) {
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:clip
           selector:@selector(windowWillStartLiveResize:)
               name:NSWindowWillStartLiveResizeNotification
             object:win];
    [nc addObserver:clip
           selector:@selector(windowDidEndLiveResize:)
               name:NSWindowDidEndLiveResizeNotification
             object:win];
    for (NSNotificationName name in @[NSWindowDidEnterFullScreenNotification,
                                      NSWindowDidExitFullScreenNotification,
                                      NSWindowDidChangeScreenNotification])
      [nc addObserver:clip selector:@selector(superviewResized:) name:name object:win];
    [nc addObserver:clip selector:@selector(superviewResized:)
                name:NSApplicationDidChangeScreenParametersNotification object:nil];
  }

  *outView = (void*)clip;       // tracked view
  return (guintptr)(void*)gl;   // the GL sink renders into the child
}

// Set the content region (crop) and re-lay-out
extern "C" void livi_set_content_region(void* view, void* sink, double cropL,
    double cropT, double visW, double visH, double tierW, double tierH) {
  (void)sink;
  if (!view) return;
  LIVIClipView* clip = (LIVIClipView*)view;
  clip->_cropL = cropL;
  clip->_cropT = cropT;
  clip->_visW = visW;
  clip->_visH = visH;
  clip->_tierW = tierW;
  clip->_tierH = tierH;
  if (clip.window == macplayWindow && visW > 0 && visH > 0)
    mpSetWindowAspect(visW / visH);
  [clip relayout];
}

extern "C" void livi_remove_view(void* view) {
  if (!view) return;
  NSView* v = (NSView*)view;
  [[NSNotificationCenter defaultCenter] removeObserver:v];
  [v removeFromSuperview];
}

extern "C" void livi_set_view_hidden(void* view, bool hidden) {
  if (!view) return;
  NSView* v = (NSView*)view;
  if ([v isKindOfClass:[LIVIClipView class]]) {
    [(LIVIClipView*)v setUserHidden:hidden];
    return;
  }
  [v setHidden:hidden];
}

extern "C" void livi_set_backdrop(guintptr parent, double r, double g, double b) {
  NSView* p = (NSView*)(void*)parent;
  if (!p) return;
  [p setWantsLayer:YES];
  if (!p.layer) return;
  NSColor* col = [NSColor colorWithSRGBRed:r green:g blue:b alpha:1.0];
  p.layer.backgroundColor = col.CGColor;
}

// MacPlay's standalone AppKit video surface; no browser or HTML UI.
struct MPInput { double x,y; int down; };
static MPInput mpInputs[128]; static int mpRead=0, mpWrite=0;
@interface MacPlayInputView : NSView
@end
@implementation MacPlayInputView
- (BOOL)acceptsFirstResponder { return YES; }
- (void)record:(NSEvent *)event down:(int)down {
 NSPoint p=[self convertPoint:event.locationInWindow fromView:nil];
 NSRect video=mpVideoRect(self,mpAspect);
 if(video.size.width<=0||video.size.height<=0)return;
 double x=(p.x-video.origin.x)/video.size.width,y=1-(p.y-video.origin.y)/video.size.height;
 if(x<0||x>1||y<0||y>1)return;
 int next=(mpWrite+1)%128;if(next==mpRead)return;
 mpInputs[mpWrite]={x,y,down};mpWrite=next;
}
- (void)mouseDown:(NSEvent *)event { [self record:event down:1]; }
- (void)mouseDragged:(NSEvent *)event { [self record:event down:1]; }
- (void)mouseUp:(NSEvent *)event { [self record:event down:0]; }
- (void)keyDown:(NSEvent *)event {
 if(event.keyCode==53) {
  if(macplayWindow.styleMask & NSWindowStyleMaskFullScreen) {
   mpHideAfterFullscreen=true;[macplayWindow toggleFullScreen:nil];
  } else [macplayWindow orderOut:nil];
 }
}
@end
extern "C" uintptr_t macplay_window(double aspect) {
 [MacPlayVideoApplication sharedApplication]; [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
 mpSetWindowAspect(aspect);
 if(!macplayWindow) {
  NSWindowStyleMask style=mpDefaultFullscreen ? NSWindowStyleMaskBorderless :
    NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskMiniaturizable;
  macplayWindow=[[MacPlayVideoWindow alloc] initWithContentRect:NSMakeRect(0,0,1100,1100/mpAspect) styleMask:style backing:NSBackingStoreBuffered defer:NO];
  [macplayWindow setReleasedWhenClosed:NO]; [macplayWindow setTitle:@"MacPlay · CarPlay"];
  [macplayWindow setMovable:!mpDefaultFullscreen]; [macplayWindow setMovableByWindowBackground:NO];
  [macplayWindow setCollectionBehavior:mpDefaultFullscreen ? NSWindowCollectionBehaviorFullScreenPrimary : NSWindowCollectionBehaviorFullScreenNone];
  mpWindowDelegate=[MacPlayWindowDelegate new]; [macplayWindow setDelegate:mpWindowDelegate];
  MacPlayInputView *view=[[MacPlayInputView alloc] initWithFrame:macplayWindow.contentView.bounds];
  [view setWantsLayer:YES];view.layer.backgroundColor=CGColorGetConstantColor(kCGColorBlack);
  [macplayWindow setContentView:view];mpSetWindowAspect(mpAspect);
 }
 [macplayWindow makeKeyAndOrderFront:nil];
 if(mpDefaultFullscreen && !(macplayWindow.styleMask & NSWindowStyleMaskFullScreen) && !mpEnteringFullscreen) {
  mpEnteringFullscreen=true;
  dispatch_async(dispatch_get_main_queue(), ^{[macplayWindow toggleFullScreen:nil];});
 } else if(!mpEnteringFullscreen) mpLogWindow();
 return (uintptr_t)macplayWindow.contentView;
}
extern "C" void macplay_pump() {
 @autoreleasepool {
  // Also cover an NSApplication created by another library before our subclass.
  if (macplayWindow && NSApp.activationPolicy != NSApplicationActivationPolicyAccessory)
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
  NSEvent *event;
  while((event=[NSApp nextEventMatchingMask:NSEventMaskAny untilDate:[NSDate distantPast] inMode:NSDefaultRunLoopMode dequeue:YES])) [NSApp sendEvent:event];
  CFRunLoopRunInMode(kCFRunLoopDefaultMode,0.001,true);
  [NSApp updateWindows];
 }
}
extern "C" int macplay_input(double *x,double *y,int *down) {
 if(mpRead==mpWrite)return 0;MPInput e=mpInputs[mpRead];mpRead=(mpRead+1)%128;
 *x=e.x;*y=e.y;*down=e.down;return 1;
}
