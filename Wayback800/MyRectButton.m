//
//  MyRectButton.m
//  Wayback800
//
//  Created by banxian on 7/12/18.
//  Copyright (c) 2018 banxian. All rights reserved.
//

#import "MyRectButton.h"

@implementation MyRectButton

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        //self.layer.borderWidth = 1; // or 0.5
        //self.layer.borderColor = [UIColor purpleColor].CGColor;
        //self.layer.cornerRadius = 2;
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

/*
- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    self.backgroundColor = UIColorFromRGB(highlighted?0x387038:0x5b705b);
}
*/

-(void)setBackgroundImagesByType:(uint)type
{
    //int width = self.frame.size.width;
    if (type == 0) {
        //[self setBackgroundImage:[UIImage imageNamed:[NSString stringWithFormat:@"keybutton_w%d.png", width]] forState:UIControlStateNormal];
        //[self setBackgroundImage:[UIImage imageNamed:[NSString stringWithFormat:@"keybutton_w%d_down.png", width]] forState:UIControlStateHighlighted];
        [self setBackgroundImage:[UIImage imageNamed:@"keybg_alpha.png"] forState:UIControlStateNormal];
        [self setBackgroundImage:[UIImage imageNamed:@"keybg_alpha_down.png"] forState:UIControlStateHighlighted];
    }
    if (type == 2) {
        //[self setBackgroundImage:[UIImage imageNamed:[NSString stringWithFormat:@"keybutton2_w%d.png", width]] forState:UIControlStateNormal];
        //[self setBackgroundImage:[UIImage imageNamed:[NSString stringWithFormat:@"keybutton2_w%d_down.png", width]] forState:UIControlStateHighlighted];
        [self setBackgroundImage:[UIImage imageNamed:@"keybg_num.png"] forState:UIControlStateNormal];
        [self setBackgroundImage:[UIImage imageNamed:@"keybg_num_down.png"] forState:UIControlStateHighlighted];
    }
}

@end
