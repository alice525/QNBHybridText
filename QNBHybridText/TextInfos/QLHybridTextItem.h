//
//  QLHybridTextItem.h
//  QLHybridTextView
//
//  Created by alicejhchen on 2017/9/12.
//  Copyright © 2017年 tencentVideo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#import <UIKit/UIKit.h>

#define DEFAULT_LINE_SPACING 3
#define DEFAULT_FONT [UIFont systemFontOfSize:15]

@class RTLabelComponent;
@class RTLabelComponentsStructure;

typedef enum
{
    RTTextAlignmentRight = kCTRightTextAlignment,
    RTTextAlignmentLeft = kCTLeftTextAlignment,
    RTTextAlignmentCenter = kCTCenterTextAlignment,
    RTTextAlignmentJustify = kCTJustifiedTextAlignment
} RTTextAlignment;

typedef enum
{
    RTTextLineBreakModeWordWrapping = kCTLineBreakByWordWrapping,
    RTTextLineBreakModeCharWrapping = kCTLineBreakByCharWrapping,
    RTTextLineBreakModeClip = kCTLineBreakByClipping,
}RTTextLineBreakMode;

typedef enum
{
    QLTextVerticalAlignmentTop = 0,
    QLTextVerticalAlignmentCenter,
    QLTextVerticalAlignmentBottom,
}QLTextVerticalAlignment;

@protocol RTLabelDelegate <NSObject>

- (void)rtLabel:(id)rtLabel didSelectLinkWithURL:(NSString*)url;

//- (void)rtLabel:(id)rtLabel didSelectSrcWithURL:(NSString*)url;

@end

@protocol RTLabelSizeDelegate <NSObject>

- (void)rtLabel:(id)rtLabel didChangedSize:(CGSize)size;

@end

@interface QLHybridTextItem : NSObject {
    CTFramesetterRef _framesetter;
    CTFrameRef _ctFrame;
    CFRange _visibleRange;
    NSString *_paragraphReplacement;
    CTFontRef _thisFont;
    CFMutableAttributedStringRef _attrString;
    RTLabelComponent * _currentLinkComponent;
    RTLabelComponent * _currentImgComponent;
    RTLabelComponentsStructure *componentsAndPlainText_;
}

/* text为需要绘制的文本，可包含自定义的表情符号，如[微笑]
 */
@property (nonatomic, copy) NSString *text;
@property (nonatomic, retain) UIFont *font;
@property (nonatomic, retain) UIColor *textColor;
@property (nonatomic, assign) RTTextLineBreakMode lineBreakMode;
@property (nonatomic, assign)NSInteger numberOfLines;     // 最多可显示的行数，0：显示所有文本 alicejhchen (20140625)
@property (nonatomic, assign)CGFloat lineSpacing;            //行间距, alicejhchen (20140919)
@property (nonatomic, assign) CGFloat prefferedMaxLayoutWidth;  //view的最大宽度，用于计算文本高度，不设置该值计算高度时选取view的宽度    alicejhchen (20141003)
@property (nonatomic, assign) RTTextAlignment textHorizonalAlignment;    //文本x轴方向的对齐
@property (nonatomic, assign)QLTextVerticalAlignment textVerticalAlignment;    //文本y轴方向的对齐方式     alicejhchen (20141023)

@property (nonatomic, assign) id<RTLabelDelegate> delegate;
@property (nonatomic, assign) id<RTLabelSizeDelegate> sizeDelegate;


- (id)initWithString:(NSString *)text;
- (void)resetParameters;

- (void)setTextHorizonalAlignment:(RTTextAlignment)textHorizonalAlignment;
- (RTTextAlignment)textHorizonalAlignment;

- (void)setLineBreakMode:(RTTextLineBreakMode)lineBreakMode;
- (RTTextLineBreakMode)lineBreakMode;

- (void)setTextColor:(UIColor*)textColor;
- (UIColor*)textColor;

- (void)setFont:(UIFont*)font;
- (UIFont*)font;

- (void)setComponentsAndPlainText:(RTLabelComponentsStructure*)componnetsDS;
- (RTLabelComponentsStructure*)componentsAndPlainText;

- (NSString*)visibleText;

- (void)renderInSize:(CGSize)size;
- (CGSize)optimumSize:(CGSize)constrainSize;

- (NSUInteger)lineCount;
- (CGSize)linesSize:(NSInteger)lCount constrainedToSize:(CGSize)size;

- (void)dismissBoundRectForTouch;
- (void)translateNormalTextToRichText;

- (BOOL)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event location:(CGPoint)location;

@end
