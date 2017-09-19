//
//  Utils.h
//  live4iphone
//
//  Created by ISD ClientDev on 11-5-6.
//  Copyright 2011 tencent.com. All rights reserved.
//


#define kSCNavigationBarBackgroundImageTag 200001
#define kSCNavigationBarTransparentButtonTag 200002

#define LOAD_EMOJI_IMAGE(imageName) [Utils emojiImageForName:imageName]

#import <objc/runtime.h>
#import <UIKit/UIKit.h>

@class QLRecentPlayItem;
@class QLPayBill;

@interface Utils : NSObject

+ (BOOL)isIOS8OrLatter;
+ (BOOL)isIOS7OrLatter;
// 是否 ios5 以前系统
+ (BOOL)isIOS5OrEarlier;
// 是否IOS6以后的系统
+ (BOOL)isIOS6OrLatter;

+ (UIImage *) emojiImageForName:(NSString *)name;

@end
