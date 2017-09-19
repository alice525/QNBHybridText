//
//  QLHybridTextItem.m
//  QLHybridTextView
//
//  Created by alicejhchen on 2017/9/12.
//  Copyright © 2017年 tencentVideo. All rights reserved.
//

#import "QLHybridTextItem.h"
#import "QLTextParser.h"
#import "QLContentItem.h"
#import "RegexKitLite.h"
#import "RTLabelComponent.h"
#import "RTLabelComponentsStructure.h"
#import "Utils.h"
#import "QLHTMLString.h"

#define IMAGE_PADDING 2
#define IMAGE_USER_WIDTH 180.0
#define IMAGE_MAX_WIDTH ((IMAGE_USER_WIDTH) - 4 *(IMAGE_PADDING))
#define IMAGE_USER_HEIGHT 80.0
#define IMAGE_USER_DESCENT ((IMAGE_USER_HEIGHT) / 20.0)
#define IMAGE_MAX_HEIGHT ((IMAGE_USER_HEIGHT + IMAGE_USER_DESCENT) - 2 * (IMAGE_PADDING))

#define LINK_PADDING 2
#define IMAGE_LINK_BOUND_MIN_HEIGHT 30

#define BG_COLOR 0xDDDDDD
#define IMAGE_MIN_WIDTH  5
#define IMAGE_MIN_HEIGHT 5

#define IMAGE_DEFAULT_HEIGHT 20
#define IMAGE_DEFAULT_WIDTH 20

//增加文本行最大高度和行间距以调整emoji文本所在行的高度  alicejhchen (20140701)
#define MAX_LINE_HEIGHT 17
#define MIN_LINE_HEIGHT 0
#define LINE_SPACING 3

static NSMutableDictionary *imgSizeDict = NULL;
static NSInteger totalCount = 0;

@interface QLHybridTextItem ()
@property (nonatomic, retain) RTLabelComponent *currentLinkComponent;
@property (nonatomic, retain) RTLabelComponent *currentImgComponent;
@property (nonatomic, assign) CGSize optimumSize;
@property (nonatomic, retain) UIColor *originalColor;
@property (nonatomic, copy) NSString *paragraphReplacement;


@property (nonatomic, assign) CGFloat maxLineHeight;
@property (nonatomic, assign) CGFloat minLineHeight;
@property (nonatomic, assign) CGFloat YPadding;      //用于文本竖直方向绘制时每行的偏移量   alicejhchen (20141021)

@property (nonatomic, assign) CGSize renderSize;

/*  解析带有html标签的字符串
 */
+ (RTLabelComponentsStructure*)extractTextStyle:(NSString*)data;
+ (NSString*)stripURL:(NSString*)url;

- (NSArray*) colorForHex:(NSString *)hexColor;
- (CGRect)BoundingRectForLink:(RTLabelComponent*)linkComponent withRun:(CTRunRef)run;
- (CGRect)BoundingRectFroImage:(RTLabelComponent*)imgComponent withRun:(CTRunRef)run;

- (void)genAttributedString;

- (CGPathRef)newPathForRoundedRect:(CGRect)rect radius:(CGFloat)radius;

#pragma mark -
#pragma mark styling

- (void)applyItalicStyleToText:(CFMutableAttributedStringRef)text atPosition:(NSInteger)position withLength:(NSInteger)length;
- (void)applyBoldStyleToText:(CFMutableAttributedStringRef)text atPosition:(NSInteger)position withLength:(NSInteger)length;
- (void)applyColor:(NSString*)value toText:(CFMutableAttributedStringRef)text atPosition:(NSInteger)position withLength:(NSInteger)length;
- (void)applySingleUnderlineText:(CFMutableAttributedStringRef)text atPosition:(NSInteger)position withLength:(NSInteger)length;
- (void)applyDoubleUnderlineText:(CFMutableAttributedStringRef)text atPosition:(NSInteger)position withLength:(NSInteger)length;
- (void)applyUnderlineColor:(NSString*)value toText:(CFMutableAttributedStringRef)text atPosition:(NSInteger)position withLength:(NSInteger)length;
- (void)applyFontAttributes:(NSDictionary*)attributes toText:(CFMutableAttributedStringRef)text atPosition:(NSInteger)position withLength:(NSInteger)length;
- (void)applyParagraphStyleToText:(CFMutableAttributedStringRef)text attributes:(NSMutableDictionary*)attributes atPosition:(NSInteger)position withLength:(NSInteger)length;
- (void)applyImageAttributes:(CFMutableAttributedStringRef)text attributes:(NSMutableDictionary*)attributes atPosition:(NSInteger)position withLength:(NSInteger)length;

@end

@implementation QLHybridTextItem
@synthesize textHorizonalAlignment = _textHorizonalAlignment;
@synthesize lineBreakMode = _lineBreakMode;
@synthesize font = _font;
@synthesize textColor = _textColor;

- (id)initWithString:(NSString *)text
{
    self = [self init];
    if (nil != self) {
        self.text = text;
        
    }
    
    return self;
}

- (id)init {
    if (self = [super init]) {
        [self resetParameters];
    }
    
    return self;
}

- (void)dealloc
{
    totalCount--;
    self.componentsAndPlainText = nil;
    
    self.textColor = nil;
    self.font = nil;
 
    self.currentLinkComponent = nil;
    self.currentImgComponent = nil;
    
    [_originalColor release];
    if (_thisFont) {
        CFRelease(_thisFont);
        _thisFont = NULL;
    }
    if (_ctFrame) {
        CFRelease(_ctFrame);
        _ctFrame = NULL;
    }
    if (_framesetter) {
        CFRelease(_framesetter);
        _framesetter = NULL;
    }
    if (_attrString) {
        CFRelease(_attrString);
        _attrString = NULL;
    }
    
    self.paragraphReplacement = nil;
    
    [super dealloc];
}

- (void)resetParameters {
    _text = @"";
    self.font = [UIFont fontWithName:@"Helvetica" size:15];
    _originalColor = [[UIColor colorWithRed:0x32/255.0 green:0x32/255.0 blue:0x33/255.0 alpha:1.0] retain];
    
    self.textColor = _originalColor;
    _currentLinkComponent = nil;
    _currentImgComponent = nil;
    
    //[self setText:@""];
    _textHorizonalAlignment = RTTextAlignmentLeft;
    _lineBreakMode = RTTextLineBreakModeWordWrapping;
    //_lineBreakMode = kCTLineBreakByTruncatingTail;
    _attrString = NULL;
    _ctFrame = NULL;
    _framesetter = NULL;
    _paragraphReplacement = @"\n";
    _numberOfLines = 0;
    _lineSpacing = -1.0;
    _maxLineHeight = _font.lineHeight*1.05;
    _minLineHeight = -1;
    _prefferedMaxLayoutWidth = -1;
    _YPadding = 0;
    if (_thisFont) {
        CFRelease(_thisFont);
    }
    _thisFont = CTFontCreateWithName ((CFStringRef)[self.font fontName], [self.font pointSize], NULL);
}

- (void)setTextHorizonalAlignment:(RTTextAlignment)textAlignment
{
    _textHorizonalAlignment = textAlignment;
    [self genAttributedString];
}

- (RTTextAlignment)textHorizonalAlignment
{
    return _textHorizonalAlignment;
}

- (void)setLineBreakMode:(RTTextLineBreakMode)lineBreakMode
{
    _lineBreakMode = lineBreakMode;
    [self genAttributedString];
}

- (RTTextLineBreakMode)lineBreakMode
{
    return _lineBreakMode;
}

- (void)setText:(NSString *)text
{
    if (_text) {
        if (_text != text) {
            [_text release];
            _text = nil;
        }
        else {
            return;
        }
    }
    _text = [text retain];
}

- (void)setTextColor:(UIColor*)textColor
{
    if (_textColor) {
        if (_textColor != textColor) {
            [_textColor release];
            _textColor = nil;
        }
        else {
            return;
        }
        
    }
    _textColor = [textColor retain];
    [self genAttributedString];
}

- (UIColor*)textColor
{
    return _textColor;
}

- (void)setFont:(UIFont*)font
{
    if (_font) {
        if (_font != font) {
            [_font release];
            _font = nil;
        }
        else {
            return;
        }
    }
    _font = [font retain];
    if (_font) {
        _maxLineHeight = _font.lineHeight*1.05;
        if (_thisFont) {
            CFRelease(_thisFont);
        }
        _thisFont = CTFontCreateWithName ((__bridge CFStringRef)[self.font fontName], [self.font pointSize], NULL);
    }
    
    
}

- (UIFont*)font
{
    return _font;
}

- (void)setComponentsAndPlainText:(RTLabelComponentsStructure*)componnetsDS {
    if (componentsAndPlainText_) {
        if (componentsAndPlainText_ != componnetsDS) {
            [componentsAndPlainText_ release];
            componentsAndPlainText_ = nil;
        }
        else {
            return;
        }
    }
    
    componentsAndPlainText_ = [componnetsDS retain];
    
    [self genAttributedString];
}

- (RTLabelComponentsStructure*)componentsAndPlainText {
    return componentsAndPlainText_;
}

#pragma mark -
#pragma mark excute image text
CGSize MyGetSize(void* refCon) {
    NSString *src = (NSString*)refCon;
    CGSize size = CGSizeMake(100.0,IMAGE_MAX_HEIGHT);
    
    if (src) {
        
        if (!imgSizeDict) {
            imgSizeDict = [[NSMutableDictionary dictionary] retain];
        }
        
        NSValue* nsv = [imgSizeDict objectForKey:src];
        if (nsv) {
            [nsv getValue:&size];
            return size;
        }
        
        UIImage* image = LOAD_EMOJI_IMAGE(src);
        
        
        if (image) {
            CGSize imageSize = image.size;
            CGFloat ratio = imageSize.width / imageSize.height;
            
            if (imageSize.width > IMAGE_MAX_WIDTH) {
                size.width = IMAGE_MAX_WIDTH;
                size.height = IMAGE_MAX_WIDTH / ratio;
            }
            else {
                size.width = imageSize.width;
                size.height = imageSize.height;
            }
            
            if (size.height > IMAGE_MAX_HEIGHT) {
                size.height = IMAGE_MAX_HEIGHT;
                size.width = size.height * ratio;
            }
            
            if (size.width < IMAGE_MIN_WIDTH) {
                size.width = IMAGE_MIN_WIDTH;
            }
            
            if (size.height < IMAGE_MIN_HEIGHT) {
                size.height = IMAGE_MIN_HEIGHT;
            }
            
            nsv = [NSValue valueWithBytes:&size objCType:@encode(CGSize)];
            [imgSizeDict setObject:nsv forKey:src];
            return size;
            
        }
    }
    return size;
}

void MyDeallocationCallback( void* refCon ){
    
    
}

CGFloat MyGetAscentCallback( void *refCon ){
    NSString *imgParameter = (NSString*)refCon;
    
    if (imgParameter) {
        return MyGetSize(imgParameter).height;
    }
    
    return IMAGE_USER_HEIGHT;
}

CGFloat MyGetDescentCallback( void *refCon ){
    NSString *imgParameter = (NSString*)refCon;
    
    if (imgParameter) {
        return 0;
    }
    return IMAGE_USER_DESCENT;
}

CGFloat MyGetWidthCallback( void* refCon ){
    CGSize size = MyGetSize(refCon);
    return size.width;
}

// 由表情的size决定图片lingAscent， alicejhchen (20140620)
CGFloat MyGetImgAscentCallback( void *refCon ){
    NSDictionary *imgdic = (NSDictionary *)refCon;
    
    if (imgdic) {
        CGFloat height = [[imgdic objectForKey:@"height"] floatValue] * 0.8;
        return height;
    }
    
    return IMAGE_DEFAULT_HEIGHT;
}

CGFloat MyGetImgDescentCallback( void *refCon ){
    NSDictionary *imgdic = (NSDictionary *)refCon;
    
    if (imgdic) {
        CGFloat height = [[imgdic objectForKey:@"height"] floatValue] * 0.2;
        return height;
    }
    
    return 0;
}

// 由表情的width决定为图片预留的width， alicejhchen (20140620)
CGFloat MyGetImgWidthCallback( void* refCon ){
    NSDictionary *imgdic = (NSDictionary *)refCon;
    
    CGFloat width = [[imgdic objectForKey:@"width"] floatValue];
    
    return width;
    
}

- (CGPathRef)newPathForRoundedRect:(CGRect)rect radius:(CGFloat)radius
{
    CGMutablePathRef retPath = CGPathCreateMutable();
    
    CGRect innerRect = CGRectInset(rect, radius, radius);
    
    CGFloat inside_right = innerRect.origin.x + innerRect.size.width;
    CGFloat outside_right = rect.origin.x + rect.size.width;
    CGFloat inside_bottom = innerRect.origin.y + innerRect.size.height;
    CGFloat outside_bottom = rect.origin.y + rect.size.height;
    
    CGFloat inside_top = innerRect.origin.y;
    CGFloat outside_top = rect.origin.y;
    CGFloat outside_left = rect.origin.x;
    
    CGPathMoveToPoint(retPath, NULL, innerRect.origin.x, outside_top);
    
    CGPathAddLineToPoint(retPath, NULL, inside_right, outside_top);
    CGPathAddArcToPoint(retPath, NULL, outside_right, outside_top, outside_right, inside_top, radius);
    CGPathAddLineToPoint(retPath, NULL, outside_right, inside_bottom);
    CGPathAddArcToPoint(retPath, NULL,  outside_right, outside_bottom, inside_right, outside_bottom, radius);
    
    CGPathAddLineToPoint(retPath, NULL, innerRect.origin.x, outside_bottom);
    CGPathAddArcToPoint(retPath, NULL,  outside_left, outside_bottom, outside_left, inside_bottom, radius);
    CGPathAddLineToPoint(retPath, NULL, outside_left, inside_top);
    CGPathAddArcToPoint(retPath, NULL,  outside_left, outside_top, innerRect.origin.x, outside_top, radius);
    
    CGPathCloseSubpath(retPath);
    
    return retPath;
}

- (CGRect)BoundingRectForLink:(RTLabelComponent*)linkComponent withRun:(CTRunRef)run {
    
    CGRect runBounds = CGRectZero;
    CFRange runRange = CTRunGetStringRange(run);
    BOOL runStartAfterLink = ((runRange.location >= linkComponent.position) && (runRange.location < linkComponent.position + [linkComponent.text length]));
    BOOL runStartBeforeLink = ((runRange.location < linkComponent.position) && (runRange.location + runRange.length) > linkComponent.position );
    
    // if the range of the glyph run falls within the range of the link to be highlighted
    if (runStartAfterLink || runStartBeforeLink) {
        //runRange is within the link range
        CFIndex rangePosition;
        CFIndex rangeLength;
        NSString *linkComponentString;
        if (runStartAfterLink) {
            rangePosition = 0;
            
            if (linkComponent.position + [linkComponent.text length] > runRange.location + runRange.length) {
                rangeLength = runRange.length;
            }
            else {
                rangeLength = linkComponent.position + [linkComponent.text length] - runRange.location;
            }
            linkComponentString = [self.componentsAndPlainText.plainTextData substringWithRange:NSMakeRange(runRange.location, rangeLength)];
            
        }
        else {
            rangePosition = linkComponent.position - runRange.location;
            if (linkComponent.position + [linkComponent.text length] > runRange.location + runRange.length) {
                rangeLength = runRange.location + runRange.length - linkComponent.position;
            }
            else {
                
                rangeLength = [linkComponent.text length];
            }
            linkComponentString = [self.componentsAndPlainText.plainTextData substringWithRange:NSMakeRange(linkComponent.position, rangeLength)];
        }
        NSLog(@"%@",linkComponentString);
        
        
        
        if ([[linkComponentString substringToIndex:1] isEqualToString:@"\n"]) {
            rangePosition+=1;
        }
        if ([[linkComponentString substringFromIndex:[linkComponentString length] - 1] isEqualToString:@"\n"]) {
            rangeLength -= 1;
        }
        if (rangeLength <= 0 ) {
            return runBounds;
        }
        
        CFIndex glyphCount = CTRunGetGlyphCount (run);
        if (rangePosition >= glyphCount) {
            rangePosition = 0;
        }
        if (rangeLength == runRange.length) {
            rangeLength = 0;
        }
        // work out the bounding rect for the glyph run (this doesn't include the origin)
        CGFloat ascent, descent, leading;
        CGFloat width = CTRunGetTypographicBounds(run, CFRangeMake(rangePosition, rangeLength), &ascent, &descent, &leading);
        /*if (![[linkComponentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] && ascent != MyGetAscentCallback(NULL)) {
         return runBounds;
         }*/
        
        runBounds.size.width = width;
        runBounds.size.height = ascent + fabs(descent) + leading;
        
        // get the origin of the glyph run (this is relative to the origin of the line)
        const CGPoint *positions = CTRunGetPositionsPtr(run);
        if (positions != NULL){
            runBounds.origin.x = positions[rangePosition].x;
        }
        runBounds.origin.y -= ascent;
    }
    
    // modified by tencent:jiachunke(20140506)
    return CGRectMake(floorf(runBounds.origin.x), floorf(runBounds.origin.y), floorf(runBounds.size.width), floorf(runBounds.size.height));
    //return runBounds;
}

- (CGRect)BoundingRectFroImage:(RTLabelComponent*)imgComponent withRun:(CTRunRef)run {
    CGRect runBounds = CGRectZero;
    CFRange runRange = CTRunGetStringRange(run);
    // 传入的run已经确定包含imgComponent中的图片了，所以不需要再次进行判断   alicejhchen (20140702)
    NSInteger index = imgComponent.position - runRange.location;
    
    CGSize imageSize = MyGetSize([imgComponent.attributes objectForKey:@"src"]);
    
    runBounds.size.width = imageSize.width;
    runBounds.size.height = imageSize.height;
    
    /*
     if ([imgComponent.attributes objectForKey:@"height"]) {
     CGFloat h = [[imgComponent.attributes objectForKey:@"height"] floatValue];
     CGFloat w = [[imgComponent.attributes objectForKey:@"with"] floatValue];
     if (h>0 && w>0) {
     runBounds.size.width = w;
     runBounds.size.height = h;
     }
     }*/
    // get the origin of the glyph run (this is relative to the origin of the line)
    
    const CGPoint *positions = CTRunGetPositionsPtr(run);
    
    if (positions != NULL) {
        runBounds.origin.x = positions[index].x;
    }
    
    return runBounds;
}

/* 判断字符串是否是emoji   alicejhchen (20140630)
 */
+ (BOOL)isEmojiString:(NSString *)string {
    NSInteger len = 0;
    if (string && [string length] > 0) {
        len = [string length];
    } else {
        return NO;
    }
    
    const unichar firstChar = [string characterAtIndex:0];
    if (0xd800 <= firstChar && firstChar <= 0xdbff) {
        if (len > 1) {
            const unichar secondChar = [string characterAtIndex:1];
            const int temp = ((firstChar - 0xd800) * 0x400) +(secondChar - 0xdc00) +0x10000;
            if (0x1d000 <= temp && temp <= 0x1f77f) {
                return YES;
            }
        }
    }
    /* 解决通过发表键盘打字出现的emoji后emoji被截断的问题   alicejhchen (20140714)
     打字出现的emoji编码与表情键盘中选中的emoji图片虽一样但编码略有不同, 经过统计发现有部分emoji（比如💗、⚽️等）
     通过emoji键盘打字出现的emoji len > 1，且secondChar编码为0xfe0f，通过emoji键盘出现的emoji len = 1
     两种emoji的firstChar编码均为以下范围
     */
    else if (0x2100 <= firstChar && firstChar <=0x27ff  && firstChar != 0x265b && firstChar != 0x2730 && firstChar != 0x2740) {
        return YES;
    } else if (0x2B05 <= firstChar && firstChar <=0x2b07) {
        return YES;
    } else if (0x2934 <= firstChar && firstChar <=0x2935) {
        return YES;
    } else if (0x3297 <= firstChar && firstChar <=0x3299) {
        return YES;
    } else if (firstChar == 0xa9 || firstChar == 0xae || firstChar == 0x303d || firstChar == 0x3030 ||
               firstChar == 0x2b55 || firstChar == 0x2b1c || firstChar == 0x2b1b || firstChar == 0xb50) {
        return YES;
    }
    else if (len > 1) {
        const unichar secondChar = [string characterAtIndex:1];
        if (secondChar == 0x20e3 || secondChar == 0xfe0f) {
            return YES;
        }
        
    }
    
    return NO;
}

/* 设置text每行的y轴偏移量  alicejhchen (20140701)
 当一行文本中有emoji字符时该行所需的行高比设定的最大行高大，所以core text会将该行挨着上一行绘制
 导致两行间无行间距，所以需要将该行下移LINE_SPACING的距离进行绘制
 */
- (void)setLineOrigin:(CFIndex)lineIndex context:(CGContextRef)context lineOrigins:(CGPoint *)lineOrigins line:(CTLineRef)line
{
    CGFloat lineAscent = 0;
    CGFloat lineDescent = 0;
    CGFloat lineLeading = 0;
    CGPoint lineOrigin = lineOrigins[lineIndex];
    CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, &lineLeading);
    //一些特殊字符lineLeading值很大，加入lineHeight中会导致排版不整齐，所以忽视lineLeading
    CGFloat lineHeight = lineAscent + fabs(lineDescent);
    //CGFloat lineHeight = lineAscent + fabsf(lineDescent) + lineLeading;
    
    lineOrigin.y -= _YPadding;
    
    /* 由于设置了maxLineHeight，文本的上部分空间被截断，下部分空间几乎不变，
     所以需要将文本下移(截断空间/2)，保证文本在整行空间的中央   alicejhchen (20141021)
     */
    if (lineHeight >= _maxLineHeight && _maxLineHeight > 0) {
        lineOrigin.y -= (lineHeight - _maxLineHeight)/2;
    }
    lineOrigins[lineIndex].y = lineOrigin.y;
    
    CGContextSetTextPosition(context, lineOrigin.x, lineOrigin.y);
}

/*  绘制需要加上省略号的文本（非图像和链接文本） alicejhchen (20140626)
 思路：
 1. 第0行到_maxNumberOfLine - 2行逐行绘制
 2. 第_maxNumberOfLine - 1行时，生成省略号的带属性字符串，将该字符串加入最后一行的带属性字符串中
 3. 将被省略的最后一行带属性字符串生成新的一行，绘制该行
 
 该方法能够省略最大行的最后一个字符是emoji的文本，且不会出现乱码
 */
- (CFIndex)drawTruncatedText:(CFArrayRef)lines lineOrigins:(CGPoint *)lineOrigins context:(CGContextRef)context
{
    NSUInteger truncationAttributePosition = -1;
    NSAttributedString *attributedString = (NSAttributedString *)_attrString;
    
    for (CFIndex lineIndex = 0; lineIndex < _numberOfLines; lineIndex++) {
        CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
        //是否需要截断，当为false时不需要截断将原来的Line绘制出，若为true则绘制带有省略号的行  alicejhchen (20140630)
        BOOL isTruncated = NO;
        
        CFRange lineRange = CTLineGetStringRange(line);
        
        [self setLineOrigin:lineIndex context:context lineOrigins:lineOrigins line:line];
        
#ifdef DEBUG
        //case2:
        //lineRange.length = 0;
        //case3:
        //lineRange.length = attributedString.length;
#endif
        //只有最后一行最后一个字符的location小于整个文本的最后一个字符的location时才会进行替换
        if (lineIndex == _numberOfLines - 1 &&
            lineRange.length > 0 &&
            (lineRange.location + lineRange.length < (CFIndex)attributedString.length) ) {
            //获取最后一行的带属性字符串
            NSMutableAttributedString *truncationString = [[[attributedString attributedSubstringFromRange:NSMakeRange(lineRange.location, lineRange.length)] mutableCopy] autorelease];
            unichar lastCharacter = [[truncationString string] characterAtIndex:lineRange.length - 1];
            
#ifdef DEBUG
            //case4:
            //lastCharacter = 0x3000;     //中文空格Unicode
            //lastCharacter = 0x0020;       //英文空格Unicode
            //lastCharacter = 0x000a;       //换行Unicode
            //lastCharacter = 0x000d;       //回车Unicode
#endif
            // 若最后一个字符是空格或换行符时不需要替换成省略号
            if (![[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:lastCharacter]) {
                isTruncated = YES;
                NSString* ellipsesCharacter = @"\u2026";  //省略号
                CTLineTruncationType truncationType = kCTLineTruncationEnd;
                truncationAttributePosition = lineRange.location + lineRange.length - 1; //省略号应该放入attributedString中的位置
                
                
                //生成带属性的省略号字符串并将其加入最后一行的带属性字符串中
                NSDictionary *tokenAttributes = [attributedString attributesAtIndex:truncationAttributePosition
                                                                     effectiveRange:NULL];
                NSAttributedString *tokenString = [[[NSAttributedString alloc] initWithString:ellipsesCharacter
                                                                                   attributes:tokenAttributes] autorelease];
                [truncationString appendAttributedString:tokenString];
                
                CTLineRef truncationToken = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)tokenString);
                CTLineRef truncationLine = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)truncationString);
                CTLineRef truncatedLine = CTLineCreateTruncatedLine(truncationLine, self.renderSize.width, truncationType, truncationToken);
                
#ifdef DEBUG
                //case5:
                //CFRelease(truncatedLine);
                //truncatedLine = nil;
#endif
                if (!truncatedLine) {
                    // If the line is not as wide as the truncationToken, truncatedLine is NULL
                    truncatedLine = CFRetain(truncationToken);
                }
                
                CFRelease(truncationLine);
                CFRelease(truncationToken);
                CTLineDraw(truncatedLine, context);
                CFRelease(truncatedLine);
            }
        }
        
        if (!isTruncated) {
            CTLineDraw(line, context);
        }
    }
    
    return truncationAttributePosition;
}

// 二分查找法查找图片所属的文本行   alicejhchen (20140702)
- (NSInteger)binarySearchLineForImg:(CFArrayRef)lines component:(RTLabelComponent *)component leftIndex:(NSInteger)leftIndex rightIndex:(NSInteger)rightIndex
{
    if (leftIndex >= rightIndex) {
        return leftIndex;
    }
    
    NSInteger midIndex = (leftIndex + rightIndex) / 2;
    CTLineRef line = CFArrayGetValueAtIndex(lines, midIndex);
    CFRange lineRange = CTLineGetStringRange(line);
    
    if (lineRange.location <= component.position && lineRange.location + lineRange.length >= component.position + [component.text length]) {
        return midIndex;
    } else if (lineRange.location > component.position) {
        return [self binarySearchLineForImg:lines component:component leftIndex:leftIndex rightIndex:midIndex - 1];
    } else {
        return [self binarySearchLineForImg:lines component:component leftIndex:midIndex + 1 rightIndex:rightIndex];
    }
    
}

// 二分查找法查找图片所属的run   alicejhchen (20140702)
- (NSInteger)binarySearchRunForImg:(CFArrayRef)runs component:(RTLabelComponent *)component leftIndex:(NSInteger)leftIndex rightIndex:(NSInteger)rightIndex
{
    if (leftIndex >= rightIndex) {
        return leftIndex;
    }
    
    NSInteger midIndex = (leftIndex + rightIndex) / 2;
    CTRunRef run = CFArrayGetValueAtIndex(runs, midIndex);
    CFRange runRange = CTRunGetStringRange(run);
    
    if (runRange.location <= component.position && runRange.location + runRange.length >= component.position + [component.text length]) {
        return midIndex;
    } else if (runRange.location > component.position) {
        return [self binarySearchRunForImg:runs component:component leftIndex:leftIndex rightIndex:midIndex - 1];
    } else {
        return [self binarySearchRunForImg:runs component:component leftIndex:midIndex + 1 rightIndex:rightIndex];
    }
    
}

//绘制文本中的图片,从render函数中独立成一个子函数   alicejhchen (20140701)
- (void) drawImageText:(CFIndex)truncationPos lines:(CFArrayRef)lines lineOrigins:(CGPoint *)lineOrigins context:(CGContextRef)context
{
    // 解决当lines有0个对象时crash    alicejhchen (20140703)
    if (!lines) {
        return;
    }
    if (CFArrayGetCount(lines) == 0) {
        return;
    }
    
    //获取需要绘制出的最后一行文本索引范围   alicejhchen (20141104)
    CTLineRef lastLine = CFArrayGetValueAtIndex(lines, CFArrayGetCount(lines) - 1);
    if(_numberOfLines > 0 && _numberOfLines < CFArrayGetCount(lines)) {
        lastLine = CFArrayGetValueAtIndex(lines, _numberOfLines - 1);
    }
    CFRange lastRange = CTLineGetStringRange(lastLine);
    
    for (RTLabelComponent *component in self.componentsAndPlainText.imgComponents)
    {
        // 最后一行的最后一个字符是图片时，图片被替换成省略号所以不需要绘制该图 alicejhchen (20140626)
        if (_numberOfLines > 0 &&  component.position == truncationPos ) {
            continue;
        }
        
        /* alicejhchen (20140702)
         由于图片的position是有序的，当一个图片的Position比最后一行文本最后一个字符的Position还大时,
         说明该文本被截断显示，图片不属于可见文本中，其后面的图片也不属于可见文本，不需要继续绘制图片了
         */
        if (component.position > lastRange.location + lastRange.length - 1) {
            break;
        }
        NSInteger lineIndex = [self binarySearchLineForImg:lines component:component leftIndex:0 rightIndex:CFArrayGetCount(lines) - 1];
        
        // 改成用二分查找法查找图片所属的文本行   alicejhchen (20140702)
        CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
        CGFloat lineAscent;
        CGFloat lineDescent;
        CGFloat lineLeading;
        CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, &lineLeading);
        CGFloat lineHeight = lineAscent + fabs(lineDescent) + lineLeading;
        
        // 改成用二分查找法查找图片所属的run   alicejhchen (20140702)
        CFArrayRef runs = CTLineGetGlyphRuns(line);
        NSInteger runIndex = [self binarySearchRunForImg:runs component:component leftIndex:0 rightIndex:CFArrayGetCount(runs) - 1];
        CTRunRef run = CFArrayGetValueAtIndex(runs, runIndex);
        
        CGRect runBounds = [self BoundingRectFroImage:component withRun:run];
        if (runBounds.size.width != 0 && runBounds.size.height != 0) {
            CGPoint origin = lineOrigins[lineIndex];
            CGFloat realLineHeight = (lineHeight<=_maxLineHeight)?lineHeight:_maxLineHeight;
            runBounds.origin.x += origin.x;
            runBounds.origin.y = origin.y;
            //微调表情间距 alicejhchen (20140619)
            runBounds.origin.y -= 2 * IMAGE_PADDING;
            
            if ([component.attributes objectForKey:@"src"]) {
                
                NSString *url =  [component.attributes objectForKey:@"src"];
                //对出错重试图片做特殊处理，原排版有问题。
                if ([url isEqualToString:@"retry.png"]) {
                    if (component.img) {
                        
                        runBounds.size = MyGetSize(url);
                        
                        CGFloat diff = realLineHeight - runBounds.size.height;
                        
                        runBounds.origin.y += diff / 2.0;
                        
                        CGContextDrawImage(context, runBounds, component.img.CGImage);
                    }
                    else {
                        CGFloat diff = realLineHeight - runBounds.size.height;
                        
                        runBounds.origin.y += diff / 2.0;
                        
                        CGContextSetFillColorWithColor(context, [[UIColor colorWithRed:(BG_COLOR&0xFF0000>>16)/255.f green:(BG_COLOR&0x00FF00>>8)/255.f blue:(BG_COLOR&0x0000FF)/255.f alpha:1.0f] CGColor]);
                        
                        CGContextFillRect(context, runBounds);
                        
                        /*if (component.isDownloadFail) {
                         
                         [[component.attributes objectForKey:@"src"] drawInRect:runBounds withFont:self.font lineBreakMode:NSLineBreakByTruncatingTail];
                         }*/
                    }
                }
                else
                {
                    if (component.img) {
                        
                        runBounds.size = MyGetSize(url);
                        
                        if ([component.attributes objectForKey:@"height"]) {
                            NSInteger height = [[component.attributes objectForKey:@"height"] integerValue];
                            NSInteger width = [[component.attributes objectForKey:@"width"] integerValue];
                            
                            if (height != 0 && width !=0) {
                                runBounds.size.width = width;
                                runBounds.size.height = height;
                            }
                        }
                        
                        // alicejhchen (20140619)
                        CGFloat diff =  realLineHeight - runBounds.size.height;
                        // 点赞图片特殊处理  alicejhchen (20140627)
                        if ([url isEqualToString:@"icon_已赞.png"]){
                            diff = 0;
                        }
                        
                        //当行高小于图片高度时图片需要上移，行高大于图片高度时图片下移才能保证图片中心点与该行中心点一致  alicejhchen(20140919)
                        if (diff < 0) {
                            runBounds.origin.y += diff / 2.0;
                        } else if (diff > 0){
                            runBounds.origin.y -= 1.0;
                        }
                        
                        CGContextDrawImage(context, runBounds, component.img.CGImage);
                    }
                    else {
                        CGFloat diff = realLineHeight - runBounds.size.height;
                        
                        runBounds.origin.y += diff / 2.0;
                        
                        CGContextSetFillColorWithColor(context, [[UIColor colorWithRed:(BG_COLOR&0xFF0000>>16)/255.f green:(BG_COLOR&0x00FF00>>8)/255.f blue:(BG_COLOR&0x0000FF)/255.f alpha:1.0f] CGColor]);
                        
                        CGContextFillRect(context, runBounds);
                        
                        
                        /*if (component.isDownloadFail) {
                         
                         [[component.attributes objectForKey:@"src"] drawInRect:runBounds withFont:self.font lineBreakMode:NSLineBreakByTruncatingTail];
                         }*/
                    }
                }
            }
            else {
                CGContextSetFillColorWithColor(context, [[UIColor colorWithRed:(BG_COLOR&0xFF0000>>16)/255.f green:(BG_COLOR&0x00FF00>>8)/255.f blue:(BG_COLOR&0x0000FF)/255.f alpha:1.0f] CGColor]);
                
                CGContextFillRect(context, runBounds);
            }
        }
    }
    
}

//绘制文本中的链接,从render函数中独立成一个子函数    alicejhchen (20140701)
- (void) drawLinkText:(CFArrayRef)lines lineOrigins:(CGPoint *)lineOrigins context:(CGContextRef)context path:(CGMutablePathRef)path
{
    //Calculate the bounding rect for link
    if (self.currentLinkComponent) {
        CGContextSetTextMatrix(context, CGAffineTransformIdentity);
        
        CGRect rect = CGPathGetBoundingBox(path);
        // for each line
        for (int i = 0; i < CFArrayGetCount(lines); i++) {
            CTLineRef line = CFArrayGetValueAtIndex(lines, i);
            CFArrayRef runs = CTLineGetGlyphRuns(line);
            CGFloat lineAscent = 0;
            CGFloat lineDescent = 0;
            CGFloat lineLeading = 0;
            CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, &lineLeading);
            CGPoint origin = lineOrigins[i];
            // fo each glyph run in the line
            for (int j = 0; j < CFArrayGetCount(runs); j++) {
                CTRunRef run = CFArrayGetValueAtIndex(runs, j);
                if (!self.currentLinkComponent) {
                    return;
                }
                CGRect runBounds = [self BoundingRectForLink:self.currentLinkComponent withRun:run];
                if (runBounds.size.width != 0 && runBounds.size.height != 0) {
                    
                    //runBounds.size.height = lineAscent + fabsf(lineDescent) + lineLeading;
                    CGFloat lineHeight = lineAscent + fabs(lineDescent) + lineLeading;
                    runBounds.origin.x += origin.x;
                    
                    
                    // this is more favourable
                    if (runBounds.size.height > IMAGE_LINK_BOUND_MIN_HEIGHT) {
                        runBounds.origin.x -= LINK_PADDING;
                        runBounds.size.width += LINK_PADDING * 2;
                        runBounds.origin.y -= LINK_PADDING;
                        runBounds.size.height += LINK_PADDING * 2;
                    }
                    else {
                        if (ABS((runBounds.size.height - lineHeight)) <= LINK_PADDING * 6) {
                            runBounds.origin.x -= LINK_PADDING * 2;
                            runBounds.size.width += LINK_PADDING * 4;
                            runBounds.size.height = lineHeight;
                            
                            runBounds.origin.y = (0 - lineHeight / 8 - lineAscent);
                            runBounds.size.height += lineHeight / 4;
                        }
                        else {
                            NSLog(@"%@",@"Run will use its original height!");
                            runBounds.origin.y -= runBounds.size.height / 8;
                            runBounds.size.height += runBounds.size.height / 4;
                        }
                    }
                    
                    
                    CGFloat y = rect.origin.y + rect.size.height - origin.y;
                    runBounds.origin.y += y ;
                    //Adjust the runBounds according to the line original position
                    
                    // Finally, create a rounded rect with a nice shadow and fill.
                    CGContextSetFillColorWithColor(context, [[UIColor lightGrayColor] CGColor]);
                    CGPathRef highlightPath = [self newPathForRoundedRect:runBounds radius:(runBounds.size.height / 10.0)];
                    //CGContextSetShadow(context, CGSizeMake(2, 2), 1.0);
                    CGContextAddPath(context, highlightPath);
                    CGContextFillPath(context);
                    CGPathRelease(highlightPath);
                    //CGContextSetShadowWithColor(context, CGSizeZero, 0.0, NULL);
                    
                }
            }
        }
    }
    
}

- (void)renderInSize:(CGSize)size
{
    if (!self.componentsAndPlainText || !self.componentsAndPlainText.plainTextData) return;
    
    //context will be nil if we are not in the call stack of drawRect, however we can calculate the height without the context
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGSize sizeBeforeRender = _optimumSize;
    CGRect bounds = CGRectMake(0.0, 0.0, size.width, size.height);
    self.renderSize = size;
    
    // Create the framesetter with the attributed string.
    if (_framesetter) {
        CFRelease(_framesetter);
        _framesetter = NULL;
    }
    _framesetter = CTFramesetterCreateWithAttributedString(_attrString);
    
    CFRange range;
    CGSize constraint = CGSizeMake(size.width, 1000);
    if (self.prefferedMaxLayoutWidth > 0) {
        constraint = CGSizeMake(self.prefferedMaxLayoutWidth, 1000);
    }
    
    CGSize sizeAfterRender = CTFramesetterSuggestFrameSizeWithConstraints(_framesetter, CFRangeMake(0, [self.componentsAndPlainText.plainTextData length]), nil, constraint, &range);
    _optimumSize = sizeAfterRender;
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, bounds);
    
    // Create the frame and draw it into the graphics context
    if (_ctFrame) {
        CFRelease(_ctFrame);
        _ctFrame = NULL;
    }
    _ctFrame = CTFramesetterCreateFrame(_framesetter,CFRangeMake(0, 0), path, NULL);
    
    // 计算能够显示出来的文本高度   alicejhchen (20141106)
    _optimumSize = [self linesSize:_numberOfLines constrainedToSize:bounds.size];
    
    _optimumSize = CGSizeMake(_optimumSize.width, _optimumSize.height + 2);
    
    if (![Utils isIOS7OrLatter]) {
        // IOS6计算的高度少了3个点导致最后一行emoji被截断 alicejhchen (20140624)
        _optimumSize = CGSizeMake(_optimumSize.width, (_optimumSize.height+3));
    }
    
    if (context) {
        if (_textVerticalAlignment == QLTextVerticalAlignmentCenter) {
            _YPadding = (bounds.size.height - _optimumSize.height)/2.0;
        }
        else if (_textVerticalAlignment == QLTextVerticalAlignmentBottom) {
            _YPadding = bounds.size.height - _optimumSize.height;
        }
        
        CFArrayRef lines = CTFrameGetLines(_ctFrame);
        CGPoint lineOrigins[CFArrayGetCount(lines)];
        CTFrameGetLineOrigins(_ctFrame, CFRangeMake(0, 0), lineOrigins);
        
        [self drawLinkText:lines lineOrigins:lineOrigins context:context path:path];
        
        CGAffineTransform flipVertical = CGAffineTransformMake(1,0,0,-1,0,size.height);
        CGContextConcatCTM(context, flipVertical);
        
        /*
         绘制文本中的字符（非图像和连接文本） alicejhchen (20140626)
         a. 若设定了可显示的最大行数，且最大行数小于等于文本的行数时，将最后一行的最后1个字符换成省略号
         b. 若未设定最大行数，或者文本行数小于最大行数，将整个frame绘制在context上
         truncationPos为文本被替换成省略号的位置， alicejhchen (20140626)
         */
        CFIndex truncationPos = -1;
#ifdef DEBUG
        //case1:
        //_maxNumberOfLines = CFArrayGetCount(lines) + 1;
#endif
        if (_numberOfLines > 0 && _numberOfLines <= CFArrayGetCount(lines)) {
            truncationPos = [self drawTruncatedText:lines lineOrigins:lineOrigins context:context];
        } else {
            for (CFIndex lineIndex = 0; lineIndex < CFArrayGetCount(lines); lineIndex++) {
                CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
                
                [self setLineOrigin:lineIndex context:context lineOrigins:lineOrigins line:line];
                CTLineDraw(line, context);
            }
            
        }
        
        [self drawImageText:truncationPos lines:lines lineOrigins:lineOrigins context:context];
        
        if (self.componentsAndPlainText.imgComponents.count) {
            if (fabs(sizeAfterRender.height - sizeBeforeRender.height) > 10) {
                if (self.sizeDelegate && [self.sizeDelegate respondsToSelector:@selector(rtLabel:didChangedSize:)]) {
                    [self.sizeDelegate rtLabel:self didChangedSize:sizeAfterRender];
                }
                NSLog(@"size changed!!");
                
            }
        }
    }
    _visibleRange = CTFrameGetVisibleStringRange(_ctFrame);
    
    CGPathRelease(path);
}

- (void)handleLeak
{
    CFMutableAttributedStringRef attrString = CFAttributedStringCreateMutable(kCFAllocatorDefault, 0);
    
    CFStringRef cfStr = (CFStringRef)@"a";
    CFAttributedStringReplaceString(attrString, CFRangeMake(0, 0), cfStr);
    
    CFRange range = CFRangeMake(0, 1);
    
    CTFontRef plainFontRef = CTFontCreateWithName((CFStringRef)@"Helvetica", 12, nil);
    
    // plainFontRef retain count incremented from 1 to 2
    
    CFAttributedStringSetAttribute(attrString, range, kCTFontAttributeName, plainFontRef);
    
    // plainFontRef retain count incremented from 2 to 4. Note that in order to see
    // a leak  this CTFramesetterCreateWithAttributedString() must be invoked. If
    // the creation of a framesetter is commented out, then the font inside the
    // attr string would be dellocated properly. So, this is likely a bug in the
    // implementation of CTFramesetterCreateWithAttributedString() in how it copies
    // properties from the mutable attr string.
    
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(attrString);
    
    // plainFontRef retain count decremented from 4 to 3 (note that it should have been decremented by 2)
    
    CFRelease(framesetter);
    
    // retain count is 1 at this point, so attrString is deallocated. Note that this should
    // drop the retain count of the font ref but it does not do that.
    
    CFRelease(attrString);
    
    // The retain count here should be 1 and this invocation should drop the last ref.
    // But the retain count for plainFontRef is 3 at this point so the font leaks.
    
    CFRelease(plainFontRef);
    
    return;
}

#pragma mark -
#pragma mark styling

- (void)applyParagraphStyleToText:(CFMutableAttributedStringRef)text attributes:(NSMutableDictionary*)attributes atPosition:(NSInteger)position withLength:(NSInteger)length
{
    if ([Utils isIOS5OrEarlier] && _maxLineHeight <= 0) {
        _maxLineHeight = MAX_LINE_HEIGHT+2;
    }
    else if (_maxLineHeight <= 0) {
        _maxLineHeight = MAX_LINE_HEIGHT;
    }
    
#ifdef DEBUG
    //_maxLineHeight = 0;
#endif
    
    if (_minLineHeight <= 0) {
        _minLineHeight = MIN_LINE_HEIGHT;
    }
    
    if (_lineSpacing <= 0) {
        _lineSpacing = LINE_SPACING;
    }
    
    CFMutableDictionaryRef styleDict = ( CFDictionaryCreateMutable( (0), 0, (0), (0) ) );
    
    // direction
    CTWritingDirection direction = kCTWritingDirectionLeftToRight;
    // leading
    
    // modified by tencent:jiachunke(20140503)
    //CGFloat firstLineIndent = 5.0;
    //CGFloat headIndent = 5.0;
    CGFloat firstLineIndent = 0.0;
    CGFloat headIndent = 0.0;
    
    CGFloat tailIndent = 0.0;
    CGFloat lineHeightMultiple = 1.0;
    
    // modified by tencent:alicejhchen(20140702)
    //CGFloat maxLineHeight = 0;
    //CGFloat minLineHeight = 0;
    
    CGFloat paragraphSpacing = 0.0;
    CGFloat paragraphSpacingBefore = 0.0;
    int textHorizonalAlignment = _textHorizonalAlignment;
    int lineBreakMode = _lineBreakMode;
    
    // modified by tencent:jiachunke(20140522)
    // modified by tencent:jiachunke(20140503)
    //CGFloat lineSpacing = 0;
    //CGFloat lineSpacing = 4.0;
    
    for (NSString *key in attributes)
    {
        id value = [attributes objectForKey:key];
        if ([key isEqualToString:@"align"])
        {
            if ([value isEqualToString:@"left"])
            {
                textHorizonalAlignment = kCTLeftTextAlignment;
            }
            else if ([value isEqualToString:@"right"])
            {
                textHorizonalAlignment = kCTRightTextAlignment;
            }
            else if ([value isEqualToString:@"justify"])
            {
                textHorizonalAlignment = kCTJustifiedTextAlignment;
            }
            else if ([value isEqualToString:@"center"])
            {
                textHorizonalAlignment = kCTCenterTextAlignment;
            }
        }
        else if ([key isEqualToString:@"indent"])
        {
            firstLineIndent = [value floatValue];
        }
        else if ([key isEqualToString:@"linebreakmode"])
        {
            if ([value isEqualToString:@"wordwrap"])
            {
                lineBreakMode = kCTLineBreakByWordWrapping;
            }
            else if ([value isEqualToString:@"charwrap"])
            {
                lineBreakMode = kCTLineBreakByCharWrapping;
            }
            else if ([value isEqualToString:@"clipping"])
            {
                lineBreakMode = kCTLineBreakByClipping;
            }
            else if ([value isEqualToString:@"truncatinghead"])
            {
                lineBreakMode = kCTLineBreakByTruncatingHead;
            }
            else if ([value isEqualToString:@"truncatingtail"])
            {
                lineBreakMode = kCTLineBreakByTruncatingTail;
            }
            else if ([value isEqualToString:@"truncatingmiddle"])
            {
                lineBreakMode = kCTLineBreakByTruncatingMiddle;
            }
        }
    }
    
    CTParagraphStyleSetting theSettings[] =
    {
        { kCTParagraphStyleSpecifierAlignment, sizeof(CTTextAlignment), &textHorizonalAlignment },
        { kCTParagraphStyleSpecifierLineBreakMode, sizeof(CTLineBreakMode), &lineBreakMode  },
        { kCTParagraphStyleSpecifierBaseWritingDirection, sizeof(CTWritingDirection), &direction },
        //{ kCTParagraphStyleSpecifierLineSpacing, sizeof(CGFloat), &lineSpacing },
        {kCTParagraphStyleSpecifierLineSpacingAdjustment, sizeof(CGFloat), &_lineSpacing},
        { kCTParagraphStyleSpecifierFirstLineHeadIndent, sizeof(CGFloat), &firstLineIndent },
        { kCTParagraphStyleSpecifierHeadIndent, sizeof(CGFloat), &headIndent },
        { kCTParagraphStyleSpecifierTailIndent, sizeof(CGFloat), &tailIndent },
        { kCTParagraphStyleSpecifierLineHeightMultiple, sizeof(CGFloat), &lineHeightMultiple },
        { kCTParagraphStyleSpecifierMaximumLineHeight, sizeof(CGFloat), &_maxLineHeight },
        { kCTParagraphStyleSpecifierMinimumLineHeight, sizeof(CGFloat), &_minLineHeight },
        { kCTParagraphStyleSpecifierParagraphSpacing, sizeof(CGFloat), &paragraphSpacing },
        { kCTParagraphStyleSpecifierParagraphSpacingBefore, sizeof(CGFloat), &paragraphSpacingBefore }
    };
    
    
    CTParagraphStyleRef theParagraphRef = CTParagraphStyleCreate(theSettings, sizeof(theSettings) / sizeof(CTParagraphStyleSetting));
    CFDictionaryAddValue( styleDict, kCTParagraphStyleAttributeName, theParagraphRef );
    
    CFAttributedStringSetAttributes( text, CFRangeMake(position, length), styleDict, 0 );
    CFRelease(theParagraphRef);
    CFRelease(styleDict);
}

- (void)applySingleUnderlineText:(CFMutableAttributedStringRef)text atPosition:(NSInteger)position withLength:(NSInteger)length
{
    CFStringRef keys[] = { kCTUnderlineStyleAttributeName };
    CFTypeRef values[] = { (CFNumberRef)[NSNumber numberWithInt:kCTUnderlineStyleSingle] };
    
    CFDictionaryRef fontDict = CFDictionaryCreate(NULL, (const void **)&keys, (const void **)&values, sizeof(keys) / sizeof(keys[0]), NULL, NULL);
    
    CFAttributedStringSetAttributes(text, CFRangeMake(position, length), fontDict, 0);
    CFRelease(fontDict);
}

- (void)applyDoubleUnderlineText:(CFMutableAttributedStringRef)text atPosition:(NSInteger)position withLength:(NSInteger)length
{
    
    CFStringRef keys[] = { kCTUnderlineStyleAttributeName };
    CFTypeRef values[] = { (CFNumberRef)[NSNumber numberWithInt:kCTUnderlineStyleDouble] };
    
    CFDictionaryRef fontDict = CFDictionaryCreate(NULL, (const void **)&keys, (const void **)&values, sizeof(keys) / sizeof(keys[0]), NULL, NULL);
    
    CFAttributedStringSetAttributes(text, CFRangeMake(position, length), fontDict, 0);
    CFRelease(fontDict);
}

- (void)applyItalicStyleToText:(CFMutableAttributedStringRef)text atPosition:(NSInteger)position withLength:(NSInteger)length
{
    UIFont *font = [UIFont italicSystemFontOfSize:self.font.pointSize];
    CTFontRef italicFont = CTFontCreateWithName ((__bridge CFStringRef)[font fontName], [font pointSize], NULL);
    
    
    CFStringRef keys[] = { kCTFontAttributeName };
    CFTypeRef values[] = { italicFont };
    
    CFDictionaryRef fontDict = CFDictionaryCreate(NULL, (const void **)&keys, (const void **)&values, sizeof(keys) / sizeof(keys[0]), NULL, NULL);
    
    CFAttributedStringSetAttributes(text, CFRangeMake(position, length), fontDict, 0);
    
    
    CFRelease(italicFont);
    CFRelease(fontDict);
}

- (void)applyFontAttributes:(NSDictionary*)attributes toText:(CFMutableAttributedStringRef)text atPosition:(NSInteger)position withLength:(NSInteger)length
{
    for (NSString *key in attributes)
    {
        NSString *value = [attributes objectForKey:key];
        value = [value stringByReplacingOccurrencesOfString:@"'" withString:@""];
        
        if ([key isEqualToString:@"color"])
        {
            [self applyColor:value toText:text atPosition:position withLength:length];
        }
        else if ([key isEqualToString:@"stroke"])
        {
            
            CFStringRef keys[] = { kCTStrokeWidthAttributeName };
            CFTypeRef values[] = { [NSNumber numberWithFloat:[[attributes objectForKey:@"stroke"] intValue]] };
            
            CFDictionaryRef fontDict = CFDictionaryCreate(NULL, (const void **)&keys, (const void **)&values, sizeof(keys) / sizeof(keys[0]), NULL, NULL);
            
            CFAttributedStringSetAttributes(text, CFRangeMake(position, length), fontDict, 0);
            
            
            CFRelease(fontDict);
            
        }
        else if ([key isEqualToString:@"kern"])
        {
            CFStringRef keys[] = { kCTKernAttributeName };
            CFTypeRef values[] = { [NSNumber numberWithFloat:[[attributes objectForKey:@"kern"] intValue]] };
            
            CFDictionaryRef fontDict = CFDictionaryCreate(NULL, (const void **)&keys, (const void **)&values, sizeof(keys) / sizeof(keys[0]), NULL, NULL);
            
            CFAttributedStringSetAttributes(text, CFRangeMake(position, length), fontDict, 0);
            
            
            CFRelease(fontDict);
        }
        else if ([key isEqualToString:@"underline"])
        {
            int numberOfLines = [value intValue];
            if (numberOfLines==1)
            {
                [self applySingleUnderlineText:text atPosition:position withLength:length];
            }
            else if (numberOfLines==2)
            {
                [self applyDoubleUnderlineText:text atPosition:position withLength:length];
            }
        }
        else if ([key isEqualToString:@"style"])
        {
            if ([value isEqualToString:@"bold"])
            {
                [self applyBoldStyleToText:text atPosition:position withLength:length];
            }
            else if ([value isEqualToString:@"italic"])
            {
                [self applyItalicStyleToText:text atPosition:position withLength:length];
            }
        }
    }
    
    UIFont *font = nil;
    if ([attributes objectForKey:@"face"] && [attributes objectForKey:@"size"])
    {
        NSString *fontName = [attributes objectForKey:@"face"];
        fontName = [fontName stringByReplacingOccurrencesOfString:@"'" withString:@""];
        font = [UIFont fontWithName:fontName size:[[attributes objectForKey:@"size"] intValue]];
    }
    else if ([attributes objectForKey:@"face"] && ![attributes objectForKey:@"size"])
    {
        NSString *fontName = [attributes objectForKey:@"face"];
        fontName = [fontName stringByReplacingOccurrencesOfString:@"'" withString:@""];
        font = [UIFont fontWithName:fontName size:self.font.pointSize];
    }
    else if (![attributes objectForKey:@"face"] && [attributes objectForKey:@"size"])
    {
        font = [UIFont fontWithName:[self.font fontName] size:[[attributes objectForKey:@"size"] intValue]];
    }
    // 处理不符合以上条件时font为空的情况    alicejhchen (20140627)
    if (!font) {
        font  = self.font;
    }
    
    if (font)
    {
        CTFontRef customFont = CTFontCreateWithName ((__bridge CFStringRef)[font fontName], [font pointSize], NULL);
        
        CFStringRef keys[] = { kCTFontAttributeName };
        CFTypeRef values[] = { customFont };
        
        CFDictionaryRef fontDict = CFDictionaryCreate(NULL, (const void **)&keys, (const void **)&values, sizeof(keys) / sizeof(keys[0]), NULL, NULL);
        
        CFAttributedStringSetAttributes(text, CFRangeMake(position, length), fontDict, 0);
        
        
        
        CFRelease(customFont);
        CFRelease(fontDict);
    }
}

//This method will be called when parsing a link
- (void)applyBoldStyleToText:(CFMutableAttributedStringRef)text atPosition:(NSInteger)position withLength:(NSInteger)length
{
    //If the font size is very large(bigger than 30), core text will invoke a memory
    //warning, and may cause crash.
    UIFont *font = [UIFont boldSystemFontOfSize:self.font.pointSize + 1];
    CTFontRef boldFont = CTFontCreateWithName ((__bridge CFStringRef)[font fontName], [font pointSize], NULL);
    CFStringRef keys[] = { kCTFontAttributeName };
    CFTypeRef values[] = { boldFont };
    
    CFDictionaryRef fontDict = CFDictionaryCreate(NULL, (const void **)&keys, (const void **)&values, sizeof(keys) / sizeof(keys[0]), NULL, NULL);
    
    CFAttributedStringSetAttributes(text, CFRangeMake(position, length), fontDict, 0);
    
    //CFAttributedStringSetAttribute(text, CFRangeMake(position, length), kCTFontAttributeName, boldFont);
    //CFAttributedStringSetAttribute(text, CFRangeMake(position, length), kCTFontAttributeName, _thisFont);
    CFRelease(boldFont);
    CFRelease(fontDict);
}

- (void)applyColor:(NSString*)value toText:(CFMutableAttributedStringRef)text atPosition:(NSInteger)position withLength:(NSInteger)length
{
    if(!value) {
        
        CGColorRef color = [self.textColor CGColor];
        
        
        
        
        
        CFStringRef keys[] = { kCTForegroundColorAttributeName };
        CFTypeRef values[] = { color };
        
        CFDictionaryRef colorDict = CFDictionaryCreate(NULL, (const void **)&keys, (const void **)&values, sizeof(keys) / sizeof(keys[0]), NULL, NULL);
        
        CFAttributedStringSetAttributes(text, CFRangeMake(position, length), colorDict, 0);
        CFRelease(colorDict);
    }
    else if ([value rangeOfString:@"#"].location == 0) {
        CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
        value = [value stringByReplacingOccurrencesOfString:@"#" withString:@""];
        NSArray *colorComponents = [self colorForHex:value];
        CGFloat components[] = { [[colorComponents objectAtIndex:0] floatValue] , [[colorComponents objectAtIndex:1] floatValue] , [[colorComponents objectAtIndex:2] floatValue] , [[colorComponents objectAtIndex:3] floatValue] };
        CGColorRef color = CGColorCreate(rgbColorSpace, components);
        
        
        
        
        
        CFStringRef keys[] = { kCTForegroundColorAttributeName };
        CFTypeRef values[] = { color };
        
        CFDictionaryRef colorDict = CFDictionaryCreate(NULL, (const void **)&keys, (const void **)&values, sizeof(keys) / sizeof(keys[0]), NULL, NULL);
        
        CFAttributedStringSetAttributes(text, CFRangeMake(position, length), colorDict, 0);
        
        CGColorRelease(color);
        CFRelease(colorDict);
        CGColorSpaceRelease(rgbColorSpace);
    } else {
        value = [value stringByAppendingString:@"Color"];
        SEL colorSel = NSSelectorFromString(value);
        UIColor *_color = nil;
        if ([UIColor respondsToSelector:colorSel]) {
            _color = [UIColor performSelector:colorSel];
            CGColorRef color = [_color CGColor];
            
            
            CFStringRef keys[] = { kCTForegroundColorAttributeName };
            CFTypeRef values[] = { color };
            
            CFDictionaryRef colorDict = CFDictionaryCreate(NULL, (const void **)&keys, (const void **)&values, sizeof(keys) / sizeof(keys[0]), NULL, NULL);
            
            CFAttributedStringSetAttributes(text, CFRangeMake(position, length), colorDict, 0);
            
            CFRelease(colorDict);
            
        }
    }
}

- (void)applyUnderlineColor:(NSString*)value toText:(CFMutableAttributedStringRef)text atPosition:(NSInteger)position withLength:(NSInteger)length
{
    value = [value stringByReplacingOccurrencesOfString:@"'" withString:@""];
    if ([value rangeOfString:@"#"].location==0) {
        CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
        value = [value stringByReplacingOccurrencesOfString:@"#" withString:@""];
        NSArray *colorComponents = [self colorForHex:value];
        CGFloat components[] = { [[colorComponents objectAtIndex:0] floatValue] , [[colorComponents objectAtIndex:1] floatValue] , [[colorComponents objectAtIndex:2] floatValue] , [[colorComponents objectAtIndex:3] floatValue] };
        CGColorRef color = CGColorCreate(rgbColorSpace, components);
        
        
        
        CFStringRef keys[] = { kCTUnderlineColorAttributeName };
        CFTypeRef values[] = { color };
        
        CFDictionaryRef colorDict = CFDictionaryCreate(NULL, (const void **)&keys, (const void **)&values, sizeof(keys) / sizeof(keys[0]), NULL, NULL);
        
        CFAttributedStringSetAttributes(text, CFRangeMake(position, length), colorDict, 0);
        
        
        
        CGColorRelease(color);
        CFRelease(colorDict);
        CGColorSpaceRelease(rgbColorSpace);
    } else {
        value = [value stringByAppendingString:@"Color"];
        SEL colorSel = NSSelectorFromString(value);
        UIColor *_color = nil;
        if ([UIColor respondsToSelector:colorSel]) {
            _color = [UIColor performSelector:colorSel];
            CGColorRef color = [_color CGColor];
            
            
            CFStringRef keys[] = { kCTUnderlineColorAttributeName };
            CFTypeRef values[] = { color };
            
            CFDictionaryRef colorDict = CFDictionaryCreate(NULL, (const void **)&keys, (const void **)&values, sizeof(keys) / sizeof(keys[0]), NULL, NULL);
            
            CFAttributedStringSetAttributes(text, CFRangeMake(position, length), colorDict, 0);
            
            CFRelease(colorDict);
            
        }
    }
}

- (void)applyImageAttributes:(CFMutableAttributedStringRef)text attributes:(NSMutableDictionary*)attributes atPosition:(NSInteger)position withLength:(NSInteger)length
{
    // create the delegate
    CTRunDelegateCallbacks callbacks;
    callbacks.version = kCTRunDelegateVersion1;
    callbacks.dealloc = MyDeallocationCallback;
    callbacks.getAscent = MyGetAscentCallback;
    callbacks.getDescent = MyGetDescentCallback;
    callbacks.getWidth = MyGetWidthCallback;
    
    NSString *imgParameter = (NSString*)[attributes objectForKey:@"src"];
    
    CTRunDelegateRef delegate = CTRunDelegateCreate(&callbacks, [attributes objectForKey:@"src"]);
    
    // 若是表情图片，则按指定的height和width缩放表情，从而使lineAscent值为表情的height，width为表情的width   alicejhchen (20140620)
    if (imgParameter && [imgParameter hasPrefix:@"Expression"]) {
        callbacks.getAscent = MyGetImgAscentCallback;
        callbacks.getWidth = MyGetImgWidthCallback;
        callbacks.getDescent = MyGetImgDescentCallback;
        CFRelease(delegate);
        delegate = CTRunDelegateCreate(&callbacks, attributes);
    }
    
    CFStringRef keys[] = { kCTRunDelegateAttributeName };
    CFTypeRef values[] = { delegate };
    
    CFDictionaryRef imgDict = CFDictionaryCreate(NULL, (const void **)&keys, (const void **)&values, sizeof(keys) / sizeof(keys[0]), NULL, NULL);
    
    CFAttributedStringSetAttributes(text, CFRangeMake(position, length), imgDict, 0);
    
    CFRelease(delegate);
    CFRelease(imgDict);
}

#pragma mark -
#pragma

- (CGSize)optimumSize:(CGSize)constrainSize
{
    [self renderInSize:constrainSize];
    return _optimumSize;
}

- (NSUInteger)lineCount
{
    CFArrayRef lines = CTFrameGetLines(_ctFrame);
    return CFArrayGetCount(lines);
}

/* 计算能够显示出来的文本size   alicejhchen (20141107)
 文本无法全部显示出来的原因有：
 1. 指定了最大行数lCount比文本的实际行数少
 2. 控件size比文本所需size小
 lCount为0表示未指定最大行数，希望文本全部显示出来
 */
- (CGSize)linesSize:(NSInteger)lCount constrainedToSize:(CGSize)size
{
    CGSize totalSize = _optimumSize;
    
    CFArrayRef lines = CTFrameGetLines(_ctFrame);
    NSUInteger count = CFArrayGetCount(lines);
    
    if (count <=0) {
        _optimumSize = size;
        return size;
    }
    
    if ((lCount == 0 || lCount >= count) && size.height >= totalSize.height) {
        return totalSize;
    }
    
    NSInteger minCount = MIN(lCount, count);
    
    if (lCount == 0) {
        minCount = count;
    }
    
    CTLineRef lastLine = CFArrayGetValueAtIndex(lines, minCount - 1);
    
    CGPoint origins[count];
    CTFrameGetLineOrigins(_ctFrame, CFRangeMake(0, 0), origins);
    CGPoint lPoint = origins[minCount-1];
    CGFloat lY = (size.height - lPoint.y);
    
    CGFloat ascent;
    CGFloat descent;
    CGFloat leading;
    CTLineGetTypographicBounds(lastLine, &ascent, &descent, &leading);
    
    //预留一定的空间以免当文本最后一行只有emoji时emoji底部被截断   alicejhchen (20141106)
    //lY += 2;
    return CGSizeMake(totalSize.width, (lY+fabs(descent)));
}

+ (RTLabelComponentsStructure*)extractTextStyle:(NSString*)data
{
    
    NSScanner *scanner = nil;
    NSString *text = nil;
    NSString *tag = nil;
    //These two variable are used to handle the unclosed tags.
    BOOL isBeginTag = NO;
    NSInteger beginTagCount = 0;
    
    //plainData is used to store the current plain result during the parse process,
    //such as <a>link to yahoo!</a> </font> (the start tag <font size=30> has
    //been parsed)
    NSString *plainData = [NSString stringWithString:data];
    
    NSMutableArray *components = [NSMutableArray array];
    NSMutableArray *linkComponents = [NSMutableArray array];
    NSMutableArray *imgComponents = [NSMutableArray array];
    
    NSInteger last_position = 0;
    scanner = [NSScanner scannerWithString:data];
    while (![scanner isAtEnd])
    {
        //Begin element(such as <font size=30>) or end element(such as </font>)
        [scanner scanUpToString:@"<" intoString:&text];
        
        if(beginTagCount <= 0 && !isBeginTag && text) { //This words even can handle the unclosed tags elegancely
            
            NSRange subRange;
            //Decipher
            do {
                subRange = [plainData rangeOfString:@"&lt;" options:NSCaseInsensitiveSearch range:NSMakeRange(last_position, [text length])];
                if (subRange.location == NSNotFound) {
                    break;
                }
                
                plainData = [plainData stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<" options:NSCaseInsensitiveSearch range:subRange];
                text = [text stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<" options:NSCaseInsensitiveSearch range:NSMakeRange(subRange.location - last_position,subRange.length)];
                
                
            }
            while (true);
            do {
                subRange = [plainData rangeOfString:@"&gt;" options:NSCaseInsensitiveSearch range:NSMakeRange(last_position, [text length])];
                if (subRange.location == NSNotFound) {
                    break;
                }
                
                plainData = [plainData stringByReplacingOccurrencesOfString:@"&gt;" withString:@">" options:NSCaseInsensitiveSearch range:subRange];
                text = [text stringByReplacingOccurrencesOfString:@"&gt;" withString:@">" options:NSCaseInsensitiveSearch range:NSMakeRange(subRange.location - last_position,subRange.length)];
            }
            while (true);
            
            
            
            RTLabelComponent *component = [RTLabelComponent componentWithString:text tag:@"rawText" attributes:nil];
            component.isClosure = YES;
            component.position = last_position;
            [components addObject:component];
            
            
        }
        text = nil;
        
        [scanner scanUpToString:@">" intoString:&text];
        if (!text || [scanner isAtEnd]) {
            
            if (text) {
                plainData = [plainData stringByReplacingOccurrencesOfString:text withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange([plainData length] - [text length], [text length])];
                //NSLog(@"%@",plainData);
            }
            break;
        }
        else {
            
            [scanner setScanLocation:[scanner scanLocation] + 1];
        }
        //delimiter now equals to a start tag(such as <font size=30>) or end tag(such as </font>)
        
        
        NSString *delimiter = [NSString stringWithFormat:@"%@>", text];
        NSInteger position = [plainData rangeOfString:delimiter options:NSCaseInsensitiveSearch range:NSMakeRange(last_position, [plainData length] - last_position)].location;
        
        if (position != NSNotFound && position >= last_position)
        {
            isBeginTag = YES;
            beginTagCount++;
            //Only replace the string behind the position, so no need to
            //recalculate the position
            plainData = [plainData stringByReplacingOccurrencesOfString:delimiter withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(position, delimiter.length)];
        }
        else {//NOTE:This will never happen!
            //NSLog(@"Some Error happen in parsing");
            break;
            
        }
        
        //Strip the white space in both end
        NSString *tempString = [text substringFromIndex:1];
        text = [tempString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        
        //That means a end tag, we should store the plain text after parsing the tag
        if ([text rangeOfString:@"/"].location==0)
        {
            isBeginTag = NO;
            beginTagCount --;
            // tag name
            
            //This can handle the awful white space too
            NSArray *textComponents = [[text substringFromIndex:1]componentsSeparatedByString:@" "];
            
            
            tag = [textComponents objectAtIndex:0];
            
            //NSLog(@"end of tag: %@", tag);
            
            NSRange subRange;
            //Decipher
            do {
                subRange = [plainData rangeOfString:@"&lt;" options:NSCaseInsensitiveSearch range:NSMakeRange(last_position, position - last_position)];
                if (subRange.location == NSNotFound) {
                    break;
                }
                plainData = [plainData stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<" options:NSCaseInsensitiveSearch range:subRange];
                //Length of @"&lt;" substract length of @"<"
                position -= 3;
            }
            while (true);
            do {
                subRange = [plainData rangeOfString:@"&gt;" options:NSCaseInsensitiveSearch range:NSMakeRange(last_position, position - last_position)];
                if (subRange.location == NSNotFound) {
                    break;
                }
                plainData = [plainData stringByReplacingOccurrencesOfString:@"&gt;" withString:@">" options:NSCaseInsensitiveSearch range:subRange];
                //Length of @"&gt;" substract length of @">"
                position -= 3;
            }
            while (true);
            
            //Find the latest tag
            //Do not use stack, because the overlapping tags are meaningful
            //This algrithm can handle the overlapping tags
            for (NSInteger i=[components count]-1; i>=0; i--)
            {
                RTLabelComponent *component = [components objectAtIndex:i];
                if (!component.isClosure && [component.tagLabel isEqualToString:tag])
                {
                    NSString *text2 = [plainData substringWithRange:NSMakeRange(component.position, position - component.position)];
                    component.text = text2;
                    component.isClosure = YES;
                    break;
                }
            }
            
            
            
        }
        else // start tag
        {
            //tag name and tag attributes
            //These words can handle if the tag is a self-closed one
            BOOL isClosure = NO;
            NSRange range = [text rangeOfString:@"/" options:NSBackwardsSearch];
            
            if (range.location == [text length] - 1) {
                isClosure = YES;
                text = [text substringToIndex:[text length] - 1];
            }
            RTLabelComponent *component = nil;
            //These words can handle if the attribute string are concacted with awful white space
            NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
            NSRange subRange;
            //You can not simply use text = [text stringByReplacingOccurrencesOfString:@"= " withString:@"="]; instead,
            //since this function can not execute incursively
            do{
                subRange = [text rangeOfString:@"= "];
                if (subRange.location == NSNotFound) {
                    break;
                }
                text = [text stringByReplacingOccurrencesOfString:@"= " withString:@"=" options:NSCaseInsensitiveSearch range:subRange];
                
            }while(true);
            
            do{
                subRange = [text rangeOfString:@" ="];
                if (subRange.location == NSNotFound) {
                    break;
                }
                text = [text stringByReplacingOccurrencesOfString:@" =" withString:@"=" options:NSCaseInsensitiveSearch range:subRange];
                
            }while(true);
            
            
            NSArray *textComponents = [text componentsSeparatedByString:@" "];
            
            tag = [textComponents objectAtIndex:0];
            
            if (tag != nil && [tag length]) { //That means the tag starts with a white space, ignore it, treat it as a raw text
                for (int i=1; i<[textComponents count]; i++)
                {
                    //NSLog(@"textComponents %d:%@",i,[textComponents objectAtIndex:i]);
                    
                    NSArray *pair = [[textComponents objectAtIndex:i] componentsSeparatedByString:@"="];
                    if ([pair count]>=2)
                    {
                        [attributes setObject:[[pair subarrayWithRange:NSMakeRange(1, [pair count] - 1)] componentsJoinedByString:@"="] forKey:[pair objectAtIndex:0]];
                    }
                }
                
                
                component = [RTLabelComponent componentWithString:nil tag:tag attributes:attributes];
            }
            else {
                component = [RTLabelComponent componentWithString:nil tag:@"rawText" attributes:attributes];
            }
            
            
            
            //Store the start position, which will be used to calculate
            //the plain text inside of a tag
            component.position = position;
            component.isClosure = isClosure;
            BOOL isSizeTooSmall = NO;
            if ([component.tagLabel isEqualToString:@"img"]) {
                
                
                NSString *url =  [component.attributes objectForKey:@"src"];
                /*NSString *inlineStyleWidth = [component.attributes objectForKey:@"width"];
                 NSString *inlineStyleHeight = [component.attributes objectForKey:@"height"];
                 */
                
                
                NSString *tempURL = [QLHybridTextItem stripURL:url];
                if (tempURL) {
                    [component.attributes setObject:tempURL forKey:@"src"];
                    UIImage  *tempImg = LOAD_EMOJI_IMAGE(tempURL);
                    
                    component.img = tempImg;
                    
                }
                
                
                
                if (!isSizeTooSmall) {
                    
                    //NSMutableString *tempString = [NSMutableString stringWithString:plainData];
                    //[tempString insertString:@"`" atIndex:position];
                    //[tempString insertString:@" " atIndex:position];
                    
                    //plainData = [NSString stringWithString:tempString];
                    
                    component.text = [plainData substringWithRange:NSMakeRange(component.position, 1)];
                    component.isClosure = YES;
                    
                    [components addObject:component];
                }
            }
            else {
                
                [components addObject:component];
                
            }
            
            
            if ([component.tagLabel isEqualToString:@"a"]) {
                [linkComponents addObject:component];
            }
            if ([component.tagLabel isEqualToString:@"img"]) {
                [imgComponents addObject:component];
            }
        }
        
        last_position = position;
        text = nil;
    }
    
    
    for (RTLabelComponent *item in components) {
        if (!item.isClosure) {
            
            NSString *text2 = [plainData substringWithRange:NSMakeRange(item.position, [plainData length] - item.position)];
            item.text = text2;
        }
        
    }
    
    RTLabelComponentsStructure *componentsDS = [[RTLabelComponentsStructure alloc] init];
    componentsDS.components = components;
    componentsDS.linkComponents = linkComponents;
    componentsDS.imgComponents = imgComponents;
    componentsDS.plainTextData = plainData;
    
    return [componentsDS autorelease];
}

- (void)genAttributedString
{
    if (!self.componentsAndPlainText || !self.componentsAndPlainText.plainTextData || !self.componentsAndPlainText.components) {
        return;
    }
    
    CFStringRef string = (__bridge CFStringRef)self.componentsAndPlainText.plainTextData;
    if (_attrString) {
        CFRelease(_attrString);
        _attrString = NULL;
    }
    _attrString = CFAttributedStringCreateMutable(NULL, 0);
    
    CFAttributedStringReplaceString (_attrString, CFRangeMake(0, 0), string);
    
    CFMutableDictionaryRef styleDict = CFDictionaryCreateMutable(NULL, 0, 0, 0);
    
    CFDictionaryAddValue( styleDict, kCTForegroundColorAttributeName, [self.textColor CGColor] );
    CFAttributedStringSetAttributes( _attrString, CFRangeMake( 0, CFAttributedStringGetLength(_attrString) ), styleDict, 0 );
    
    // alicejhchen (20140619)
#ifdef DEBUG
    //  NSInteger t = CFAttributedStringGetLength(_attrString);
#endif
    
    [self applyParagraphStyleToText:_attrString attributes:nil atPosition:0 withLength:CFAttributedStringGetLength(_attrString)];
    
    /* ios6中emoji后紧跟部分中文时字体变成粗体bug修改   alicejhchen (20141030)
     原因：按理说不需要特意为emoji设定AppleColorEmoji字体，系统在遇到emoji时会自动为其设定该字体
     但ios6并未自动设定emoji字体，导致这种奇葩现在，所以按以下方法修改使系统将文本中的emoji强制
     转换成AppleColorEmoji字体
     */
    NSDictionary *fontAttributes = @{
                                     (id)kCTFontFamilyNameAttribute : _font.fontName,
                                     (id)kCTFontCascadeListAttribute : @[
                                             ( id)CTFontDescriptorCreateWithNameAndSize(CFSTR("AppleColorEmoji"), 0),
                                             ( id)CTFontDescriptorCreateWithNameAndSize((CFStringRef)_font.fontName, 0),
                                             ]
                                     };
    CTFontDescriptorRef descriptor = CTFontDescriptorCreateWithAttributes((__bridge CFDictionaryRef)(fontAttributes));
    CTFontRef nfont = CTFontCreateWithFontDescriptor(descriptor, _font.pointSize, 0);
    CFStringRef keys[] = { kCTFontAttributeName};
    CFTypeRef values[] = { nfont};
    
    CFDictionaryRef fontDict = CFDictionaryCreate(NULL, (const void **)&keys, (const void **)&values, sizeof(keys) / sizeof(keys[0]), NULL, NULL);
    
    CFAttributedStringSetAttributes(_attrString, CFRangeMake(0, CFAttributedStringGetLength(_attrString)), fontDict, 0);
    
    CFRelease(descriptor);
    CFRelease(nfont);
    CFRelease(fontDict);
    
    for (RTLabelComponent *component in self.componentsAndPlainText.components)
    {
        NSInteger index = [self.componentsAndPlainText.components indexOfObject:component];
        component.componentIndex = index;
        
        if ([component.tagLabel isEqualToString:@"i"])
        {
            // make font italic
            [self applyItalicStyleToText:_attrString atPosition:component.position withLength:[component.text length]];
            [self applyColor:nil toText:_attrString atPosition:component.position withLength:[component.text length]];
            //[self applyColor:@"#2e2e2e" toText:_attrString atPosition:component.position withLength:[component.text length]];
        }
        else if ([component.tagLabel isEqualToString:@"b"])
        {
            // make font bold
            [self applyBoldStyleToText:_attrString atPosition:component.position withLength:[component.text length]];
            [self applyColor:nil toText:_attrString atPosition:component.position withLength:[component.text length]];
            //[self applyColor:@"#2e2e2e" toText:_attrString atPosition:component.position withLength:[component.text length]];
        }
        else if ([component.tagLabel isEqualToString:@"a"])
        {
            
            [self applyBoldStyleToText:_attrString atPosition:component.position withLength:[component.text length]];
            if(![self.textColor isEqual:[UIColor whiteColor]]) {
                [self applyColor:@"#16387C" toText:_attrString atPosition:component.position withLength:[component.text length]];
            }
            else {
                [self applyColor:nil toText:_attrString atPosition:component.position withLength:[component.text length]];
                
            }
            
            //[self applySingleUnderlineText:_attrString atPosition:component.position withLength:[component.text length]];
            
            
            
            NSString *value = [component.attributes objectForKey:@"href"];
            //value = [value stringByReplacingOccurrencesOfString:@"'" withString:@""];
            if (value) {
                [component.attributes setObject:value forKey:@"href"];
                
            }
        }
        else if ([component.tagLabel isEqualToString:@"u"] || [component.tagLabel isEqualToString:@"underlined"])
        {
            // underline
            if ([component.tagLabel isEqualToString:@"u"])
            {
                [self applySingleUnderlineText:_attrString atPosition:component.position withLength:[component.text length]];
            }
            
            
            if ([component.attributes objectForKey:@"color"])
            {
                NSString *value = [component.attributes objectForKey:@"color"];
                [self applyUnderlineColor:value toText:_attrString atPosition:component.position withLength:[component.text length]];
            }
        }
        else if ([component.tagLabel isEqualToString:@"font"])
        {
            [self applyFontAttributes:component.attributes toText:_attrString atPosition:component.position withLength:[component.text length]];
        }
        else if ([component.tagLabel isEqualToString:@"p"])
        {
            [self applyParagraphStyleToText:_attrString attributes:component.attributes atPosition:component.position withLength:[component.text length]];
        }
        else if([component.tagLabel isEqualToString:@"img"])
        {
            [self applyImageAttributes:_attrString attributes:component.attributes atPosition:component.position withLength:[component.text length]];
        }
    }
    CFRelease(styleDict);
}

- (NSArray*)colorForHex:(NSString *)hexColor
{
    hexColor = [[hexColor stringByTrimmingCharactersInSet:
                 [NSCharacterSet whitespaceAndNewlineCharacterSet]
                 ] uppercaseString];
    
    NSRange range;
    range.location = 0;
    range.length = 2;
    
    NSString *rString = [hexColor substringWithRange:range];
    
    range.location = 2;
    NSString *gString = [hexColor substringWithRange:range];
    
    range.location = 4;
    NSString *bString = [hexColor substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    NSArray *components = [NSArray arrayWithObjects:[NSNumber numberWithFloat:((float) r / 255.0f)],[NSNumber numberWithFloat:((float) g / 255.0f)],[NSNumber numberWithFloat:((float) b / 255.0f)],[NSNumber numberWithFloat:1.0],nil];
    return components;
    
}

+ (NSString*)stripURL:(NSString*)url {
    
    NSString *tempURL = [url stringByReplacingOccurrencesOfRegex:@"^\\\\?[\"\']" withString:@""];
    tempURL = [tempURL stringByReplacingOccurrencesOfRegex:@"\\\\?[\"\']$" withString:@""];
    return tempURL;
}

- (void)dismissBoundRectForTouch
{
    self.currentImgComponent = nil;
    self.currentLinkComponent = nil;
}

- (NSString*)visibleText
{
    [self renderInSize:self.renderSize];
    NSString *text = [self.componentsAndPlainText.plainTextData substringWithRange:NSMakeRange(_visibleRange.location, _visibleRange.length)];
    return text;
}

#pragma mark -
#pragma excute text (可包含qq表情符号的文本)
- (void)translateNormalTextToRichText
{
    NSString *multiStr = [self generateMultiString:_text];
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    RTLabelComponentsStructure *componentsDS = [QLHybridTextItem extractTextStyle:multiStr];
    self.componentsAndPlainText = componentsDS;
    // 先初始化整个文本，tencent:jiachunke(20140611)
    [pool drain];
}

- (NSString *)generateMultiString:(NSString *)Str
{
    NSMutableString *multiString = [[[NSMutableString alloc] init] autorelease];
    NSMutableArray* itemArray = [QLTextParser parseText:Str];
    for (QLContentItem *contentItem in itemArray) {
        if (contentItem.contentType == QL_CONTENT_ITEM_TYPE_EM) {
            NSString* emojiName = [NSString stringWithFormat:@"Expression_%@.png",contentItem.text];
            
            //经过多次测试总结出表情图片大小与font的关系如下设定整个文本排版会更美观   alicejhchen (20141111)
            if (_font.pointSize < 13) {
                [multiString appendFormat:@"%@",[QLHTMLString imageHTML:emojiName index:-1 size:CGSizeMake(_font.lineHeight*1.15, _font.lineHeight*1.15)]];
            }
            else if (_font.pointSize < 16) {
                [multiString appendFormat:@"%@",[QLHTMLString imageHTML:emojiName index:-1 size:CGSizeMake(_font.lineHeight*1.1, _font.lineHeight*1.1)]];
            }
            else {
                [multiString appendFormat:@"%@",[QLHTMLString imageHTML:emojiName index:-1 size:CGSizeMake(_font.lineHeight, _font.lineHeight)]];
            }
            
        }else if(contentItem.contentType == QL_CONTENT_ITEM_TYPE_TEXT){
            [multiString appendFormat:@"%@",[QLHTMLString plainContentHTML:contentItem.text]];
        }else if(contentItem.contentType == QL_CONTENT_ITEM_TYPE_URL){
            [multiString appendFormat:@"%@",[QLHTMLString urlHTML:contentItem.text]];
        }
    }
    
    return multiString;
}

// 若响应点击事件返回YES，不需要响应点击事件返回NO
- (BOOL)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event location:(CGPoint)location
{
    CFArrayRef lines = CTFrameGetLines(_ctFrame);
    CGPoint origins[CFArrayGetCount(lines)];
    CTFrameGetLineOrigins(_ctFrame, CFRangeMake(0, 0), origins);
    
    CTLineRef line = NULL;
    CGPoint lineOrigin = CGPointZero;
    CGPathRef path = CTFrameGetPath(_ctFrame);
    CGRect rect = CGPathGetBoundingBox(path);
    CGFloat nextLineY = 0;
    for (int i= 0; i < CFArrayGetCount(lines); i++)
    {
        CGPoint origin = origins[i];
        
        CGFloat y = rect.origin.y + rect.size.height - origin.y;
        CTLineRef tempLine = CFArrayGetValueAtIndex(lines, i);
        CGFloat ascend = 0;
        CGFloat decend = 0;
        CGFloat leading = 0;
        CTLineGetTypographicBounds(tempLine, &ascend, &decend, &leading);
        y -= ascend;
        
        if ((location.y >= y) && (location.x >= origin.x))
        {
            
            line = CFArrayGetValueAtIndex(lines, i);
            lineOrigin = origin;
        }
        nextLineY = y + ascend + fabs(decend) + leading;
    }
    if (!line || location.y >= nextLineY) {
        return YES;
    }
    location.x -= lineOrigin.x;
    
    
    CFArrayRef runs = CTLineGetGlyphRuns(line);
    CGFloat lineAscent;
    CGFloat lineDescent;
    CGFloat lineLeading;
    CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, &lineLeading);
    BOOL isClicked = NO;
    for (int j = 0; j < CFArrayGetCount(runs); j++) {
        CTRunRef run = CFArrayGetValueAtIndex(runs, j);
        
        CGFloat ascent, descent, leading;
        
        CGFloat width = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, &leading);
        
        const CGPoint *positions = CTRunGetPositionsPtr(run);
        
        if (nil != positions && location.x <= width + positions[0].x) {
            isClicked = YES;
            break;
        }
        
    }
    if (!isClicked) {
        return NO;
    }
    
    
    CFIndex index = CTLineGetStringIndexForPosition(line, location);
    RTLabelComponent *tempComponent = nil;
    for (RTLabelComponent *component in self.componentsAndPlainText.linkComponents)
    {
        if ((index >= component.position) && (index <= ([component.text length] + component.position)))
        {
            tempComponent = component;
            
        }
    }
    if (tempComponent) {
        self.currentLinkComponent = tempComponent;
        
        return YES;
    }
    else {
        
        // 暂时不必支持图片的可点击响应，tencent:jiachunke(20140619)
       
        return NO;
        
        /*
         for (RTLabelComponent *component in self.componentsAndPlainText.imgComponents)
         {
         if ((index >= component.position) && (index <= ([component.text length] + component.position)))
         {
         tempComponent = component;
         
         }
         }
         if (tempComponent) {
         self.currentImgComponent = tempComponent;
         [self setNeedsDisplay];
         }
         else {
         [super touchesBegan:touches withEvent:event];
         }
         */
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.currentLinkComponent) {
        if ([_delegate respondsToSelector:@selector(rtLabel:didSelectLinkWithURL:)]) {
            [_delegate rtLabel:self didSelectLinkWithURL:[self.currentLinkComponent.attributes objectForKey:@"href"]];
        }
    }
    else if(self.currentImgComponent) {
        // 暂时不必支持图片的可点击响应，tencent:jiachunke(20140619)
        /*
         // 区分link回调，tencent:jiachunke(20140619)
         //if ([_delegate respondsToSelector:@selector(rtLabel:didSelectLinkWithURL:)]) {
         //    [_delegate rtLabel:self didSelectLinkWithURL:[self.currentImgComponent.attributes objectForKey:@"src"]];
         //}
         if ([_delegate respondsToSelector:@selector(rtLabel:didSelectSrcWithURL:)]) {
         [_delegate rtLabel:self didSelectSrcWithURL:[self.currentImgComponent.attributes objectForKey:@"src"]];
         }
         */
    }
    
    [self performSelector:@selector(dismissBoundRectForTouch) withObject:nil afterDelay:0.1];
}

@end
