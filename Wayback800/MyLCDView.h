//
//  MyLCDView.h
//  Wayback800
//
//  Created by banxian on 7/14/18.
//  Copyright (c) 2018 banxian. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "CheatTypes.h"

typedef struct tagLCDStripe {
    QRect texture;
    int left, top;
} TLCDStripe;

TLCDStripe getCoordInfoWithKey(id json, NSString* key);

@interface MyLCDView : UIView
{
    TLCDStripe fLCDStripes[80];
    QRect fLCDPixel, fLCDEmpty;
    CGImageRef fLCDTexture;
    int fTextureWidth, fTextureHeight;
}

@property (nonatomic, assign) TScreenBuffer* lcdbuffer;
//- (id)initWithFrame:(CGRect)frame
-(void) initLCDStripe;

@end
