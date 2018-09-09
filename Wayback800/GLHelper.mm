//
//  GLHelper.m
//  Wayback800
//
//  Created by Banxian on 7/21/18.
//  Copyright © 2018 banxian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import<objc/runtime.h>
#import<objc/message.h>
#import "GLHelper.h"

@interface NSObject (_UIAssetManager)
- (id) initWithName:(NSString *)name inBundle:(NSBundle *)bundle idiom:(UIUserInterfaceIdiom)idiom;
- (float) scale;
- (NSUInteger) subtype;
- (NSInteger) idiom;
@end

@interface CUINamedImage: NSObject
- (CGImage*) image;
@end

@interface NSObject (CUICatalog)
- (id) imageWithName:(NSString *)name scaleFactor:(float)scale deviceIdiom:(NSInteger)idiom deviceSubtype:(NSUInteger)subtype;
@end

void testUIAssetManager()
{
    Class cls = NSClassFromString(@"_UIAssetManager");
    Ivar ivar = class_getInstanceVariable([cls class], "_catalog");
    ptrdiff_t offset = ivar_getOffset(ivar);
    NSLog(@"offset: %ld", offset);
    id assetmgr = [[cls alloc] initWithName:@"Assets" inBundle:[NSBundle mainBundle] idiom:[[UIDevice currentDevice] userInterfaceIdiom]];
    NSLog(@"assetmgr: %@", assetmgr);
    NSArray *allRenditionNames = [assetmgr valueForKeyPath:@"catalog.themeStore.store.allRenditionNames"];
    for (NSString *renditionName in allRenditionNames) {
        NSLog(@"renditionName: %@", renditionName);
    }
    //"imageWithName:scaleFactor:deviceIdiom:deviceSubtype:"
    //UIUserInterfaceIdiom idiom = (UIUserInterfaceIdiom)[assetmgr idiom];//[[UIDevice currentDevice] userInterfaceIdiom];
    //int deviceidiom = 2;
    //if ( idiom != 1 )
    //    deviceidiom = idiom == 0;
    
    void* catalog = *(uintptr_t**)(((char*)(__bridge void*)assetmgr) + offset);
#if OBJC_OLD_DISPATCH_PROTOTYPES
    //objc_msgSend((__bridge id)(catalog), @selector(clearCachedImageResources));
#else
    //((id (*)(id, SEL))objc_msgSend)((__bridge id)(catalog), @selector(clearCachedImageResources));
#endif
    ivar = class_getInstanceVariable([cls class], "_preferredIdiomSubtype");
    offset = ivar_getOffset(ivar);
    NSLog(@"offset: %ld", offset);
    NSUInteger subtype = *(NSUInteger*)(((char*)(__bridge void*)assetmgr) + offset);
    ivar = class_getInstanceVariable([cls class], "_preferredIdiom");
    offset = ivar_getOffset(ivar);
    NSLog(@"offset: %ld", offset);
    NSInteger idiom = *(NSInteger*)(((char*)(__bridge void*)assetmgr) + offset);
    ivar = class_getInstanceVariable([cls class], "_preferredScale");
    offset = ivar_getOffset(ivar);
    NSLog(@"offset: %ld", offset);
    float scale = *(float*)(((char*)(__bridge void*)assetmgr) + offset);
    int deviceidiom = 2;
    if ( idiom != 1 )
        deviceidiom = idiom == 0;
    
    //float scale = ((float (*)(id, SEL))objc_msgSend)(assetmgr, @selector(scale));
    //NSUInteger subtype = ((NSUInteger (*)(id, SEL))objc_msgSend)(assetmgr, @selector(subtype));
    NSLog(@"catelog: %@", (__bridge id)catalog);
    //id img = [(__bridge id)catalog imageWithName:@"frontpanel" scaleFactor:3.0 deviceIdiom:deviceidiom deviceSubtype:570];
    id img = [(__bridge id)catalog imageWithName:@"frontpanel" scaleFactor:scale deviceIdiom:deviceidiom deviceSubtype:subtype];
    //CUINamedImage
    NSLog(@"namedimage: %@", img);
}

CGImage* tryLoadImageFromAssetsWoCache(NSString* name)
{
    Class cls = NSClassFromString(@"_UIAssetManager");
    Ivar ivar = class_getInstanceVariable([cls class], "_catalog");
    ptrdiff_t offset = ivar_getOffset(ivar);
    id assetmgr = [[cls alloc] initWithName:@"Assets" inBundle:[NSBundle mainBundle] idiom:[[UIDevice currentDevice] userInterfaceIdiom]];
    
    void* catalog = *(uintptr_t**)(((char*)(__bridge void*)assetmgr) + offset);

    ivar = class_getInstanceVariable([cls class], "_preferredIdiomSubtype");
    offset = ivar_getOffset(ivar);
    //NSLog(@"offset: %ld", offset);
    NSUInteger subtype = *(NSUInteger*)(((char*)(__bridge void*)assetmgr) + offset);
    ivar = class_getInstanceVariable([cls class], "_preferredIdiom");
    offset = ivar_getOffset(ivar);
    //NSLog(@"offset: %ld", offset);
    NSInteger idiom = *(NSInteger*)(((char*)(__bridge void*)assetmgr) + offset);
    ivar = class_getInstanceVariable([cls class], "_preferredScale");
    offset = ivar_getOffset(ivar);
    //NSLog(@"offset: %ld", offset);
    float scale = *(float*)(((char*)(__bridge void*)assetmgr) + offset);
    int deviceidiom = 2;
    if ( idiom != 1 )
        deviceidiom = idiom == 0;
    
    //NSLog(@"catelog: %@", (__bridge id)catalog);
    CUINamedImage* img = [(__bridge id)catalog imageWithName:name scaleFactor:scale deviceIdiom:deviceidiom deviceSubtype:subtype];
    //CUINamedImage
    //NSLog(@"namedimage: %@", img);
    return (CGImage*)[img image];
}
