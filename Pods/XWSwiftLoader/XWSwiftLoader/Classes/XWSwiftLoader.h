//
//  XWSwiftLoader.h
//  XWSwiftLoader_Example
//
//  Created by xiewei on 2021/12/31.
//  Copyright © 2021 xiewei. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for XWSwiftLoader.
FOUNDATION_EXPORT double XWSwiftLoaderVersionNumber;

//! Project version string for XWSwiftLoader.
FOUNDATION_EXPORT const unsigned char XWSwiftLoaderVersionString[];


@protocol XWSwiftLoaderProtocol <NSObject>
@optional
+ (void)xw_Load;
+ (void)xw_Initialize;
@end

#define XW_SWIFT_LOADER(className) \
@interface className(swizzle_swifty_hook)\
@end\
\
@implementation className(swizzle_swifty_hook)\
+ (void)load {if ([[self class] respondsToSelector:@selector(xw_Load)]) {[[self class] xw_Load];}}\
+ (void)initialize {if ([[self class] respondsToSelector:@selector(xw_Initialize)]) {[[self class] xw_Initialize];}}\
@end
