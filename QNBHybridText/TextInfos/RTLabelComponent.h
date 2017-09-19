//
//  RTLabelComponent.h
//  richLabel-project
//
//  Created by alice on 14-10-15.
//  Copyright (c) 2014年 alicejhchen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface RTLabelComponent : NSObject
{
    NSString *_text;
    NSString *_tagLabel;
    NSMutableDictionary *_attributes;
    NSInteger _position;
    NSInteger _componentIndex;
    BOOL _isClosure;
    UIImage *img_;
}

@property (nonatomic, assign) NSInteger componentIndex;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *tagLabel;
@property (nonatomic, retain) NSMutableDictionary *attributes;
@property (nonatomic, assign) NSInteger position;
@property (nonatomic, assign) BOOL isClosure;
@property (nonatomic, retain) UIImage *img;



- (id)initWithString:(NSString*)aText tag:(NSString*)aTagLabel attributes:(NSMutableDictionary*)theAttributes;
+ (id)componentWithString:(NSString*)aText tag:(NSString*)aTagLabel attributes:(NSMutableDictionary*)theAttributes;
- (id)initWithTag:(NSString*)aTagLabel position:(NSInteger)_position attributes:(NSMutableDictionary*)_attributes;
+ (id)componentWithTag:(NSString*)aTagLabel position:(NSInteger)aPosition attributes:(NSMutableDictionary*)theAttributes;

@end
