//
//  main.m
//  Sim800
//
//  Created by banxian on 12/30/12.
//  Copyright (c) 2012 banxian. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AppDelegate.h"

#include <QtCore/QtPlugin>

Q_IMPORT_PLUGIN(UIKitLite)

int main(int argc, char *argv[])
{
    // Set current directory to app bundle folder
    chdir( [[[NSBundle mainBundle] bundlePath] UTF8String] );
    
    // Set default platform plugin
    setenv("QT_QPA_PLATFORM","uikitlite",1);
    
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
