//
//  MainViewController.h
//  Wayback800
//
//  Created by banxian on 7/9/18.
//  Copyright (c) 2018 banxian. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "KeyItem.h"
#include "CheatTypes.h"
//#include "MyLCDView.h"
//#include "MyGLKLCDView2.h"

//typedef struct tagLCDStripe {
//    QRect texture;
//    int left, top;
//} TLCDStripe;

@interface MainViewController : UIViewController {
    bool stageChecked;
    bool stageInited;
    CGSize stageSize;
    CGFloat scalebase;
    CGRect keypadRect;
    int keyColWidth, keyColPad;
    int keyRowHeight, keyRowLabelHeight;
    TKeyItem* fKeyItems[8][8];
    //TLCDStripe fLCDStripes[80];
    //QRect fLCDPixel, fLCDEmpty;
    //MyLCDView* lcdView;
    //MyGLKLCDView2* lcdView2;
}

//@property(readonly) CGSize stageSize;
- (IBAction)onMatrixBtnRelease:(id)sender;
- (IBAction)onMatrixBtnPress:(id)sender;

-(void) initKeypad;
-(void) updateKeyMatrix;
//-(void) initLCDStripe;

@end
