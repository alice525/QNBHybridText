//
//  QLContentItem.h
//  live4iphone
//
//  Created by deron on 14-6-5.
//  Copyright (c) 2014年 Tencent Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#pragma mark -
#pragma mark 内容分段信息

/**
 * feed内容单元元素类型
 */
typedef enum
{
    QL_CONTENT_ITEM_TYPE_TEXT = 1,     // 纯文本 (对应GAContentItem text 字段)
    QL_CONTENT_ITEM_TYPE_USER = 2,     // 用户   (对应GAContentItem uin 和 nick 字段)
    QL_CONTENT_ITEM_TYPE_AT_USER = 3,  // @用户  (对应GAContentItem uin 和 nick 字段)
    QL_CONTENT_ITEM_TYPE_EM = 4,       // 表情   (对应GAContentItem text 字段，表情格式为 eXXX （XXX 对应srver 下标）)
    QL_CONTENT_ITEM_TYPE_URL = 5,      // 链接   (对应GAContentItem text 和 url 字段）
    QL_CONTENT_ITEM_TYPE_NEW_LINE = 6, // 换行
} QLContentItemType;

@interface QLContentItem : NSObject<NSCopying,NSCoding>
{
@private
    QLContentItemType           _contentType;
    NSString*                   _text;
    NSString*                   _url;
    NSString*                   _vuserid;
    
    //下面两个为可选函数。如果设置了颜色和字体，排版的时候会优先读取这两个值。
    //_contentType 为QL_CONTENT_ITEM_TYPE_TEXT 时候生效
    UIColor*                    _textColor;
}
@property(nonatomic, assign)QLContentItemType   contentType;
@property(nonatomic, retain)NSString*               text;
@property(nonatomic, retain)NSString*               url;
@property(nonatomic, retain)NSString*               vuserid;
@property(nonatomic, retain)NSString*               nick;
@property(nonatomic, retain)UIColor*                textColor;
@property(nonatomic, assign)BOOL                    isAppStoreLink;
@property(nonatomic, retain)NSString*               postParam;
@end
