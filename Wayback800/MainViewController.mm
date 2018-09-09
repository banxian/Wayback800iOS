//
//  MainViewController.m
//  Wayback800
//
//  Created by banxian on 7/9/18.
//  Copyright (c) 2018 banxian. All rights reserved.
//

#import "MainViewController.h"
#import "MyRectButton.h"
#import "MyGLKLCDView6.h"
#include "NekoDriver.h"
#include "DbCentre.h"

//TScreenBuffer tempbuffer;

@interface MainViewController ()
{
    float keyCaptionFontSize; // QWER,
    float keyCaptionFontSizeSmall; // tiaochu,
    float keySingleCaptionFontSize;
    float keySingleCaptionFontSizeSmall;
    float keySubscriptFontSize; // right, small (except 123)
    
    float keyLabelFontSize; // upperline
}
//+(TLCDStripe)getCoordInfo:(id)data withKey: (NSString*) key;
@end

id lcdchangelistener = nil; // should be GLKView or UIView or GLKViewController

void NekoDriverLCDChangedCallback();

@implementation MainViewController

- (void)dealloc
{
    /*
    NSLog(@"killed+++");
    theNekoDriver->StopEmulation();
    NSLog(@"killed---");
    //delete[] fLCDStripes;
    delete theNekoDriver;
    theNekoDriver = NULL;*/
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        //[self initLCDStripe];
        stageChecked = false;
        stageInited = false;
        LoadAppSettings();
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
        NSString *txtPath = [documentsDirectory stringByAppendingPathComponent:@"cc800.fls"];
        
        if ([fileManager fileExistsAtPath:txtPath] == NO) {
            NSString *resourcePath = [[NSBundle mainBundle] pathForResource:@"cc800" ofType:@"fls"];
            [fileManager copyItemAtPath:resourcePath toPath:txtPath error:&error];
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - appear hack
- (void)viewDidAppear:(BOOL)animated
{
    //[self.navigationController setNavigationBarHidden:YES];
    [super viewDidAppear:animated];
    
    //NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
    //[[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    
    // Quick hack
    UIApplication *application = [UIApplication sharedApplication];
    
    if (!UIInterfaceOrientationIsPortrait(application.statusBarOrientation)) {
        NSLog(@"Apply dirty fix to get portrait");
        [application setStatusBarOrientation:UIInterfaceOrientationPortrait animated:NO];
    }
    
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
        NSLog(@"interface orientation: %d, device orientation: %d", (int)sborientation, (int)devorientation);
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
            
            if (self.view.bounds.size.width > self.view.bounds.size.height) {
                // real landscape
                NSLog(@"Fake cordinal");
                //[self.navigationController.view setTransform:CGAffineTransformMakeRotation(M_PI_2)];
            }
        }
    }
    if (stageChecked && stageInited == false) {
        // init stage
        //memset(renderLCDBuffer.fPixel, 0xFF, sizeof(renderLCDBuffer.fPixel));

        if (stageSize.width == 640) {
            // iphone 2x
            keypadRect = CGRectMake(1, 244, 318, 168);
            keyColWidth = 30;
            keyColPad = 2; // 60*10+4*9
            keyRowHeight = 20;
            keyRowLabelHeight = 8;
            
            keyCaptionFontSize = 11;
            keyCaptionFontSizeSmall = 7;
            keySingleCaptionFontSize = 10;
            keySingleCaptionFontSizeSmall = 8;
            keySubscriptFontSize = 6;
            keyLabelFontSize = 5;
            
            MyGLKLCDView6* glkview = [[MyGLKLCDView6 alloc] initWithFrame:CGRectMake(0, 0, 320, 160)];// 120 + 20
            glkview.lcdbuffer = &renderLCDBuffer;
            glkview.lcdpos = QPoint(24, 45);
            lcdchangelistener = glkview;
            [glkview initLCDStripe:@"lcdstripe" withJsonFile:[[NSBundle mainBundle] pathForResource:@"lcdstripe_slice_w562" ofType:@"json"] frontPanel:@"frontpanel"];
            [self.view addSubview:glkview];
        }
        if (stageSize.width == 750) {
            // iphone 6, 6s, 7, 8
        }
        if (stageSize.width == 1242) {
            // 6+, 6s+, 7+, 8+ realsize is 1080
            keypadRect = CGRectMake(3, 444, 407, 168);
            keyColWidth = 38;
            keyColPad = 3; // 380+27+7
            keyRowHeight = 30;
            keyRowLabelHeight = 10;
            
            keyCaptionFontSize = 16;
            keyCaptionFontSizeSmall = 10;
            keySingleCaptionFontSize = 15;
            keySingleCaptionFontSizeSmall = 12;
            keySubscriptFontSize = 9;
            keyLabelFontSize = 7;
            
            MyGLKLCDView6* glkview = [[MyGLKLCDView6 alloc] initWithFrame:CGRectMake(0, 0, 414, 23 * 9)]; // 60 *9 = 540
            glkview.lcdbuffer = &renderLCDBuffer;
            glkview.lcdpos = QPoint(45, 75);
            lcdchangelistener = glkview;
            [glkview initLCDStripe:@"lcdstripe" withJsonFile:[[NSBundle mainBundle] pathForResource:@"lcdstripe_slice_w938" ofType:@"json"] frontPanel:@"frontpanel"];
            [self.view addSubview:glkview];

        }
        if (stageSize.width == 1125) {
            // iphone x, 375*3
            keypadRect = CGRectMake(3, 444, 368, 168);
            keyColWidth = 35;
            keyColPad = 2; // 350+18+7
            keyRowHeight = 30;
            keyRowLabelHeight = 10;
            
            keyCaptionFontSize = 15;
            keyCaptionFontSizeSmall = 8;
            keySingleCaptionFontSize = 14;
            keySingleCaptionFontSizeSmall = 11;
            keySubscriptFontSize = 8;
            keyLabelFontSize = 6;
            
            MyGLKLCDView6* glkview = [[MyGLKLCDView6 alloc] initWithFrame:CGRectMake(0, 0, 414, 23 * 9)]; // 60 *9 = 540
            glkview.lcdbuffer = &renderLCDBuffer;
            glkview.lcdpos = QPoint(67, 75);
            lcdchangelistener = glkview;
            // share same 3x on 1080/1125 width but large frontpanel
            [glkview initLCDStripe:@"lcdstripe" withJsonFile:[[NSBundle mainBundle] pathForResource:@"lcdstripe_slice_w938" ofType:@"json"] frontPanel:@"frontpanelx"];
            [self.view addSubview:glkview];
        }
        if (stageSize.width == 1536) {
            // ipad2 mini
            // iphone 2x
            keypadRect = CGRectMake(2, 400, 764, 390);
            keyColWidth = 71;
            keyColPad = 6; // 710+54
            keyRowHeight = 50;
            keyRowLabelHeight = 15;
            
            keyCaptionFontSize = 23;
            keyCaptionFontSizeSmall = 15;
            keySingleCaptionFontSize = 21;
            keySingleCaptionFontSizeSmall = 18;
            keySubscriptFontSize = 13;
            keyLabelFontSize = 11;
            
            MyGLKLCDView6* glkview = [[MyGLKLCDView6 alloc] initWithFrame:CGRectMake(0, 0, 768, 378)];
            glkview.lcdbuffer = &renderLCDBuffer;
            glkview.lcdpos = QPoint(75, 111);
            lcdchangelistener = glkview;
            [glkview initLCDStripe:@"lcdstripe" withJsonFile:[[NSBundle mainBundle] pathForResource:@"lcdstripe_slice_w1313" ofType:@"json"] frontPanel:@"frontpanel"];
            [self.view addSubview:glkview];
        }
        [self initKeypad];
        stageInited = true;
        
        theNekoDriver = new TNekoDriver();
        theNekoDriver->SetLCDBufferChangedCallback(&NekoDriverLCDChangedCallback);
        theNekoDriver->RunDemoBin("");
    }
}

#pragma mark - ui layout



-(void) initKeypad
{
    TKeyItem* item[8][8] = {
        NULL,       // P10, P30
        NULL,       // P11, P30
        new TKeyItem(18, NULL, NULL, "ON/OFF"),        // GND, P30
        NULL,       // P??, P30
        NULL,       // P??, P30
        NULL,       // P??, P30
        NULL,       // P??, P30
        NULL,       // P??, P30
        
        new TKeyItem(0, "英汉", NULL, "汉英"),          // P00, P30
        new TKeyItem(1, "名片", NULL, "通讯"),          // P01, P30
        new TKeyItem(2, "计算", NULL, "换算"),          // P02, P30
        new TKeyItem(3, "行程", NULL, "记事"),          // P03, P30
        new TKeyItem(4, "资料", NULL, "游戏"),          // P04, P30
        new TKeyItem(5, "时间", NULL, "其他"),        // P05, P30
        new TKeyItem(6, "网络", NULL, NULL),        // P06, P30
        NULL,       // P07, P30
        
        new TKeyItem(50, "求助", NULL),  // P00, P12
        new TKeyItem(51, "中英数", NULL, "SHIFT"),   // P01, P12
        new TKeyItem(52, "输入法", NULL, "反查 CAPS"), // P02, P12
        new TKeyItem(53, "跳出", "AC"),     // P03, P12
        new TKeyItem(54, "符\n号", "0", "继续"),           // P04, P12
        new TKeyItem(55, ".", ".", "-"),      // P05, P12
        new TKeyItem(56, "空格", "=", "✓"),       // P06, P12
        new TKeyItem(57, "←", ""),     // P07, P12
        
        new TKeyItem(40, "Z", "(", ")"),           // P00, P13
        new TKeyItem(41, "X", "π", "X!"),           // P01, P13
        new TKeyItem(42, "C", "EXP", "。'\""),           // P02, P13
        new TKeyItem(43, "V", "C"),           // P03, P13
        new TKeyItem(44, "B", "1"),           // P04, P13
        new TKeyItem(45, "N", "2"),           // P05, P13
        new TKeyItem(46, "M", "3"),           // P06, P13
        new TKeyItem(47, "⇞", "税"),   // P07, P13
        
        new TKeyItem(30, "A", "log", "10x"),       // P00, P14
        new TKeyItem(31, "S", "ln", "ex"),       // P01, P14
        new TKeyItem(32, "D", "Xʸ", "y√x"),       // P02, P14
        new TKeyItem(33, "F", "√", "X\u00B2"),       // P03, P14
        new TKeyItem(34, "G", "4"),       // P04, P14
        new TKeyItem(35, "H", "5"),       // P05, P14
        new TKeyItem(36, "J", "6"),       // P06, P14
        new TKeyItem(37, "K", "±"),       // P07, P14
        
        new TKeyItem(20, "Q", "sin", "sin-1"),       // P00, P15
        new TKeyItem(21, "W", "cos", "cos-1"),       // P01, P15
        new TKeyItem(22, "E", "tan", "tan-1"),       // P02, P15
        new TKeyItem(23, "R", "1/X", "hyp"),       // P03, P15
        new TKeyItem(24, "T", "7"),       // P04, P15
        new TKeyItem(25, "Y", "8"),       // P05, P15
        new TKeyItem(26, "U", "9"),       // P06, P15
        new TKeyItem(27, "I", "%"),       // P07, P15
        
        new TKeyItem(28, "O", "÷", "#"),           // P00, P16
        new TKeyItem(38, "L", "x", "*"),           // P01, P16
        new TKeyItem(48, "▲", "-"),         // P02, P16
        new TKeyItem(58, "▼", "+"),     // P03, P16
        new TKeyItem(29, "P", "MC", "☎"),           // P04, P16
        new TKeyItem(39, "输入", "MR"),   // P05, P16
        new TKeyItem(49, "⇟", "M-"), // P06, P16
        new TKeyItem(59, "→", "M+"),   // P07, P16
        
        NULL,       // P00, P17
        NULL,       // P01, P17
        new TKeyItem(12, "F1", NULL, "插入"),       // P02, P17
        new TKeyItem(13, "F2", NULL, "删除"),       // P03, P17
        new TKeyItem(14, "F3", NULL, "查找"),       // P04, P17
        new TKeyItem(15, "F4", NULL, "修改"),       // P05, P17
        NULL,       // P06, P17
        NULL,       // P07, P17
    };

    for (int y = 0; y < 8; y++) {
        for (int x = 0; x < 8; x++) {
            fKeyItems[y][x] = item[y][x];
            if (item[y][x] == NULL) {
                //keypadmatrix[y][x] = 2;
            } else {
                int row = item[y][x]->fRow;
                int col = item[y][x]->fColumn;
                int index = row * 10 + col;
                MyRectButton* button = [MyRectButton buttonWithType:UIButtonTypeRoundedRect];
                //button.contentScaleFactor = 1;
                //button.layer.contentsScale = 1;
                button.tag = y * 0x10 + x;
                button.frame = CGRectMake(keypadRect.origin.x + (keyColWidth + keyColPad) * col, keypadRect.origin.y + keyRowHeight * row + keyRowLabelHeight * (row + 1), keyColWidth, keyRowHeight);
                if (item[y][x]->fGraphic) {
                    button.titleLabel.textColor = [UIColor blackColor];
                    if (item[y][x]->fSubscript) {
                        NSString* graphic = [NSString stringWithCString:item[y][x]->fGraphic encoding:NSUTF8StringEncoding];
                        NSString* subscript = [NSString stringWithCString:item[y][x]->fSubscript encoding:NSUTF8StringEncoding];

                        [button setTitle:graphic forState:UIControlStateNormal];
                        if (index == 53 || index == 56 || index == 39 || (index >= 47 &&index <= 49) || (index >= 57 && index <= 59)) {
                            // 跳出空格输入
                            button.titleLabel.font = [UIFont systemFontOfSize:keyCaptionFontSizeSmall];
                            button.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
                        } else {
                            // QWER
                            button.titleLabel.font = [UIFont systemFontOfSize:keyCaptionFontSize];
                        }
                        button.contentEdgeInsets = UIEdgeInsetsMake(2, 5, 2, 3);
                        button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
                        if (index == 54) {
                            // 符号
                            button.titleLabel.numberOfLines = 2;
                            button.titleLabel.lineBreakMode = NSLineBreakByCharWrapping;
                            button.titleLabel.font = [UIFont systemFontOfSize:keyCaptionFontSizeSmall];
                        }
                        
                        CGRect labelrect = CGRectMake(4, keyRowHeight / 3, keyColWidth - 8, keyRowHeight / 2);
                        if ((index >= 24 && index <= 26) || (index >= 34 && index <= 36) || (index >= 44 && index <= 46)  || (index >= 54 && index <= 55)) {
                            labelrect = CGRectMake(5, 2, keyColWidth - 10, keyRowHeight - 4);
                        }
                        if (index == 53 || index == 56 || index == 39 || (index >= 47 &&index <= 49) || (index >= 57 && index <= 59) || index == 29) {
                            labelrect = CGRectOffset(labelrect, 0, 2);
                        }
                        UILabel* label = [[UILabel alloc] initWithFrame:labelrect];
                        label.text = subscript;
                        //label.userInteractionEnabled = NO;
                        label.textAlignment = NSTextAlignmentRight;
                        if ((index >= 24 && index <= 26) || (index >= 34 && index <= 36) || (index >= 44 && index <= 46)  || (index >= 54 && index <= 55)) {
                            // 789,456,123=QWER
                            label.font = [UIFont systemFontOfSize:keyCaptionFontSize];
                            label.textColor = [UIColor lightGrayColor];
                        } else {
                            // sin,cos
                            label.font = [UIFont systemFontOfSize:keySubscriptFontSize];
                            label.textColor = [UIColor purpleColor];
                        }
                        //label.backgroundColor = [UIColor lightGrayColor];
                        [button addSubview:label];
                        
                        //button.titleLabel.backgroundColor = [UIColor grayColor];
                    } else {
                        // only caption, no subscript
                        if (index >= 50 && index <= 52) {
                            // 求助中英数输入法
                            button.titleLabel.font = [UIFont systemFontOfSize:keySingleCaptionFontSizeSmall];
                        } else {
                            // 英汉名片F1F2
                            button.titleLabel.font = [UIFont systemFontOfSize:keySingleCaptionFontSize];
                        }
                        [button setTitle:[NSString stringWithCString:item[y][x]->fGraphic encoding:NSUTF8StringEncoding] forState:UIControlStateNormal];
                    }
                }
                if ((index >= 24 && index <= 26) || (index >= 34 && index <= 36) || (index >= 44 && index <= 46)  || (index >= 54 && index <= 55)) {
                    [button setBackgroundImagesByType:2];
                } else {
                    [button setBackgroundImagesByType:0];
                }
                [button addTarget:self action:@selector(onMatrixBtnPress:) forControlEvents:UIControlEventTouchDown];
                [button addTarget:self action:@selector(onMatrixBtnRelease:) forControlEvents:UIControlEventTouchUpInside];
                [button addTarget:self action:@selector(onMatrixBtnRelease:) forControlEvents:UIControlEventTouchUpOutside];
                [button addTarget:self action:@selector(onMatrixBtnRelease:) forControlEvents:UIControlEventTouchCancel];
                [self.view addSubview:button];
                if (item[y][x]->fSuperLabel) {
                    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(keypadRect.origin.x + (keyColWidth + keyColPad) * col, keypadRect.origin.y + (keyRowHeight + keyRowLabelHeight) * row, keyColWidth, keyRowLabelHeight)];
                    label.text = [NSString stringWithCString:item[y][x]->fSuperLabel encoding:NSUTF8StringEncoding];
                    label.userInteractionEnabled = NO;
                    label.textColor = [UIColor purpleColor];
                    label.textAlignment = row >1? NSTextAlignmentRight:NSTextAlignmentCenter;
                    label.font = [UIFont systemFontOfSize:keyLabelFontSize];
                    [self.view addSubview:label];
                }
            }
        }
    }
    //onKeypadSizeChanged(fKeypadRect.width(), fKeypadRect.height());
}

extern void CheckSleepFlagAndForceWakeup();
extern void AppendLog(const char* text);

-(void) updateKeyMatrix
{
    // FIXME: ON/OFF detection
    CheckSleepFlagAndForceWakeup();
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Button responders
-(void) onMatrixBtnPress:(id)sender
{
    MyRectButton* button = (MyRectButton*)sender;
    unsigned int yx = button.tag;
    unsigned int y = yx / 16;
    unsigned int x = yx % 16;
    if (y < 8 && x < 8) {
        keypadmatrix[y][x] = 1;
    }
    [self updateKeyMatrix];
}

-(void) onMatrixBtnRelease:(id)sender
{
    MyRectButton* button = (MyRectButton*)sender;
    unsigned int yx = button.tag;
    unsigned int y = yx / 16;
    unsigned int x = yx % 16;
    if (y < 8 && x < 8) {
        keypadmatrix[y][x] = 0;
    }
    [self updateKeyMatrix];
}

@end

#pragma mark - C++
void NekoDriverLCDChangedCallback()
{
    if (lcdchangelistener) {
        [lcdchangelistener performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:NO];
    }
}
