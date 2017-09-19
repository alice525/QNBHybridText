//
//  QLContentItem.m
//  live4iphone
//
//  Created by deron on 14-6-5.
//  Copyright (c) 2014年 Tencent Inc. All rights reserved.
//

#import "QLContentItem.h"
#import <objc/runtime.h>

@implementation QLContentItem

@synthesize   contentType = _contentType;
@synthesize   text = _text;
@synthesize   url = _url;
@synthesize   vuserid = _vuserid;
@synthesize   nick = _nick;
@synthesize   textColor = _textColor;
@synthesize   isAppStoreLink;
@synthesize   postParam = _postParam;


- (void)dealloc
{
    self.text = nil;
    self.url = nil;
    self.vuserid = nil;
    self.nick = nil;
    self.postParam = nil;
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
    QLContentItem *other = [[[self class] allocWithZone:zone] init];
    
    if (nil != other)
    {
        other.contentType = _contentType;
        if (_text != nil) {
            other.text = [NSString stringWithString:_text];
        }
        if (_url != nil) {
            other.url = [NSString stringWithString:_url];
        }
        other.vuserid = _vuserid;
        if (_nick != nil) {
            other.nick = [NSString stringWithString:_nick];
        }
        
        if (_textColor != nil) {
            other.textColor = _textColor;
        }
        
        if (_postParam != nil) {
            other.postParam = [NSString stringWithString:_postParam];
        }
        
        other.isAppStoreLink = self.isAppStoreLink;
    }
    
    return other;
}


#pragma mark -- NSCoding

- (void)encodeWithCoder:(NSCoder *)encoder {
	Class cls = [self class];
	while (cls != [NSObject class]) {
		unsigned int numberOfIvars = 0;
		Ivar* ivars = class_copyIvarList(cls, &numberOfIvars);
		for(const Ivar* p = ivars; p < ivars+numberOfIvars; p++)
		{
			Ivar const ivar = *p;
			const char *type = ivar_getTypeEncoding(ivar);
			NSString *key = [NSString stringWithUTF8String:ivar_getName(ivar)];
            if (key == nil){
                continue;
            }
            if ([key length] == 0){
                continue;
            }
			id value = [self valueForKey:key];
			if (value) {
				switch (type[0]) {
					case _C_STRUCT_B: {
						NSUInteger ivarSize = 0;
						NSUInteger ivarAlignment = 0;
						NSGetSizeAndAlignment(type, &ivarSize, &ivarAlignment);
						NSData *data = [NSData dataWithBytes:(const char *)self + ivar_getOffset(ivar)
													  length:ivarSize];
						[encoder encodeObject:data forKey:key];
					}
						break;
					default:
						[encoder encodeObject:value
									   forKey:key];
						break;
				}
			}
		}
		if (ivars) {
			free(ivars);
		}
		
		cls = class_getSuperclass(cls);
	}
}

- (id)initWithCoder:(NSCoder *)decoder {
	
	self = [super init];
	
	if (self) {
		Class cls = [self class];
		while (cls != [NSObject class]) {
			unsigned int numberOfIvars = 0;
			Ivar* ivars = class_copyIvarList(cls, &numberOfIvars);
			
			for(const Ivar* p = ivars; p < ivars+numberOfIvars; p++)
			{
				Ivar const ivar = *p;
				const char *type = ivar_getTypeEncoding(ivar);
				NSString *key = [NSString stringWithUTF8String:ivar_getName(ivar)];
                if (key == nil){
                    continue;
                }
                if ([key length] == 0){
                    continue;
                }
				id value = [decoder decodeObjectForKey:key];
				if (value) {
					switch (type[0]) {
						case _C_STRUCT_B: {
							NSUInteger ivarSize = 0;
							NSUInteger ivarAlignment = 0;
							NSGetSizeAndAlignment(type, &ivarSize, &ivarAlignment);
							NSData *data = [decoder decodeObjectForKey:key];
							char *sourceIvarLocation = (char*)self+ ivar_getOffset(ivar);
							[data getBytes:sourceIvarLocation length:ivarSize];
							memcpy((char *)self + ivar_getOffset(ivar), sourceIvarLocation, ivarSize);
						}
							break;
						default:
							[self setValue:value forKey:key];
							break;
					}
				}
			}
			
			if (ivars) {
				free(ivars);
			}
			cls = class_getSuperclass(cls);
		}
	}
	
	return self;
}

@end
