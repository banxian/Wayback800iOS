//
//  ViewController.h
//  Sim800
//
//  Created by banxian on 12/30/12.
//  Copyright (c) 2012 banxian. All rights reserved.
//

#import <UIKit/UIKit.h>

class TMainViewBridge;
class QImage;

@interface MainViewController : UIViewController {
    TMainViewBridge* bridge;
    bool stageChecked;
    bool stageInited;
    CGSize stageSize;
    CGFloat scalebase;
}

@property(readonly) CGSize stageSize;

-(void) replaceImage: (QImage*) image;
-(void) replaceImage2: (const QImage*) image;

@end
