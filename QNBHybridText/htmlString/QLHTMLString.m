//
//  QLHTMLString.m
//  richLabel-project
//
//  Created by alice on 14-10-20.
//  Copyright (c) 2014年 alicejhchen. All rights reserved.
//

#import "QLHTMLString.h"

@implementation QLHTMLString

+ (NSString *)urlHTML:(NSString*)url
{
    if (![url isKindOfClass:[NSString class]] || 0 == [url length]) {
        return @"";
    }
    NSString *htmlString = [NSString stringWithFormat:@"<a href=%@><font color=#1c65a9>%@</font></a>", url, url];
    return htmlString;
}

+ (NSString *)nicknameHTML:(NSString *)nickname index:(NSInteger)index
{
    if (![nickname isKindOfClass:[NSString class]] || 0 == [nickname length]) {
        return @"";
    }
    NSString *htmlString = nil;
  
    if (0 <= index) {
        htmlString = [NSString stringWithFormat:@"<a href=%d><font color=#1c65a9>%@</font></a>", (int)index, nickname];
    } else {
        htmlString = [NSString stringWithFormat:@"<font color=#1c65a9>%@</font>", nickname];
    }
    return htmlString;
}

+ (NSString *)imageHTML:(NSString *)imgName index:(NSInteger)index
{
    if (![imgName isKindOfClass:[NSString class]] || 0 == [imgName length]) {
        return @"";
    }
    unichar objReplaceChar = 0xFFFC;
    NSString *replaceString = [NSString stringWithCharacters:&objReplaceChar length:1];
    NSString *htmlString = nil;
    
    // 将表情用" "替换，在计算文本高度时以空格计算，所以排版会出问题，使用OxFFFC替换就OK了， alicejhchen (20140617)
    if (0 <= index) {
        htmlString = [NSString stringWithFormat:@"<a href=%d><img src=%@>%@</a>", (int)index, imgName, replaceString];
    } else {
        htmlString = [NSString stringWithFormat:@"<img src=%@>%@</img>", imgName, replaceString];
    }
    return htmlString;
}

+ (NSString *)imageHTML:(NSString *)imgName index:(NSInteger)index size:(CGSize)size
{
    if (![imgName isKindOfClass:[NSString class]] || 0 == [imgName length]) {
        return @"";
    }
    unichar objReplaceChar = 0xFFFC;
    NSString *replaceString = [NSString stringWithCharacters:&objReplaceChar length:1];
    NSString *htmlString = nil;
    
    // 将表情用" "替换，在计算文本高度时以空格计算，所以排版会出问题，使用OxFFFC替换就OK了， alicejhchen (20140617)
    if (0 <= index) {
        htmlString = [NSString stringWithFormat:@"<a href=%d><img src=%@ height=%f width=%f>%@</a>", (int)index, imgName, size.height,size.width, replaceString];
    } else {
        htmlString = [NSString stringWithFormat:@"<img src=%@ height=%f width=%f>%@</img>", imgName , size.height, size.width, replaceString];
    }
    return htmlString;
}

+ (NSString *)characterHTML:(NSString *)charString
{
    if (![charString isKindOfClass:[NSString class]] || 0 == [charString length]) {
        return @"";
    }
    NSString *htmlString = [NSString stringWithFormat:@"<font size=15 face=Helvetica color=#323233>%@</font>", charString];
    return htmlString;
}

// 非图片类文本不需要添加Html标签， alicejhchen (20140624)
+ (NSString *)plainContentHTML:(NSString *)content
{
    if (![content isKindOfClass:[NSString class]] || 0 == [content length]) {
        return @"";
    }
    return content;
}

@end
