//
//  MyGLKLCDView6.m
//  Wayback800
//
//  Created by Banxian on 7/19/18.
//  Copyright © 2018 banxian. All rights reserved.
//

#import "MyGLKLCDView6.h"
#import <OpenGLES/ES2/glext.h>
#import "GLHelper.h"

struct ColorTexture
{
    GLuint _offbuffer;
    GLuint _depbuffer;
    GLuint _colortex; // usage?
    GLint _realbuffer;
    ColorTexture(GLuint width, GLuint height);
    ~ColorTexture();
    void begin();
    void end();
};

ColorTexture::ColorTexture(GLuint width, GLuint height)
{
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &_realbuffer);
    
    glGenFramebuffers(1, &_offbuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _offbuffer);
    
    glGenTextures(1, &_colortex);
    glBindTexture(GL_TEXTURE_2D, _colortex);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _colortex, 0);
    
    glGenRenderbuffers(1, &_depbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _depbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, width, height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depbuffer);
    
    //glClearColor(1, 0, 0, 0.8);
    //glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    GLuint status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        printf("framebuffer status: %u\n", status);
    }
    glBindTexture(GL_TEXTURE_2D, 0);
    
    glBindFramebuffer(GL_FRAMEBUFFER, _realbuffer);
}

ColorTexture::~ColorTexture()
{
    glDeleteFramebuffers(1, &_offbuffer);
}

void ColorTexture::begin()
{
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &_realbuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _offbuffer);
}

void ColorTexture::end()
{
    glBindFramebuffer(GL_FRAMEBUFFER, _realbuffer);
}

@interface MyGLKLCDView6() {
    GLuint _stripeArray;
    GLuint _stripeBuffer;
    bool updated;
    //Texture2D* _shadowtex;
    ColorTexture* _shadowtex;
}

@property GLKBaseEffect *effect; // color
@property GLKBaseEffect *effect2; // texture for lcdstripe
@property GLKBaseEffect *effect3; // texture shader for panel
@property GLKBaseEffect *effect4 ; // shadow?
@property GLKTextureInfo * textureInfo;
@property GLKTextureInfo * textureInfo3;

- (void)setupGL;
- (void)tearDownGL;


@end

// 160*80, overlap, front, middle(shadow)
#define MAX_STRIPE_VTX_CNT 160*80*4+16

typedef GLfloat GLfloat3d[3];
typedef GLfloat GLfloat5d[5];


GLfloat5d stripeData6[MAX_STRIPE_VTX_CNT];

static int currentStripeCounter = 0;

void addStripe6(GLfloat x, GLfloat y, GLfloat z, GLfloat tx, GLfloat ty)
{
    assert(currentStripeCounter < MAX_STRIPE_VTX_CNT);
    
    stripeData6[currentStripeCounter][0] = x;
    stripeData6[currentStripeCounter][1] = y;
    stripeData6[currentStripeCounter][2] = z;
    
    stripeData6[currentStripeCounter][3] = tx; // texture?
    stripeData6[currentStripeCounter][4] = ty; // texture?
    
    ++currentStripeCounter;
}


@implementation MyGLKLCDView6

-(void)dealloc
{
    // no duprt
    self.delegate = nil;
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self == 0) {
        return self;
    }
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    self.delegate = self;
    //self.opaque = NO;
    
    [self setupGL];
    
    updated = false;
    
    return self;
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.useConstantColor = GL_TRUE;
    
    self.effect2 = [[GLKBaseEffect alloc] init];
    self.effect2.texture2d0.enabled = GL_TRUE;
    
    self.effect3 = [[GLKBaseEffect alloc] init];
    self.effect3.texture2d0.enabled = GL_TRUE;
    
    //[self setupRectangles];
    self.effect4 = [[GLKBaseEffect alloc] init];
    self.effect4.texture2d0.enabled = GL_TRUE;
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    //glDeleteBuffers(1, &_vertexBuffer);
    //glDeleteVertexArraysOES(1, &_vertexArray);
    glDeleteBuffers(1, &_stripeBuffer);
    glDeleteVertexArraysOES(1, &_stripeArray);
    
    self.effect = nil;
    if (_shadowtex) {
        delete _shadowtex;
        _shadowtex = NULL;
    }
}

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

struct TStripeMiscInfo
{
    struct {
        int sevenseg;
        int line;
        bool oddline;
    } gap;
    struct {
        int width;
        int height;
    } lcd;
};

TStripeMiscInfo getStripeMiscInfo(id json)
{
    TStripeMiscInfo info;
    id misc = [json valueForKey:@"misc"];
    if (misc) {
        id gap = [misc valueForKey:@"gap"];
        id lcd = [misc valueForKey:@"lcd"];
        if (gap) {
            info.gap.sevenseg = (int)[[gap valueForKey:@"7seg"] integerValue];
            info.gap.line = (int)[[gap valueForKey:@"line"] integerValue];
            info.gap.oddline = [[gap valueForKey:@"oddline"] boolValue];
        }
        if (lcd) {
            info.lcd.width = (int)[[lcd valueForKey:@"w"] integerValue];
            info.lcd.height = (int)[[lcd valueForKey:@"h"] integerValue];
        }
    }
    return info;
}

-(void) initLCDStripe:(NSString*)name withJsonFile:(NSString*)jsonpath frontPanel:(NSString*)panel
{
    // build map
    NSError* err = 0;
    NSString* jsonstr = [NSString stringWithContentsOfFile:jsonpath encoding:NSUTF8StringEncoding error:&err];
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
    TLCDStripe Pixel = getCoordInfoWithKey(json, @"lcdpixel");
    fLCDPixel = Pixel.texture;
    fLCDEmpty = getCoordInfoWithKey(json, @"lcdoverlap").texture;
    TStripeMiscInfo gap = getStripeMiscInfo(json);
    
    // 7 segment display
    fLCDStripes[2]  = getCoordInfoWithKey(json, @"lcd_seven_vert1");
    fLCDStripes[33] = getCoordInfoWithKey(json, @"lcd_seven_vert2");
    fLCDStripes[0]  = getCoordInfoWithKey(json, @"lcd_seven_vert3");
    fLCDStripes[35] = getCoordInfoWithKey(json, @"lcd_seven_vert4");
    fLCDStripes[1]  = getCoordInfoWithKey(json, @"lcd_seven_honz1");
    fLCDStripes[3]  = getCoordInfoWithKey(json, @"lcd_seven_honz2");
    fLCDStripes[34] = getCoordInfoWithKey(json, @"lcd_seven_honz3");
    int sevenstep = gap.gap.sevenseg;
    // col1
    fLCDStripes[7]  = fLCDStripes[2];
    fLCDStripes[29] = fLCDStripes[33];
    fLCDStripes[5]  = fLCDStripes[0];
    fLCDStripes[31] = fLCDStripes[35];
    fLCDStripes[6]  = fLCDStripes[1];
    fLCDStripes[8]  = fLCDStripes[3];
    fLCDStripes[30] = fLCDStripes[34];
    
    fLCDStripes[7].left += sevenstep;
    fLCDStripes[29].left += sevenstep;
    fLCDStripes[5].left += sevenstep;
    fLCDStripes[31].left += sevenstep;
    fLCDStripes[6].left += sevenstep;
    fLCDStripes[8].left += sevenstep;
    fLCDStripes[30].left += sevenstep;
    // col2
    fLCDStripes[13] = fLCDStripes[7];
    fLCDStripes[24] = fLCDStripes[29];
    fLCDStripes[10] = fLCDStripes[5];
    fLCDStripes[26] = fLCDStripes[31];
    fLCDStripes[11] = fLCDStripes[6];
    fLCDStripes[14] = fLCDStripes[8];
    fLCDStripes[25] = fLCDStripes[30];
    
    fLCDStripes[13].left += sevenstep;
    fLCDStripes[24].left += sevenstep;
    fLCDStripes[10].left += sevenstep;
    fLCDStripes[26].left += sevenstep;
    fLCDStripes[11].left += sevenstep;
    fLCDStripes[14].left += sevenstep;
    fLCDStripes[25].left += sevenstep;
    // col3
    fLCDStripes[17] = fLCDStripes[13];
    fLCDStripes[19] = fLCDStripes[24];
    fLCDStripes[15] = fLCDStripes[10];
    fLCDStripes[22] = fLCDStripes[26];
    fLCDStripes[16] = fLCDStripes[11];
    fLCDStripes[18] = fLCDStripes[14];
    fLCDStripes[21] = fLCDStripes[25];
    
    fLCDStripes[17].left += sevenstep;
    fLCDStripes[19].left += sevenstep;
    fLCDStripes[15].left += sevenstep;
    fLCDStripes[22].left += sevenstep;
    fLCDStripes[16].left += sevenstep;
    fLCDStripes[18].left += sevenstep;
    fLCDStripes[21].left += sevenstep;
    
    fLCDStripes[32] = getCoordInfoWithKey(json, @"lcd_point");
    fLCDStripes[9] = getCoordInfoWithKey(json, @"lcd_semicolon");
    fLCDStripes[27] = fLCDStripes[32]; // Point
    fLCDStripes[27].left += sevenstep;
    fLCDStripes[23] = fLCDStripes[27];
    fLCDStripes[23].left += sevenstep;
    
    // right lines, isodd?
    if (gap.gap.oddline) {
        // two rows?
        int linegap = gap.gap.line;
        fLCDStripes[4] = Line; Line.top += linegap;
        fLCDStripes[12] = Line2; Line2.top += linegap;
        fLCDStripes[20] = Line; Line.top += linegap;
        fLCDStripes[28] = Line2; Line2.top += linegap;
        fLCDStripes[36] = Line; Line.top += linegap;
        fLCDStripes[44] = Line2; Line2.top += linegap;
        fLCDStripes[52] = Line; Line.top += linegap;
        fLCDStripes[60] = Line2; Line2.top += linegap;
        fLCDStripes[68] = Line; Line.top += linegap;
        fLCDStripes[70] = getCoordInfoWithKey(json, @"lcd_right");
        fLCDStripes[74] = Line2; // hmm??
    } else {
        int linegap = gap.gap.line; // same gap on each line
        fLCDStripes[4] = Line; Line.top += linegap;
        fLCDStripes[12] = Line; Line.top += linegap;
        fLCDStripes[20] = Line; Line.top += linegap;
        fLCDStripes[28] = Line; Line.top += linegap;
        fLCDStripes[36] = Line; Line.top += linegap;
        fLCDStripes[44] = Line; Line.top += linegap;
        fLCDStripes[52] = Line; Line.top += linegap;
        fLCDStripes[60] = Line; Line.top += linegap;
        fLCDStripes[68] = Line; Line.top += linegap;
        fLCDStripes[70] = getCoordInfoWithKey(json, @"lcd_right");
        fLCDStripes[74] = Line;
    }
    
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
    int vbargap = VertBar.texture.h;
    int hbargap = HonzBar.texture.w;
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
    
    //NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@(1),GLKTextureLoaderOriginBottomLeft, nil];
    CGImageRef stripe = [UIImage imageNamed:name].CGImage;
    //CGImageRef stripe = tryLoadImageFromAssetsWoCache(name);
    self.textureInfo = [GLKTextureLoader textureWithCGImage:stripe options:nil error:nil];
    //CGImageRelease(stripe);
    
    //testUIAssetManager();
    stripe = [UIImage imageNamed:panel].CGImage;
    //stripe = tryLoadImageFromAssetsWoCache(@"frontpanel");
    self.textureInfo3 = [GLKTextureLoader textureWithCGImage:stripe options:nil error:nil];
    //CGImageRelease(stripe);

    //fLCDTexture = stripe;
    self.effect2.texture2d0.enabled = GL_TRUE;
    self.effect2.texture2d0.name = self.textureInfo.name;
    //NSLog(@"new texture2d0 name: %d", self.effect2.texture2d0.name);
    
    self.effect3.texture2d0.enabled = GL_TRUE;
    self.effect3.texture2d0.name = self.textureInfo3.name;
    
    _shadowtex = new ColorTexture(gap.lcd.width, gap.lcd.height);
    self.effect4.texture2d0.enabled = GL_TRUE;
    self.effect4.texture2d0.name = _shadowtex->_colortex;

    GLfloat texx = double(fLCDPixel.x) / self.textureInfo.width, texy = double(fLCDPixel.y) / self.textureInfo.height;
    GLfloat texw = double(fLCDPixel.w) / self.textureInfo.width, texh = double(fLCDPixel.h) / self.textureInfo.height;
    NSLog(@"texx:%f, texy: %f, texw: %f, texh: %f", texx, texy, texw, texh);
    //GLfloat texx = 0, texy = 0;
    //GLfloat texw = 15.0 / 128, texh = 15.0 / 128;
    int statusbarheight = floor([UIApplication sharedApplication].statusBarFrame.size.height * self.contentScaleFactor);
    int top = (self.bounds.size.height * self.contentScaleFactor - gap.lcd.height - statusbarheight) / 3 + statusbarheight;
    int left = (self.bounds.size.width * self.contentScaleFactor - gap.lcd.width) / 3;
    if (self.lcdpos.x == 0 && self.lcdpos.y == 0) {
        self.lcdpos = QPoint(left, top); // totally
    } else {
        left = self.lcdpos.x;
        top = self.lcdpos.y;
    }
    
    // pre-offset align is bottom-left. or translate effect2's modelviewmatrix in drawtime.
    int drawableheight = floor(self.bounds.size.height * self.contentScaleFactor);
    // 159x80 matrix
    GLfloat pixelx = 0 + Pixel.left, pixely = drawableheight - gap.lcd.height + Pixel.top;
    GLfloat w = fLCDPixel.w;
    for (int y = 0; y < 80 * fLCDPixel.w; y+= fLCDPixel.w) {
        for (int x = 0; x < 159 * fLCDPixel.h; x+= fLCDPixel.h) {
            addStripe6(pixelx + x, pixely + y, 0, texx, texy); // bl
            addStripe6(pixelx + x + w, pixely + y, 0, texx + texw, texy); // br
            addStripe6(pixelx + x, pixely + y + w, 0, texx, texy + texh); // tl
            addStripe6(pixelx + x + w, pixely + y + w, 0, texx + texw, texy + texh); // tr
        }
    }
    // 80 stripes
    pixelx = 0;
    pixely -= Pixel.top;
    for (int i = 79; i >= 0; i--) {
        GLfloat texx = double(fLCDStripes[i].texture.x) / self.textureInfo.width, texy = double(fLCDStripes[i].texture.y) / self.textureInfo.height;
        GLfloat texw = double(fLCDStripes[i].texture.w) / self.textureInfo.width, texh = double(fLCDStripes[i].texture.h) / self.textureInfo.height;
        int x = fLCDStripes[i].left, y = fLCDStripes[i].top;
        int w = fLCDStripes[i].texture.w, h = fLCDStripes[i].texture.h;
        addStripe6(pixelx + x, pixely + y, 0, texx, texy); // bl
        addStripe6(pixelx + x + w, pixely + y, 0, texx + texw, texy); // br
        addStripe6(pixelx + x, pixely + y + h, 0, texx, texy + texh); // tl
        addStripe6(pixelx + x + w, pixely + y + h, 0, texx + texw, texy + texh); // tr
    }
    // overlap
    if (0){
        GLfloat texx = double(fLCDEmpty.x) / self.textureInfo.width, texy = double(fLCDEmpty.y) / self.textureInfo.height;
        GLfloat texw = double(fLCDEmpty.w) / self.textureInfo.width, texh = double(fLCDEmpty.h) / self.textureInfo.height;
        int w = fLCDEmpty.w, h = fLCDEmpty.h;
        
        addStripe6(left, top, -0.5, texx, texy); // bl
        addStripe6(left + w, top, -0.5, texx + texw, texy); // br
        addStripe6(left, top + h, -0.5, texx, texy + texh); // tl
        addStripe6(left + w, top + h, -0.5, texx + texw, texy + texh); // tr
    }
    {
        left = 0;
        top = pixely = drawableheight - gap.lcd.height;
        GLfloat texx = double(fLCDEmpty.x) / self.textureInfo.width, texy = double(fLCDEmpty.y) / self.textureInfo.height;
        GLfloat texw = double(fLCDEmpty.w) / self.textureInfo.width, texh = double(fLCDEmpty.h) / self.textureInfo.height;
        int w = fLCDEmpty.w, h = fLCDEmpty.h;
        
        addStripe6(left, top, -0.5, texx, texy); // bl
        addStripe6(left + w, top, -0.5, texx + texw, texy); // br
        addStripe6(left, top + h, -0.5, texx, texy + texh); // tl
        addStripe6(left + w, top + h, -0.5, texx + texw, texy + texh); // tr
    }

    
    [self setupFrontPanel];
    //[self setupTwoRectangle];
    [self setupMiddleLayersWithWidth2:gap.lcd.width height:gap.lcd.height offset:fLCDPixel.w];
    
    glGenVertexArraysOES(1, &_stripeArray);
    glBindVertexArrayOES(_stripeArray);
    
    glGenBuffers(1, &_stripeBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _stripeBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(stripeData6), stripeData6, GL_STATIC_DRAW);
    assert(glGetError() == GL_NO_ERROR);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat5d), 0);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat5d), (void*)sizeof(GLfloat3d)); // fixed
    
    glBindVertexArrayOES(0);
    assert(glGetError() == GL_NO_ERROR);
}

- (void)setupTwoRectangle
{
    addStripe6(64, 64, 0, 0, 0); // bl
    addStripe6(128, 64, 0, 0.5, 0); // br
    addStripe6(64, 128, 0, 0, 0.5); // tl
    addStripe6(128, 128, 0, 0.5, 0.5); // tr
    
    addStripe6(164, 164, 0, 0.5, 0.5); // bl
    addStripe6(228, 164, 0, 1.0, 0.5); // br
    addStripe6(164, 228, 0, 0.5, 1); // tl
    addStripe6(228, 228, 0, 1, 1); // tr
}

- (void)setupMiddleLayersWithWidth:(int) width height:(int)height offset:(int)offset
{
    addStripe6(0, 0, 0,          0, 1); // bl
    addStripe6(width, 0, 0,      1, 1); // br
    addStripe6(0, height, 0,     0, 0); // tl
    addStripe6(width, height, 0, 1, 0); // tr
    
    addStripe6(offset, offset, 0, 0, 1); // bl
    addStripe6(width + offset, offset, 0, 1, 1); // br
    addStripe6(offset, height + offset, 0, 0, 0); // tl
    addStripe6(width + offset, height + offset, 0, 1, 0); // tr
}

- (void)setupMiddleLayersWithWidth2:(int) width height:(int)height offset:(int)offset
{
    CGFloat left = self.lcdpos.x;
    CGFloat top = self.lcdpos.y;
    addStripe6(left, top, 0,                  0, 1); // bl
    addStripe6(left + width, top, 0,          1, 1); // br
    addStripe6(left, top + height, 0,         0, 0); // tl
    addStripe6(left + width, top + height, 0, 1, 0); // tr
    
    left += offset;
    top += offset;
    
    addStripe6(left, top, 0,                  0, 1); // bl
    addStripe6(left + width, top, 0,          1, 1); // br
    addStripe6(left, top + height, 0,         0, 0); // tl
    addStripe6(left + width, top + height, 0, 1, 0); // tr
}

-(void)setupOverlay
{
    GLfloat texx = double(fLCDEmpty.x) / self.textureInfo.width, texy = double(fLCDEmpty.y) / self.textureInfo.height;
    GLfloat texw = double(fLCDEmpty.w) / self.textureInfo.width, texh = double(fLCDEmpty.h) / self.textureInfo.height;
}

-(void)setupFrontPanel
{
    addStripe6(0, 0, 0.5, 0, 0); // bl
    addStripe6(self.textureInfo3.width, 0.5, 0, 1, 0); // br
    addStripe6(0, self.textureInfo3.height, 0.5, 0, 1); // tl
    addStripe6(self.textureInfo3.width, self.textureInfo3.height, 0.5, 1, 1); // tr
}

extern bool lcdoffshift0flag;

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    if (!updated) {
        NSLog(@"drawInRect: drawable:%dx%d", (int)self.drawableWidth, (int)self.drawableHeight);
        if (self.drawableWidth == 0) {
            return;
        }
        
        GLKMatrix4 UIMatrix = GLKMatrix4MakeOrtho(0, self.drawableWidth, self.drawableHeight, 0, -1, 1);
        
        self.effect.transform.projectionMatrix = UIMatrix;
        self.effect.transform.modelviewMatrix = GLKMatrix4Identity;
        
        self.effect2.transform.projectionMatrix = UIMatrix;
        self.effect2.transform.modelviewMatrix = GLKMatrix4Identity;

        self.effect3.transform.projectionMatrix = UIMatrix;
        self.effect3.transform.modelviewMatrix = GLKMatrix4Identity;
        
        self.effect4.transform.projectionMatrix = UIMatrix;
        self.effect4.transform.modelviewMatrix = GLKMatrix4Identity;

        updated = true;
    }
    
    //glClearColor(0.0f, 0.0f, 0.0f, 1.0f); // black
    glClearColor(1.0, 0xfd / 255.0, 0xe8 / 256.0, 1.0f); // yellow (TODO: hair)
    //glClear(GL_COLOR_BUFFER_BIT);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    if (self->_lcdbuffer == 0 || self.textureInfo == 0) {
        return;
    }
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    glBindVertexArrayOES(_stripeArray);

    [self.effect2 prepareToDraw];
    // Draw overlap
    if (!lcdoffshift0flag) {
        //glDrawArrays(GL_TRIANGLE_STRIP, 160*80*4, 4);
    }

    _shadowtex->begin();
    //glDisable(GL_BLEND);
    //glClearColor(1, 0, 0, 0.8);
    //glClearColor(1, 1, 1, 0);
    glClearColor(1.0, 0xfd / 255.0, 0xe8 / 256.0, 0); // transparent yellow
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    [self.effect2 prepareToDraw];
    //if (!lcdoffshift0flag) {
    //    glDrawArrays(GL_TRIANGLE_STRIP, 160*80*4, 4);
    //}
    // Draw matrix
    TScreenBuffer* buffer = self->_lcdbuffer;
    int index = 0;
    int index4 = 0;
    for (int y = 0; y < 80; y++) {
        for (int i = 0; i < 160 / 8; i++) {
            const unsigned char pixel = buffer->fPixel[index];
            // try to shrink jump cost
            if (pixel) {
                // col0 is stripe?
                if (i) {
                    if (pixel & 0x80u) {
                        glDrawArrays(GL_TRIANGLE_STRIP, index4, 4);
                    }
                    index4 += 4;
                }
                if (pixel & 0x40) {
                    glDrawArrays(GL_TRIANGLE_STRIP, index4, 4);
                }
                if (pixel & 0x20) {
                    glDrawArrays(GL_TRIANGLE_STRIP, index4 + 4, 4);
                }
                if (pixel & 0x10) {
                    glDrawArrays(GL_TRIANGLE_STRIP, index4 + 8, 4);
                }
                if (pixel & 0x08) {
                    glDrawArrays(GL_TRIANGLE_STRIP, index4 + 12, 4);
                }
                if (pixel & 0x04) {
                    glDrawArrays(GL_TRIANGLE_STRIP, index4 + 16, 4);
                }
                if (pixel & 0x02) {
                    glDrawArrays(GL_TRIANGLE_STRIP, index4 + 20, 4);
                }
                if (pixel & 0x01) {
                    glDrawArrays(GL_TRIANGLE_STRIP, index4 + 24, 4);
                }
                index4 += 28;
            } else {
                index4 += i?32:28;
            }
            //index4 += pixel?28:28;
            index++;
        }
    }
    
    // Draw stripes
    index4 = 159 * 80 * 4;
    for (int y = 79; y >= 0; y--) {
        char pixel = buffer->fPixel[(160/8) * y];
        if ((pixel < 0)) {
            glDrawArrays(GL_TRIANGLE_STRIP, index4, 4);
        }
        index4 += 4;
    }
    if (!lcdoffshift0flag) {
        glDrawArrays(GL_TRIANGLE_STRIP, 160*80*4, 4);
    }
    
    _shadowtex->end();

    glBlendFunc(GL_CONSTANT_ALPHA, GL_ONE_MINUS_CONSTANT_ALPHA);
    glBlendColor(1.0, 0xfd / 255.0, 0xe8 / 256.0, 0.2);
    [self.effect4 prepareToDraw];
    glDrawArrays(GL_TRIANGLE_STRIP, 160*80*4 + 12, 4); // shadow

    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    /*[self.effect2 prepareToDraw];
    // Draw overlap
    if (!lcdoffshift0flag) {
        glDrawArrays(GL_TRIANGLE_STRIP, 160*80*4, 4);
    }*/
    // workaroud for overlap alpha bug in shadowtex
    if (!lcdoffshift0flag) {
        // identity is bottom-left aligned
        self.effect2.transform.modelviewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, self.lcdpos.x, fLCDEmpty.h + self.lcdpos.y - self.drawableHeight, 0);
        [self.effect2 prepareToDraw];
        glDrawArrays(GL_TRIANGLE_STRIP, 160*80*4, 4);
        self.effect2.transform.modelviewMatrix = GLKMatrix4Identity;
    }
    [self.effect4 prepareToDraw];
    //glBlendFunc(GL_SRC_ALPHA, GL_BLEND_COLOR);
    glDrawArrays(GL_TRIANGLE_STRIP, 160*80*4 + 8, 4); // fixed

    // front panel?
    [self.effect3 prepareToDraw];
    glDrawArrays(GL_TRIANGLE_STRIP, 160*80*4 + 4, 4);
    
    glDisable(GL_BLEND);
    glBindVertexArrayOES(0);
}


@end
