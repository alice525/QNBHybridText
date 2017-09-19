//
//  QLTextParser.h
//  live4iphone
//
//  Created by deron on 14-6-5.
//  Copyright (c) 2014年 Tencent Inc. All rights reserved.
//
//  moment里面文字的解析，可以解析表情、超链接、@名字 等
//
//  指定特定格式，即可以从文本中一块解出来，供外部使用

#import <Foundation/Foundation.h>

/////////////////////////////////////////////
// 从一串文本中解出的Node信息，以此再进一步的处理
typedef enum {
	TNT_Normal = 0,		// 普通文本
	TNT_Emotion,		// 表情
	TNT_Url,			// url
	TNT_At,				// @名字
	TNT_Nickname,		// 名字
    TNT_NewLine,         // 换行
    TNT_QQEmotion,
} QLTextNodeType;

@interface QLTextParser : NSObject

// 把所有的标签块及普通文本块都解析出来,存在数组中(存的QLMomentContentItem)，供别处使用
+(NSMutableArray*) parseText:(NSString*)str;

+(NSString*)UBBStringFromNormalString:(NSString*)origin;
@end
