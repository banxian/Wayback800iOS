//
//  ViewController.m
//  Sim800
//
//  Created by banxian on 12/30/12.
//  Copyright (c) 2012 banxian. All rights reserved.
//

#import "MainViewController.h"

#import <QuartzCore/QuartzCore.h>
#include <QtGui/QImage>
#include "NekoDriver.h"
#include "DbCentre.h"
#include "AddonFuncUnt.h"
#include <QtCore/QRegExp>
#include "MainViewBridge.h"
#include <QtGui/QApplication>
#include <QtCore/QDebug>


const void* GetBytePointer(void* info);
void ReleaseBytePointer(void*info, const void* pointer);
size_t GetBytesAtPosition(void* info, void* buffer, off_t position, size_t count);

const void* GetBytePointer(void* info) 
{ 
    // this is currently only called once 
    return info; // info is a pointer to the buffer 
} 

void ReleaseBytePointer(void*info, const void* pointer) 
{ 
    // don't care, just using the one static buffer at the moment 
} 


size_t GetBytesAtPosition(void* info, void* buffer, off_t position, size_t count) 
{ 
    // I don't think this ever gets called 
    memcpy(buffer, ((char*)info) + position, count); 
    return count; 
} 

CGDataProviderDirectCallbacks providerCallbacks = 
{ 0, GetBytePointer, ReleaseBytePointer, GetBytesAtPosition, 0 }; 


static CGImageRef cgIm = NULL; 

static CGDataProviderRef dataProvider = NULL; 
unsigned char* imageData = NULL; 
size_t imageDataSize = 1024 * 768 * 4; 
NSTimer *animationTimer; 
NSTimeInterval animationInterval= 1.0f/12.0f;

static CALayer* benchlayer;

@interface MainViewController ()

@end

@implementation MainViewController

@synthesize stageSize;

#pragma mark -
#pragma mark Initialization

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		// Initialization code
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
        NSString *txtPath = [documentsDirectory stringByAppendingPathComponent:@"cc800.fls"];
        
        if ([fileManager fileExistsAtPath:txtPath] == NO) {
            NSString *resourcePath = [[NSBundle mainBundle] pathForResource:@"cc800" ofType:@"fls"];
            [fileManager copyItemAtPath:resourcePath toPath:txtPath error:&error];
        }

        
        //[self setWantsFullScreenLayout:YES];
        //[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
        stageChecked = false;
        stageInited = false;
        LoadAppSettings();
        //theNekoDriver = new TNekoDriver();
        //bridge = new TMainViewBridge((__bridge void*)self);
        //QObject::connect(theNekoDriver, SIGNAL(singlePrefetchFinished(TPageBundleRec*)),
        //                 bridge, SLOT(onSinglePrefetchFinished(TPageBundleRec*)), Qt::QueuedConnection);
	}
	return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self.navigationController setNavigationBarHidden:YES];
}

-(void) updater 
{
    // Cast
    QCoreApplication::processEvents();
}

-(void) replaceImage: (QImage*) image
{
    NSLog(@"image width:%d, height: %d", image->width(), image->height());
    
    if (image->depth() == 8 || IsGrayscaleImage(*image)) {
        Normalize8bitQImage(*image);
    }
    if (image->depth() != 32) {
        *image = image->convertToFormat(QImage::Format_RGB32, Qt::AutoColor);
    }
    
    CGFloat nativeWidth = image->width();
    CGFloat nativeHeight = image->height();
    CGRect startFrame;
    if (scalebase != 0) {
        startFrame = CGRectMake(int(stageSize.width / scalebase - nativeWidth / scalebase) / 2, int(stageSize.height / scalebase - nativeHeight / scalebase) / 2, nativeWidth / scalebase, nativeHeight / scalebase);
    } else {
        startFrame = CGRectMake(int(stageSize.width - nativeWidth) / 2, int(stageSize.height - nativeHeight) / 2, nativeWidth, nativeHeight);
    }
    //NSLog(@"view frame width:%d, height:%d", int(self.view.frame.size.width), int(self.view.frame.size.height));
    NSLog(@"layer frame pos x:%d, y:%d", int(startFrame.origin.x), int(startFrame.origin.y));
    
    int prevsize = imageDataSize;
    const size_t byteRowSize = nativeWidth * 4;
    imageDataSize = byteRowSize * nativeHeight;
    if (imageData) {
        if (byteRowSize * nativeHeight > prevsize) {
            free(imageData);
            imageData = (unsigned char*) malloc(imageDataSize);
        } else {
            // Keep
        }
    } else {
        imageData = (unsigned char*) malloc(imageDataSize);
    }
    memcpy(imageData, image->bits(), imageDataSize);
    
    if (cgIm) {
        CGImageRelease(cgIm);  // we should do this at some stage... 
        cgIm = nil;
    }
    if (dataProvider) {
        CGDataProviderRelease(dataProvider); 
        dataProvider = nil;
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); 
    dataProvider = 
    CGDataProviderCreateDirect(imageData, imageDataSize, 
                               &providerCallbacks);  // currently global 
    
    cgIm = CGImageCreate 
    (nativeWidth, nativeHeight, 
     8, 32, byteRowSize, colorSpace, 
     kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little, 
     dataProvider, 0, false, kCGRenderingIntentDefault);  // also global, probably doesn't need to be 
    

    benchlayer.contents = (__bridge id)cgIm;
    if (scalebase != 0) {
        benchlayer.contentsScale = 1;
    }
    benchlayer.frame = startFrame;
    //[self.view setNeedsDisplay];
    
    //CGColorSpaceRelease(colorSpace);
    //CGImageRelease(cgIm);
    
    //cgIm = nil;
}

-(void) replaceImage2: (const QImage*) image
{
    qDebug("replaceImage2: image width:%d, height: %d", image->width(), image->height());
    
    if (image->depth() == 8 /*|| IsGrayscaleImage(*image)*/) {
        return;
    }
    if (image->depth() != 32) {
        return;
    }
    
    CGFloat nativeWidth = image->width();
    CGFloat nativeHeight = image->height();
    CGRect startFrame;
    if (scalebase != 0) {
        startFrame = CGRectMake(int(stageSize.width / scalebase - nativeWidth / scalebase) / 2, int(stageSize.height / scalebase - nativeHeight / scalebase) / 2, nativeWidth / scalebase, nativeHeight / scalebase);
    } else {
        startFrame = CGRectMake(int(stageSize.width - nativeWidth) / 2, int(stageSize.height - nativeHeight) / 2, nativeWidth, nativeHeight);
    }
    //NSLog(@"view frame width:%d, height:%d", int(self.view.frame.size.width), int(self.view.frame.size.height));
    qDebug("replaceImage2: layer frame pos x:%d, y:%d", int(startFrame.origin.x), int(startFrame.origin.y));
    
    int prevsize = imageDataSize;
    const size_t byteRowSize = nativeWidth * 4;
    imageDataSize = byteRowSize * nativeHeight;
    if (imageData) {
        if (byteRowSize * nativeHeight > prevsize) {
            free(imageData);
            imageData = (unsigned char*) malloc(imageDataSize);
        } else {
            // Keep
        }
    } else {
        imageData = (unsigned char*) malloc(imageDataSize);
    }
    memcpy(imageData, image->bits(), imageDataSize);
    
    if (cgIm) {
        CGImageRelease(cgIm);  // we should do this at some stage... 
        cgIm = nil;
    }
    if (dataProvider) {
        CGDataProviderRelease(dataProvider); 
        dataProvider = nil;
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); 
    dataProvider = 
    CGDataProviderCreateDirect(imageData, imageDataSize, 
                               &providerCallbacks);  // currently global 
    
    cgIm = CGImageCreate 
    (nativeWidth, nativeHeight, 
     8, 32, byteRowSize, colorSpace, 
     kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little, 
     dataProvider, 0, false, kCGRenderingIntentDefault);  // also global, probably doesn't need to be 
    
    
    benchlayer.contents = (__bridge id)cgIm;
    if (scalebase != 0) {
        benchlayer.contentsScale = 1;
    }
    benchlayer.frame = startFrame;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    if (cgIm) {
        CGImageRelease(cgIm);  // we should do this at some stage... 
        cgIm = NULL;
    }
    if (dataProvider) {
        CGDataProviderRelease(dataProvider); 
        dataProvider = NULL;
    }
    if (imageData){
        free(imageData);
        imageData = NULL;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
//    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
//    
//    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
//        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
//    } else {
//        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
//    }
//    [self setWantsFullScreenLayout:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES];
    [super viewDidAppear:animated];
    
    // Quick hack
    UIApplication *application = [UIApplication sharedApplication];
    
//    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
//        // Landscape
//        if (UIInterfaceOrientationIsPortrait(application.statusBarOrientation)) {
//            NSLog(@"Apply dirty fix to get landscape");
//            [application setStatusBarOrientation:UIInterfaceOrientationLandscapeLeft animated:NO];
//        }
//    } else {
        if (!UIInterfaceOrientationIsPortrait(application.statusBarOrientation)) {
            NSLog(@"Apply dirty fix to get portrait");
            [application setStatusBarOrientation:UIInterfaceOrientationPortrait animated:NO];
        //    [self.navigationController.view setTransform:CGAffineTransformMakeRotation(M_PI_2)];
        //    UIViewController* c = [[UIViewController alloc] init];
        //    [self presentModalViewController:c animated:NO];
        //    [self dismissModalViewControllerAnimated:NO];
        //    c = nil;
        }
    //}
    //[[UIDevice currentDevice] performSelector:NSSelectorFromString(@"setOrien") withObject:(id)UIInterfaceOrientationPortrait];
    
    if (stageChecked == false) {
        UIScreen* screen =[UIScreen mainScreen];
        stageSize = screen.bounds.size;
        if ([screen respondsToSelector: @selector(scale)]) {
            CGFloat scale = screen.scale;
            stageSize = CGSizeMake(stageSize.width * scale, stageSize.height * scale);
            self.view.contentScaleFactor = 1;
            self.view.layer.contentsScale = 1;
            scalebase = scale;
        } else {
            scalebase = 0;
        }
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        // But we may still get unknown orientation
        UIInterfaceOrientation sborientation = [UIApplication sharedApplication].statusBarOrientation; // Never unknown
        UIDeviceOrientation devorientation = [UIDevice currentDevice].orientation;
        NSLog(@"interface orientation: %d, device orientation: %d", sborientation, devorientation);
        //if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
        if (true /*[UIDevice currentDevice].orientation != UIDeviceOrientationUnknown*/) {
            stageChecked = true;
            //NSLog(@"orientation: %d", [UIDevice currentDevice].orientation);
            if (UIInterfaceOrientationIsPortrait(sborientation/*[UIDevice currentDevice].orientation*/)) {
                NSLog(@"portrait width:%d, height:%d", int(stageSize.width), int(stageSize.height));
                // Portrait should width less than height
                if (stageSize.width > stageSize.height) {
                    stageSize = CGSizeMake(stageSize.height, stageSize.width); // swap
                }
            } else {
                NSLog(@"landscape width:%d, height:%d", int(stageSize.width), int(stageSize.height));
                if (stageSize.width < stageSize.height) {
                    stageSize = CGSizeMake(stageSize.height, stageSize.width); // swap
                }
            }
            NSLog(@"final width:%d, height:%d", int(stageSize.width), int(stageSize.height));
//            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
//                if (self.view.bounds.size.width < self.view.bounds.size.height) {
//                    // real portrait
//                    NSLog(@"Fake cordinal");
//                    [self.navigationController.view setTransform:CGAffineTransformMakeRotation(M_PI_2)];
//                }
//            } else {
                if (self.view.bounds.size.width > self.view.bounds.size.height) {
                    // real landscape
                    NSLog(@"Fake cordinal");
                    [self.navigationController.view setTransform:CGAffineTransformMakeRotation(M_PI_2)];
                    //UIViewController* c = [[UIViewController alloc] init];
                    //[self presentModalViewController:c animated:NO];
                    //[self dismissModalViewControllerAnimated:NO];
                    //c = nil;
                }
            //}
        }
    }
    if (stageChecked && stageInited == false) {
        // Initialize
        QImage image;
        image.load([[[NSBundle mainBundle] pathForResource:@"Apollo-nagato-avatar-15-3" ofType:@"jpg"] UTF8String]);

        benchlayer = [CALayer layer];
        if (scalebase != 0) {
            benchlayer.contentsScale = 1;
        }
        
        self.view.layer.backgroundColor = [UIColor grayColor].CGColor;
        [self.view.layer addSublayer:benchlayer];
        stageInited = true;

        [self replaceImage:&image];
        
        //animationTimer = [NSTimer scheduledTimerWithTimeInterval:animationInterval target:self selector:@selector(someRandomFunction) userInfo:nil repeats:YES]; 
        // set up a timer in the attempt to update the image 
        
        bridge = new TMainViewBridge((__bridge void*)self); // stagesize used
       

        animationTimer = [NSTimer scheduledTimerWithTimeInterval:animationInterval target:self selector:@selector(updater) userInfo:nil repeats:YES];
        GlobalSetting.AutoExposure = false; // need optmize
        GlobalSetting.AutoCrop = false; // AutoExpose mixed
        
        bridge->onEmulationStartClicked();
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
    
//    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
//        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
//    }
//    [self setWantsFullScreenLayout:NO];
}

//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
//{
//    // Return YES for supported orientations
//    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
//        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
//    } else {
//        return YES;
//    }
//    return UIInterfaceOrientationIsPortrait(interfaceOrientation);
//    //return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
//}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    //NSLog(@"touchesBegan");
    // MouseDown?
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:touch.view];
    if (scalebase != 0){
        location.x = location.x * scalebase;
        location.y = location.y * scalebase;
    }
    bridge->onMouseDown(location.x, location.y);
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    //NSLog(@"touchesMoved");
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:touch.view];
    if (scalebase != 0){
        location.x = location.x * scalebase;
        location.y = location.y * scalebase;
    }
    bridge->onMouseMove(location.x, location.y);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    //NSLog(@"touchesEnded");
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:touch.view];
    if (scalebase != 0){
        location.x = location.x * scalebase;
        location.y = location.y * scalebase;
    }
    bridge->onMouseUp(location.x, location.y);
}


@end
