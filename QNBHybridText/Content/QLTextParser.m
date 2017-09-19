//
//  QLTextParser.m
//  live4iphone
//
//  Created by deron on 14-6-5.
//  Copyright (c) 2014年 Tencent Inc. All rights reserved.
//

#import "QLTextParser.h"
#import "RegexKitLite.h"
#import "QLContentItem.h"
#import "QLEmotionMap.h"

/////////////////////////////////////////////
//#define REGEX_EM @"(\\[em\\]e[0-9]+?\\[/em\\])"	// 表情
//#define REGEX_EM @"(\\[.*?\\])"	// 表情
#define REGEX_EM @"(\\[.{1,3}\\])"	// 表情

#define REGEX_AT @"(@?[{]uin:[0-9]+?,nick:.*?[}])"   // @名字
#define REGEX_AT1 @"(@?[{]uin:.*?,nick:.*?,who:[0-9]+?[}])"     // 微博及朋友的@名字
#define REGEX_USER @"([<]uin:[0-9]+?,nick:.*?[>])"
#define REGEX_LINK @"([<{]url:.*?,text:.*?[>}])" // Link对象(超链接) <>为内部拼的，{}为服务器下发的
#define REGEX_URL @"[a-zA-z]+:\\/\\/[^\\s\u4e00-\u9fa5]+"
//#define URL_NORMAL_EXPRESSION    @"((http(s)?://)(([-A-Za-z0-9_]+(\\.[-A-Za-z0-9_]+)*(\\.[-A-Za-z]{2,5}))|([0-9]{1,3}(\\.[0-9]{1,3}){3}))(:[0-9]*)?(/[-A-Za-z0-9_\\$\\.\\+\\!*()<>{},;:@&=?/~#%'`]*)*)"
//@"((http|ftp|https):\\/\\/[\\w\\-_]+(\\.[\\w\\-_]+)+([\\w\\-\\.,@?^=%&amp;:/~\\+#]*[\\w\\-\\@?^=%&amp;/~\\+#])?)"

#define URL_NORMAL_EXPRESSION    @"((http(s)?://url\\.cn/)([-A-Za-z0-9_\\$\\.\\+\\!*()<>{},;:@&=?/~#%'`]*)*)"

static NSString* const QZONE_REGEXSTR =@"(\\[[\u4e00-\u9fa5A-Za-z]{1,3}\\])";

@implementation QLTextParser

+(QLTextNodeType) getCurrentType:(NSString*)str Postion:(NSRange)range
{
	// MQZ_ASSERT(range.location != NSNotFound);
    
	unichar c = [str characterAtIndex:range.location];
	if (c == '[')
		return TNT_Emotion;
    else if(c == '/')
        return TNT_QQEmotion;
	else if (c == '@' || c == '{') {
        if (range.length < 3) {
            return TNT_At;
        }
        unichar c2 = [str characterAtIndex:range.location+2];
        if (c2 == 'r') {
            return TNT_Url;     // {url:...,text:...}
        }
        else {
            return TNT_At;
        }
    }
	else if (c == '<') {
        if (range.length < 3) {
            return TNT_Nickname;
        }
        unichar c2 = [str characterAtIndex:range.location+2];
        if (c2 == 'r') {
            return TNT_Url;     // <url:...,link:...>
        }
        else {
            return TNT_Nickname;
        }
    }
	else
		return TNT_Url;
}

// 对文本内容进行一下特殊处理 (对里面的\n分割一下)
+ (void)processNormalText:(NSString*)str range:(NSRange)range list:(NSMutableArray*)list
{
    NSRange normalTextRange = range;
    NSRange nlRange = NSMakeRange(NSNotFound,0);    // new line character range
    NSUInteger strIndex = range.location + range.length;
    
    while (TRUE) {
        // mod by batiliu =>
        //      nlRange = [str rangeOfString:@"\n" options:0 range:range];
        /*
        nlRange = [str rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]
                                       options:0
                                         range:range];
         */
        // mod by batiliu <=
        
        if (nlRange.location == NSNotFound) {
            [self addList:list captureStr:[str substringWithRange:range] Type:TNT_Normal];
            break;
        } else {
            NSRange tRange = NSMakeRange(range.location, nlRange.location - range.location);
            // mod by batiliu =>
            if (tRange.length > 0) {
                // the first character is new line character
                // mod by batiliu
                [self addList:list captureStr:[str substringWithRange:tRange] Type:TNT_Normal];
            }
            // mod by batiliu <=
            [self addList:list captureStr:[str substringWithRange:nlRange] Type:TNT_NewLine];
            
            NSUInteger nLocation = nlRange.location + nlRange.length;
            if (normalTextRange.length + normalTextRange.location > nLocation) {
                range = NSMakeRange(nLocation, strIndex - nLocation);
            } else {
                break;
            }
        }
    }
}

+(NSMutableArray*) parseText:(NSString*)str
{
    NSString* regex = [NSString stringWithFormat:@"%@|%@",QZONE_REGEXSTR,URL_NORMAL_EXPRESSION];
    return [self parseText:str regex:regex];
}

// 用正则式一次遍历过去，把所有的标签块及普通文本块都标注出来
/**
 * 目前的思路是从里面搜到标签串(表情/@/url)之后，放到一个单独的文本块中，其余的都是普通文字，也单独放到文本块中
 * 用(.*?)(?:myregex)也可以把所有的找出来，按块分开，但需要遍历4次文本，效率可能比较低
 * (因为目前regexkitlite提供的接口不支持返回group的range，并且不知道是匹配的哪一个group)
 * 目前返回range也不清楚是哪一个格式串的，所以判断它前面的第一个字符，可以知道是什么串，这样一次遍历string就可以把所有的都处理好
 */
+(NSMutableArray*) parseText:(NSString*)str regex:(NSString*)regex
{
    //\r\n会被解成两个回车，这边统一过滤下 2013.9.16 timm
    str = [str stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
    
	NSMutableArray *nodeList = [[NSMutableArray alloc] init];
    
    /*
     // 增加<uin:,nick:>表示昵称，同@类似，但是没有@符号，用来处理点击昵称后跳空间主页
     NSString *regex = @"(\\[em\\]e[0-9]+?\\[/em\\])|"								// 表情
     @"(@?[{]uin:[0-9]+?,nick:.*?[}])|"                                              // @名字
     @"(@?[{]uin:.*?,nick:.*?,who:[0-9]+?[}])|"     // 微博及朋友的@名字
     @"([<]uin:[0-9]+?,nick:.*?[>])|"
     @"([<{]url:.*?,text:.*?[>}])|"             // Link对象(超链接) <>为内部拼的，{}为服务器下发的
     @"((?:(?i)https?://|www\\.)[a-zA-Z0-9\\-.]+(?::(\\d+))?(?:(?:/[a-zA-Z0-9\\-._?,'+\\&%$=~*!;#():@\\\\]*)+)?)";	// url链接*/
	
    //    NSString* regex = [NSString stringWithFormat:@"%@|%@|%@|%@|%@",REGEX_AT,REGEX_AT1,REGEX_EM,REGEX_LINK,REGEX_USER];
    
    
	NSRange searchRange = {0, str.length};
	NSRange lastMatchedRange = {0, 0};		// 上一次匹配的内容
	
    //NSString *strLower = [str lowercaseString];
	while (searchRange.location < str.length) {
		NSRange matchedRange = [str rangeOfRegex:regex inRange:searchRange];
        
		// 中间是否有普通文本，如果就有添加到list中
		if (matchedRange.location > lastMatchedRange.location+lastMatchedRange.length) {
			NSRange normalRange = {0, 0};
			normalRange.location = lastMatchedRange.location+lastMatchedRange.length;
			if (matchedRange.location == NSNotFound) {	// 没有找到了，之前的都放到普通文本块中
				normalRange.length = str.length-normalRange.location;
                [self processNormalText:str range:normalRange list:nodeList];
                // [self addList:nodeList NodeRange:normalRange Type:TNT_Normal];
				break;
			}
			else {	// A-B之间的普通文本块
				normalRange.length = matchedRange.location-normalRange.location;
                [self processNormalText:str range:normalRange list:nodeList];
                // [self addList:nodeList NodeRange:normalRange Type:TNT_Normal];
			}
		}
		
		[self addList:nodeList captureStr:[str substringWithRange:matchedRange] Type:[self getCurrentType:str Postion:matchedRange]];
        // 添加标签块
		
		lastMatchedRange = matchedRange;
		// 将searchRange移至下一个有效区域
		searchRange.location = matchedRange.location+matchedRange.length;
		searchRange.length = str.length - searchRange.location;
	}
	
	return [nodeList autorelease];
}

+(void) addList:(NSMutableArray*)list captureStr:(NSString*)cap Type:(QLTextNodeType)type
{
    //    QZONE_LOG_COMMON("captureStr=%s",[cap UTF8String]);
    
	QLContentItem* item = [[[QLContentItem alloc]init]autorelease];
    
    switch (type) {
        case TNT_Url:
        {
            item.contentType = QL_CONTENT_ITEM_TYPE_URL;
            item.text = cap;
        }
            break;
        case TNT_Normal:		// 普通文本
        {
            item.contentType = QL_CONTENT_ITEM_TYPE_TEXT;
            item.text = cap;
            
        }
            break;
        case TNT_Emotion:		// 表情 [微笑]
        {
            NSInteger localIndex = [[QLEmotionMap intance] emotionLocalIndexFromEmotionString:cap];
            if (localIndex == -1) {
                //没找到对应的表情符号
                item.contentType = QL_CONTENT_ITEM_TYPE_TEXT;
                item.text = cap;
            }else {
                item.contentType = QL_CONTENT_ITEM_TYPE_EM;
                item.text = [NSString stringWithFormat:@"%ld",(long)localIndex];
            }
            
        }
            break;
        case TNT_QQEmotion: //QQ表情 /微笑
        {
            NSInteger localIndex = [[QLEmotionMap intance] emotionQQLocalIndexFromEmotionString:cap];
            if (localIndex == -1) {
                //没找到对应的表情符号
                NSInteger secondeLocalIndex = [[QLEmotionMap intance] emotionQQLocalIndexFromEmotionMatchEnString:cap];
                if (secondeLocalIndex == -1) {
                    item.contentType = QL_CONTENT_ITEM_TYPE_TEXT;
                    item.text = cap;
                }else {
                    item.contentType = QL_CONTENT_ITEM_TYPE_EM;
                    item.text = cap;
                }
            }else {
                item.contentType = QL_CONTENT_ITEM_TYPE_EM;
                item.text = cap;
            }
        }
            break;
        default:
        {
            return;
        }
    }
    
    //   QZONE_LOG_COMMON("item=%s",[[item description] UTF8String]);
    
    [list addObject:item]; 
}

+(NSString*)UBBStringFromNormalString:(NSString*)origin
{
    NSString* regex = [[QLEmotionMap intance] getEmotionRexString];
    
    NSString *result = @"";
    
    NSArray *nodeList = nil;
    
    nodeList = [QLTextParser parseText:origin regex:regex];
    for (QLContentItem *contentItem in nodeList) {
        if (contentItem.contentType == QL_CONTENT_ITEM_TYPE_EM) {
            NSInteger serverIndex = [[QLEmotionMap intance] emotionQQLocalIndexFromEmotionString:contentItem.text];
            if (-1 == serverIndex)
            {
                NSInteger secondeIndex = [[QLEmotionMap intance] emotionQQLocalIndexFromEmotionMatchEnString:contentItem.text];
                if (secondeIndex == -1) {
                    // 无法解析表情，当成普通文本
                    result = [result stringByAppendingString:contentItem.text];
                }else {
                    NSString* name = [[QLEmotionMap intance] emotionStringFromLocalIndex:secondeIndex];
                    
                    result = [result stringByAppendingString:name];
                }

            }
            else
            {
                NSString* name = [[QLEmotionMap intance] emotionStringFromLocalIndex:serverIndex];
                
                result = [result stringByAppendingString:name];
            }

        }else if(contentItem.contentType == QL_CONTENT_ITEM_TYPE_TEXT){
            result = [result stringByAppendingString:contentItem.text];
        }
    }
    return result;
}
@end
