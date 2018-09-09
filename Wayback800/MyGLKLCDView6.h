//
//  MyGLKLCDView6.h
//  Wayback800
//
//  Created by Banxian on 7/19/18.
//  Copyright © 2018 banxian. All rights reserved.
//

#import <GLKit/GLKit.h>
#include "CheatTypes.h"

typedef struct tagLCDStripe {
    QRect texture;
    int left, top;
} TLCDStripe;

TLCDStripe getCoordInfoWithKey(id json, NSString* key);

@interface MyGLKLCDView6 : GLKView <GLKViewDelegate>
{
    TLCDStripe fLCDStripes[80];
    QRect fLCDPixel, fLCDEmpty;
    CGImageRef fLCDTexture;
    int fTextureWidth, fTextureHeight;
}

@property (nonatomic, assign) TScreenBuffer* lcdbuffer;
@property QPoint lcdpos;

-(void) initLCDStripe:(NSString*)name withJsonFile:(NSString*)jsonpath frontPanel:(NSString*)panel;

@end
