//
//  MyLCDView.m
//  Wayback800
//
//  Created by banxian on 7/14/18.
//  Copyright (c) 2018 banxian. All rights reserved.
//

#import "MyLCDView.h"

@implementation MyLCDView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.lcdbuffer = 0;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

-(void) initLCDStripe
{
    // build map
    NSString* path = [[NSBundle mainBundle] pathForResource:@"lcdstripe_slice_w576" ofType:@"json"];
    NSError* err = 0;
    NSString* jsonstr = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    if (err) {
        NSLog(@"open json file error:%@", err);
        return;
    }
    NSData* data = [jsonstr dataUsingEncoding:NSUTF8StringEncoding];
    
    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
    TLCDStripe Line = getCoordInfoWithKey(json, @"lcd_line"); // odd
    TLCDStripe Line2 = getCoordInfoWithKey(json, @"lcd_line5"); // even
    TLCDStripe VertBar = getCoordInfoWithKey(json, @"lcd_vertbar");
    TLCDStripe HonzBar = getCoordInfoWithKey(json, @"lcd_hbar");
    fLCDPixel = getCoordInfoWithKey(json, @"lcdpixel").texture;
    fLCDEmpty = getCoordInfoWithKey(json, @"lcdoverlap").texture;
    
    // 7 segment display
    fLCDStripes[2]  = getCoordInfoWithKey(json, @"lcd_seven_vert1");
    fLCDStripes[19] = getCoordInfoWithKey(json, @"lcd_seven_vert2");
    fLCDStripes[0]  = getCoordInfoWithKey(json, @"lcd_seven_vert3");
    fLCDStripes[22] = getCoordInfoWithKey(json, @"lcd_seven_vert4");
    fLCDStripes[1]  = getCoordInfoWithKey(json, @"lcd_seven_honz1");
    fLCDStripes[3]  = getCoordInfoWithKey(json, @"lcd_seven_honz2");
    fLCDStripes[21] = getCoordInfoWithKey(json, @"lcd_seven_honz3");
    int sevenstep = 13;
    // col1
    fLCDStripes[7]  = fLCDStripes[2];
    fLCDStripes[24] = fLCDStripes[19];
    fLCDStripes[5]  = fLCDStripes[0];
    fLCDStripes[26] = fLCDStripes[22];
    fLCDStripes[6]  = fLCDStripes[1];
    fLCDStripes[8]  = fLCDStripes[3];
    fLCDStripes[25] = fLCDStripes[21];
    
    fLCDStripes[7].left += sevenstep;
    fLCDStripes[24].left += sevenstep;
    fLCDStripes[5].left += sevenstep;
    fLCDStripes[26].left += sevenstep;
    fLCDStripes[6].left += sevenstep;
    fLCDStripes[8].left += sevenstep;
    fLCDStripes[25].left += sevenstep;
    // col2
    fLCDStripes[13] = fLCDStripes[7];
    fLCDStripes[29] = fLCDStripes[24];
    fLCDStripes[10] = fLCDStripes[5];
    fLCDStripes[31] = fLCDStripes[26];
    fLCDStripes[11] = fLCDStripes[6];
    fLCDStripes[14] = fLCDStripes[8];
    fLCDStripes[30] = fLCDStripes[25];
    
    fLCDStripes[13].left += sevenstep;
    fLCDStripes[29].left += sevenstep;
    fLCDStripes[10].left += sevenstep;
    fLCDStripes[31].left += sevenstep;
    fLCDStripes[11].left += sevenstep;
    fLCDStripes[14].left += sevenstep;
    fLCDStripes[30].left += sevenstep;
    // col3
    fLCDStripes[17] = fLCDStripes[13];
    fLCDStripes[33] = fLCDStripes[29];
    fLCDStripes[15] = fLCDStripes[10];
    fLCDStripes[35] = fLCDStripes[31];
    fLCDStripes[16] = fLCDStripes[11];
    fLCDStripes[18] = fLCDStripes[14];
    fLCDStripes[34] = fLCDStripes[30];
    
    fLCDStripes[17].left += sevenstep;
    fLCDStripes[33].left += sevenstep;
    fLCDStripes[15].left += sevenstep;
    fLCDStripes[35].left += sevenstep;
    fLCDStripes[16].left += sevenstep;
    fLCDStripes[18].left += sevenstep;
    fLCDStripes[34].left += sevenstep;
    
    // right lines, isodd?
    int linegap = 24;
    fLCDStripes[4] = Line; Line.top += linegap * 2;
    fLCDStripes[12] = Line2; Line2.top += linegap * 2;
    fLCDStripes[20] = Line; Line.top += linegap * 2;
    fLCDStripes[28] = Line2; Line2.top += linegap * 2;
    fLCDStripes[36] = Line; Line.top += linegap * 2;
    fLCDStripes[44] = Line2; Line2.top += linegap * 2;
    fLCDStripes[52] = Line; Line.top += linegap * 2;
    fLCDStripes[60] = Line2; Line2.top += linegap * 2;
    fLCDStripes[68] = Line; Line.top += linegap * 2;
    fLCDStripes[70] = getCoordInfoWithKey(json, @"lcd_right");
    fLCDStripes[74] = Line;
    
    fLCDStripes[38] = getCoordInfoWithKey(json, @"lcd_pgup"); // PageUp
    fLCDStripes[37] = getCoordInfoWithKey(json, @"lcd_star"); //Star;
    fLCDStripes[39] = getCoordInfoWithKey(json, @"lcd_num"); //Num;
    fLCDStripes[40] = getCoordInfoWithKey(json, @"lcd_eng"); //Eng;
    fLCDStripes[41] = getCoordInfoWithKey(json, @"lcd_caps"); //Caps;
    fLCDStripes[42] = getCoordInfoWithKey(json, @"lcd_shift"); //Shift;
    fLCDStripes[46] = getCoordInfoWithKey(json, @"lcd_flash"); //Flash;
    fLCDStripes[47] = getCoordInfoWithKey(json, @"lcd_sound"); //Sound;
    fLCDStripes[48] = getCoordInfoWithKey(json, @"lcd_keyclick"); //KeyClick;
    fLCDStripes[51] = getCoordInfoWithKey(json, @"lcd_sharpbell"); //SharpBell;
    fLCDStripes[50] = getCoordInfoWithKey(json, @"lcd_speaker"); //Speaker;
    fLCDStripes[49] = getCoordInfoWithKey(json, @"lcd_alarm"); //Alarm;
    fLCDStripes[53] = getCoordInfoWithKey(json, @"lcd_microphone"); //Microphone;
    fLCDStripes[54] = getCoordInfoWithKey(json, @"lcd_tap"); //Tape;
    fLCDStripes[55] = getCoordInfoWithKey(json, @"lcd_minus"); //Minus;
    fLCDStripes[58] = getCoordInfoWithKey(json, @"lcd_battery"); //Battery;
    fLCDStripes[59] = getCoordInfoWithKey(json, @"lcd_secret"); //Secret;
    fLCDStripes[61] = getCoordInfoWithKey(json, @"lcd_pgleft"); //PageLeft;
    fLCDStripes[62] = getCoordInfoWithKey(json, @"lcd_pgright"); //PageRight;
    fLCDStripes[63] = getCoordInfoWithKey(json, @"lcd_left"); //Left;
    fLCDStripes[64] = getCoordInfoWithKey(json, @"lcd_pgdown"); //PageDown;
    
    // vertframe
    int vbargap = 18;
    int hbargap = 9;
    fLCDStripes[65] = getCoordInfoWithKey(json, @"lcd_vframe"); //VertFrame;
    fLCDStripes[79] = getCoordInfoWithKey(json, @"lcd_up"); //Up;
    fLCDStripes[43] = VertBar; VertBar.top += vbargap;
    fLCDStripes[45] = VertBar; VertBar.top += vbargap;
    fLCDStripes[56] = VertBar; VertBar.top += vbargap;
    fLCDStripes[78] = VertBar; VertBar.top += vbargap;
    fLCDStripes[77] = VertBar; VertBar.top += vbargap;
    fLCDStripes[57] = VertBar; VertBar.top += vbargap;
    fLCDStripes[76] = VertBar; VertBar.top += vbargap;
    fLCDStripes[75] = VertBar; VertBar.top += vbargap;
    fLCDStripes[73] = VertBar;
    fLCDStripes[66] = getCoordInfoWithKey(json, @"lcd_down"); //Down;
    fLCDStripes[72] = getCoordInfoWithKey(json, @"lcd_hframe"); //HonzFrame;
    fLCDStripes[67] = HonzBar; HonzBar.left += hbargap;
    fLCDStripes[69] = HonzBar; HonzBar.left += hbargap;
    fLCDStripes[71] = HonzBar;
    
    fLCDTexture = [UIImage imageNamed:@"lcdstripe.png"].CGImage;
    fTextureWidth = (int)CGImageGetWidth(fLCDTexture);
    fTextureHeight = (int)CGImageGetHeight(fLCDTexture);
    NSLog(@"texture width:%d, height:%d", fTextureWidth, fTextureHeight);
}

void drawclipped(CGContextRef ctx, CGImageRef image, int left, int top, int width, int height, int x, int y, int w, int h)
{
    CGContextSaveGState(ctx);
    CGContextClipToRect(ctx, CGRectMake(left, top, w, h));
    CGContextDrawImage(ctx, CGRectMake(left - x, top - y, width, height), image);
    CGContextRestoreGState(ctx);
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    if (self->_lcdbuffer == 0 || fLCDTexture == 0) {
        return;
    }
    // Drawing code
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextClearRect(ctx, rect);
    //CGContextSetRGBFillColor(ctx, 0, 1, 0, 1);
    CGContextSaveGState(ctx);
    //CGContextScaleCTM(ctx, 1.0, -1.0);
    CGContextScaleCTM(ctx, 0.5, 0.5);
    TScreenBuffer* buffer = self->_lcdbuffer;
    for (int y = 79; y >= 0; y--) {
        char pixel = buffer->fPixel[(160/8) * y];
        if ((pixel < 0)) {
            TLCDStripe* item = &self->fLCDStripes[y];
            CGContextSaveGState(ctx);
            CGContextClipToRect(ctx, CGRectMake(item->left, item->top, item->texture.w, item->texture.h));
            //CGContextClipToRect(ctx, CGRectMake(item->left, item->top, 80, 80));
            //CGContextSetFillColorWithColor(C)
            //CGContextFillRect(ctx, CGRectMake(item->left, item->top, item->texture.w, item->texture.h));
            CGContextDrawImage(ctx, CGRectMake(item->left - item->texture.x, item->top - item->texture.y, fTextureWidth, fTextureHeight), self->fLCDTexture);
            CGContextRestoreGState(ctx);
            if (y == 70) {
                //break;
            }
        }
    }
    //CGContextClipToRect(ctx, rect);
    //CGContextRestoreGState(ctx);
    //return;
    int index = 0;
    int yp = 0;
    for (int y = 0; y < 80; y++) {
        int xp = 64;
        for (int i = 0; i < 160 / 8; i++) {
            const unsigned char pixel = buffer->fPixel[index];
            // try to shrink jump cost
            if (pixel) {
                if (i && (pixel & 0x80u)) {
                    drawclipped(ctx, self->fLCDTexture, xp, yp, fTextureWidth, fTextureHeight, fLCDPixel.x, fLCDPixel.y, fLCDPixel.w, fLCDPixel.h);
                }
                if (pixel & 0x40) {
                    drawclipped(ctx, self->fLCDTexture, xp + 3, yp, fTextureWidth, fTextureHeight, fLCDPixel.x, fLCDPixel.y, fLCDPixel.w, fLCDPixel.h);
                }
                if (pixel & 0x20) {
                    drawclipped(ctx, self->fLCDTexture, xp + 6, yp, fTextureWidth, fTextureHeight, fLCDPixel.x, fLCDPixel.y, fLCDPixel.w, fLCDPixel.h);
                }
                if (pixel & 0x10) {
                    drawclipped(ctx, self->fLCDTexture, xp + 9, yp, fTextureWidth, fTextureHeight, fLCDPixel.x, fLCDPixel.y, fLCDPixel.w, fLCDPixel.h);
                }
                if (pixel & 0x08) {
                    drawclipped(ctx, self->fLCDTexture, xp + 12, yp, fTextureWidth, fTextureHeight, fLCDPixel.x, fLCDPixel.y, fLCDPixel.w, fLCDPixel.h);
                }
                if (pixel & 0x04) {
                    drawclipped(ctx, self->fLCDTexture, xp + 15, yp, fTextureWidth, fTextureHeight, fLCDPixel.x, fLCDPixel.y, fLCDPixel.w, fLCDPixel.h);
                }
                if (pixel & 0x02) {
                    drawclipped(ctx, self->fLCDTexture, xp + 18, yp, fTextureWidth, fTextureHeight, fLCDPixel.x, fLCDPixel.y, fLCDPixel.w, fLCDPixel.h);
                }
                if (pixel & 0x01) {
                    drawclipped(ctx, self->fLCDTexture, xp + 21, yp, fTextureWidth, fTextureHeight, fLCDPixel.x, fLCDPixel.y, fLCDPixel.w, fLCDPixel.h);
                }
            }
            xp += 24;
            index++;
        }
        yp += 3;
    }
    CGContextRestoreGState(ctx);
}


@end

TLCDStripe getCoordInfoWithKey(id json, NSString* key)
{
    TLCDStripe stripe;
    NSData* sliceframe = [json valueForKey:key];
    if (sliceframe) {
        NSData* slice = [sliceframe valueForKey:@"slice"];
        NSData* frame = [sliceframe valueForKey:@"frame"];
        if (slice) {
            stripe.left = (int)[[slice valueForKey:@"x"] integerValue];
            stripe.top = (int)[[slice valueForKey:@"y"] integerValue];
            
        }
        if (frame) {
            stripe.texture.x = (int)[[frame valueForKey:@"x"] integerValue];
            stripe.texture.y = (int)[[frame valueForKey:@"y"] integerValue];
            stripe.texture.w = (int)[[frame valueForKey:@"w"] integerValue];
            stripe.texture.h = (int)[[frame valueForKey:@"h"] integerValue];
        }
    }
    return stripe;
}
