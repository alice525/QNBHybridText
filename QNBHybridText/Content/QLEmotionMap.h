//
//  QLEmotionMap.h
//  live4iphone
//
//  Created by deron on 14-6-6.
//  Copyright (c) 2014年 Tencent Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define TOTAL_IOS_COUNT (60)
#define TOTAL_QQ_COUNT (100) // the total face count
#define TOTAL_SYMBOL_COUNT (72) // the total face count

#pragma mark- Class EMojiInfo
@interface EMojiInfo:NSObject
{
    NSString* _emj;
    NSString* _imageName;
    NSString* _codeID;
    NSUInteger _index;
}

@property (nonatomic,retain) NSString* emj;
@property (nonatomic,retain) NSString* imageName;
@property (nonatomic,retain) NSString* codeID;
@property (nonatomic,assign) NSUInteger index;
@end



extern const NSString* emoji_unicode6_table[];

@interface QLEmotionMap : NSObject
{
    NSMutableArray  *_emotionLocalIndexArray;
    NSMutableArray  *_emotionStringArray;
    NSMutableArray  *_QQemotionStringArray;
    NSMutableArray  *_QQemotionEnStringArray;
    NSMutableArray  *_QQemotionEnMatchStringArray;
    NSMutableArray  *_emojiArray;
    NSMutableArray  *_symbolArray;
}

+ (QLEmotionMap*)intance;


/*localIndex转换成string*/
- (NSString*)emotionStringFromLocalIndex:(NSInteger)localIndex;
- (NSString*)emotionQQStringFromLocalIndex:(NSInteger)localIndex;
- (NSString*)emotionQQEnStringFromLocalIndex:(NSInteger)localIndex;

/*string转换成serverIndex*/
- (NSInteger)emotionLocalIndexFromEmotionString:(NSString*)emotionString;
- (NSInteger)emotionQQLocalIndexFromEmotionString:(NSString*)emotionString;
- (NSInteger)emotionQQLocalIndexFromEmotionEnString:(NSString*)emotionString;
- (NSInteger)emotionQQLocalIndexFromEmotionMatchEnString:(NSString*)emotionString;

/*localIndex转换出文件名称*/
- (NSString*)emotionNameFromLocalIndex:(NSInteger)localIndex;
/*返回QQ表情字段数组*/
- (NSArray *)getEmojiArray;
/*返回IOS表情字段数组*/
- (NSArray *)getEmotionStringArray;
- (NSString*)getEmotionRexString;
/*返回符号表情字段数组*/
- (NSArray *)getSymBolArray;
@end
