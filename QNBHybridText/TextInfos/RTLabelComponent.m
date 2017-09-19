//
//  RTLabelComponent.m
//  richLabel-project
//
//  Created by alice on 14-10-15.
//  Copyright (c) 2014年 alicejhchen. All rights reserved.
//

#import "RTLabelComponent.h"

@implementation RTLabelComponent

@synthesize text = _text;
@synthesize tagLabel = _tagLabel;
@synthesize attributes = _attributes;
@synthesize position = _position;
@synthesize componentIndex = _componentIndex;
@synthesize isClosure = _isClosure;
@synthesize img = img_;

- (id)initWithString:(NSString*)aText tag:(NSString*)aTagLabel attributes:(NSMutableDictionary*)theAttributes;
{
    self = [super init];
    if (self) {
        self.text = aText;
        self.tagLabel = aTagLabel;
        self.attributes = theAttributes;
        self.isClosure = NO;
    }
    return self;
}

+ (id)componentWithString:(NSString*)aText tag:(NSString*)aTagLabel attributes:(NSMutableDictionary*)theAttributes
{
    return [[[self alloc] initWithString:aText tag:aTagLabel attributes:theAttributes] autorelease];
}

- (id)initWithTag:(NSString*)aTagLabel position:(NSInteger)aPosition attributes:(NSMutableDictionary*)theAttributes
{
    self = [super init];
    if (self) {
        self.tagLabel = aTagLabel;
        self.position = aPosition;
        self.attributes = theAttributes;
        self.isClosure = NO;
    }
    return self;
}

+ (id)componentWithTag:(NSString*)aTagLabel position:(NSInteger)aPosition attributes:(NSMutableDictionary*)theAttributes
{
    return [[[self alloc] initWithTag:aTagLabel position:aPosition attributes:theAttributes] autorelease];
}

- (NSString*)description
{
    NSMutableString *desc = [NSMutableString string];
    [desc appendFormat:@"text: %@", self.text];
    [desc appendFormat:@", position: %d", (int)self.position];
    if (self.tagLabel) [desc appendFormat:@", tag: %@", self.tagLabel];
    if (self.attributes) [desc appendFormat:@", attributes: %@", self.attributes];
    return desc;
}

- (void)dealloc
{
    self.text = nil;
    self.tagLabel = nil;
    self.attributes = nil;
    self.img = nil;
    [super dealloc];
}

@end
