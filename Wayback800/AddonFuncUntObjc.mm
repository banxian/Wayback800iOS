//
//  AddonFuncUntObjc.mm
//  MViewLite
//
//  Created by banxian on 7/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#include "AddonFuncUnt.h"
#include "AddonFuncUntObjc.h"
#include <TargetConditionals.h>
#include <mach/mach_time.h>


std::wstring StringToWideString(const std::string& Source, unsigned int Codepage)
{
    std::wstring Result;
    
    if (Source.size() > 0) {
        NSString* dummy = [[NSString alloc] initWithBytes:(const void *)Source.c_str() length:Source.size() encoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSJapanese)];
        const wchar_t* unicode = (const wchar_t*)[dummy cStringUsingEncoding:NSUTF32LittleEndianStringEncoding];
        int unicodelen = wcslen(unicode);
        Result.resize(unicodelen);
        memcpy(&Result[0], unicode, unicodelen * sizeof(std::wstring::size_type));
        dummy = nil;
    }
    
    return Result;
}

std::wstring UTF82WideString( const std::string& source )
{
    std::wstring Result;
    
    if (source.size() > 0) {
        NSString* dummy = [[NSString alloc] initWithBytes:(const void *)source.c_str() length:source.size() encoding:NSUTF8StringEncoding];
        const wchar_t* unicode = (const wchar_t*)[dummy cStringUsingEncoding:NSUTF32LittleEndianStringEncoding];
        int unicodelen = wcslen(unicode);
        Result.resize(unicodelen);
        memcpy(&Result[0], unicode, unicodelen * sizeof(std::wstring::size_type));
        dummy = nil;
    }
    
    return Result;
}

std::string WideString2UTF8( const std::wstring& source )
{
    std::string Result;
    if (source.size() > 0) {
        NSString* dummy = [[NSString alloc] initWithBytes:(const void *)source.c_str() length:(source.size() * sizeof(std::wstring::size_type)) encoding:NSUTF32LittleEndianStringEncoding];
        const char* utf8 = [dummy UTF8String];
        int utf8len = strlen(utf8);
        Result.resize(utf8len);
        memcpy(&Result[0], utf8, utf8len);
        dummy = nil;
    }
    
    return Result;
}

NSString* WideString2NSString( const std::wstring& source )
{
    NSString* Result = [[NSString alloc] initWithBytes:(const void *)source.c_str() length:(source.size() * sizeof(std::wstring::size_type)) encoding:NSUTF32LittleEndianStringEncoding];
    return Result;
}

std::wstring NSString2WideString(const NSString* source)
{
    NSStringEncoding pEncode = CFStringConvertEncodingToNSStringEncoding ( kCFStringEncodingUTF32LE );    
    NSData* pSData = [ source dataUsingEncoding : pEncode ];     
    
    return std::wstring ( (wchar_t*) [ pSData bytes ], [ pSData length] / sizeof ( wchar_t ) );    
}

#if TARGET_OS_IPHONE
mach_timebase_info_data_t base;
unsigned int GetTickCount()
{
    //return (unsigned int)-1;
    if (base.numer == 0) {
        mach_timebase_info(&base);
    }
    uint64_t now = mach_absolute_time();
    return (now * base.numer / base.denom) / 1000000;
}
#else
unsigned int GetTickCount()
{
    //double curr = (double)(CFAbsoluteTimeGetCurrent()) * 1000.0;
    //return (unsigned int)curr;
    return CFAbsoluteTimeGetCurrent() * 1000;
}
#endif

std::string GetResourcePath()
{
    NSString* bundlePath = [[NSBundle mainBundle] resourcePath];
    if (bundlePath) {
        return [bundlePath UTF8String];
    } else {
        return "";
    }
}

std::string GetDocumentsPath()
{
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [searchPaths objectAtIndex:0];
    if (documentPath) {
        return [documentPath UTF8String];
    } else {
        return "";
    }
    
}
