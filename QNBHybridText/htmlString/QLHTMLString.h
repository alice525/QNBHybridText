//
//  QLHTMLString.h
//  richLabel-project
//
//  Created by alice on 14-10-20.
//  Copyright (c) 2014年 alicejhchen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface QLHTMLString : NSObject

/* 将特定的字符串转换成带Html标签的字符串，可根据项目需求做更改
 */

+ (NSString *)nicknameHTML:(NSString *)nickname index:(NSInteger)index;

+ (NSString *)imageHTML:(NSString *)imgName index:(NSInteger)index;

+ (NSString *)imageHTML:(NSString *)imgName index:(NSInteger)index size:(CGSize)size;

+ (NSString *)characterHTML:(NSString *)charString;

+ (NSString *)plainContentHTML:(NSString *)content;

/**
	处理url的连接
	@param url url
	@returns rich string
 */
+ (NSString *)urlHTML:(NSString*)url;

@end
