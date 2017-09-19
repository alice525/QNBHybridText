//
//  QLEmotionMap.m
//  live4iphone
//
//  Created by deron on 14-6-6.
//  Copyright (c) 2014年 Tencent Inc. All rights reserved.
//

#import "QLEmotionMap.h"

#pragma mark- Class EMojiInfo
@implementation EMojiInfo
@synthesize emj = _emj,imageName = _imageName,codeID = _codeID,index = _index;

- (void)dealloc
{
    self.emj = nil;
    self.imageName = nil;
    self.codeID = nil;
    self.index =0;
    
    [super dealloc];
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"%@",self.emj];
}

@end


const NSInteger  kEmotionCount = 105;
const NSInteger  KEmojiCount = 60;
const NSInteger  KSymbolCount = 72;

/*表情本地索引（比如索引1对应1.png）*/
const  NSInteger kEmotionLocalIndexArray[kEmotionCount] =
{
    1, 2, 3, 4, 5, 6, 7,
    8, 9, 10, 11, 12, 13, 14,
    15, 16, 17, 18, 19, 20, 21,
    22, 23, 24, 25, 26, 27, 28,
    29, 30, 31, 32, 33, 34, 35,
    36, 37, 38, 39, 40, 41, 42,
    43, 44, 45, 46, 47, 48, 49,
    50, 51, 52, 53, 54, 55, 56,
    57, 58, 59, 60, 61, 62, 63,
    64, 65, 66, 67, 68, 69, 70,
    71, 72, 73, 74, 75, 76, 77,
    78, 79, 80, 81, 82, 83, 84,
    85, 86, 87, 88, 89, 90, 91,
    92, 93, 94, 95, 96, 97, 98,
    99, 100, 101, 102, 103, 104, 105,
    /*
    107, 108, 109, 110, 111, 112, 113,
    114, 115, 116, 117, 118, 119, 120,
    121, 122, 123, 124, 125, 126, 127,
    128, 129, 130, 131, 132, 133, 134,
    135, 136, 137, 138, 139, 140, 141
     */
};

/*表情编码字符*/
const char* kEmotionStringArray[kEmotionCount]=
{
    "[微笑]","[撇嘴]","[色]","[发呆]","[得意]","[流泪]","[害羞]",
    "[闭嘴]","[睡]","[大哭]","[尴尬]","[发怒]","[调皮]","[呲牙]",
    "[惊讶]","[难过]","[酷]","[冷汗]","[抓狂]","[吐]","[偷笑]",
    "[愉快]","[白眼]","[傲慢]","[饥饿]","[困]","[惊恐]","[流汗]",
    
    "[憨笑]","[悠闲]","[奋斗]","[咒骂]","[疑问]","[嘘]","[晕]",
    "[疯了]","[衰]","[骷髅]","[敲打]","[再见]","[擦汗]","[抠鼻]",
    "[鼓掌]","[糗大了]","[坏笑]","[左哼哼]","[右哼哼]","[哈欠]","[鄙视]",
    "[委屈]","[快哭了]","[阴险]","[亲亲]","[吓]","[可怜]","[菜刀]",
    
    "[西瓜]","[啤酒]","[篮球]","[乒乓]","[咖啡]","[饭]","[猪头]",
    "[玫瑰]","[凋谢]","[嘴唇]","[爱心]","[心碎]","[蛋糕]","[闪电]",
    "[炸弹]","[刀]","[足球]","[瓢虫]","[便便]","[月亮]","[太阳]",
    "[礼物]","[拥抱]","[强]","[弱]","[握手]","[胜利]","[抱拳]",
    
    "[勾引]","[拳头]","[差劲]","[爱你]","[NO]","[OK]","[爱情]","[飞吻]",
    "[跳跳]","[发抖]","[怄火]","[转圈]","[磕头]","[回头]","[跳绳]",
    "[投降]","[激动]","[乱舞]","[献吻]","[左太极]","[右太极]"
};

const char* kQQEmotionStringArray[kEmotionCount]=
{
    "/微笑","/撇嘴","/色","/发呆","/得意","/流泪","/害羞",
    "/闭嘴","/睡","/大哭","/尴尬","/发怒","/调皮","/呲牙",
    "/惊讶","/难过","/酷","/冷汗","/抓狂","/吐","/偷笑",
    "/愉快","/白眼","/傲慢","/饥饿","/困","/惊恐","/流汗",
    
    "/憨笑","/悠闲","/奋斗","/咒骂","/疑问","/嘘","/晕",
    "/疯了","/衰","/骷髅","/敲打","/再见","/擦汗","/抠鼻",
    "/鼓掌","/糗大了","/坏笑","/左哼哼","/右哼哼","/哈欠","/鄙视",
    "/委屈","/快哭了","/阴险","/亲亲","/吓","/可怜","/菜刀",
    
    "/西瓜","/啤酒","/篮球","/乒乓","/咖啡","/饭","/猪头",
    "/玫瑰","/凋谢","/嘴唇","/爱心","/心碎","/蛋糕","/闪电",
    "/炸弹","/刀","/足球","/瓢虫","/便便","/月亮","/太阳",
    "/礼物","/拥抱","/强","/弱","/握手","/胜利","/抱拳",
    
    "/勾引","/拳头","/差劲","/爱你","/NO","/OK","/爱情","/飞吻",
    "/跳跳","/发抖","/怄火","/转圈","/磕头","/回头","/跳绳",
    "/投降","/激动","/乱舞","/献吻","/左太极","/右太极"
};

const char* kQQEmotionEngStringArray[kEmotionCount]=
{
    "/::\\)","/::~","/::B","/::\\|","/:8-\\)","/::<","/::\\$",
    "/::X","/::Z","/::'\\(","/::-\\|","/::@","/::P","/::D",
    "/::O","/::\\(","/::\\+","/:--b","/::Q","/::T","/:,@P",
    "/:,@-D","/::d","/:,@o","/::g","/:\\|-\\)","/::!","/::L",
    
    "/::>","/::,@","/:,@f","/::-S","/:\\?","/:,@x","/:,@@",
    "/::8","/:,@!","/:!!!","/:xx","/:bye","/:wipe","/:dig",
    "/:handclap","/:&-\\(","/:B-\\)","/:<@","/:@>","/::-O","/:>-\\|",
    "/:P-\\(","/::'\\|","/:X-\\)","/::\\*","/:@x","/:8\\*","/:pd",
    
    "/:<W>","/:beer","/:basketb","/:oo","/:coffee","/:eat","/:pig",
    "/:rose","/:fade","/:showlove","/:heart","/:break","/:cake","/:li",
    "/:bome","/:kn","/:footb","/:ladybug","/:shit","/:moon","/:sun",
    "/:gift","/:hug","/:strong","/:weak","/:share","/:v","/:@\\)",
    
    "/:jj","/:@@","/:bad","/:lvu","/:no","/:ok","/:love",
    "/:<L>","/:jump","/:shake","/:<O>","/:circle","/:kotow","/:turn",
    "/:skip","/:oY","/:#-0","/:hiphot","/:kiss","/:<&","/:&>"
};

const char* kQQEmotionMatchStringArray[kEmotionCount]=
{
    "/::)","/::~","/::B","/::|","/:8-)","/::<","/::$",
    "/::X","/::Z","/::'(","/::-|","/::@","/::P","/::D",
    "/::O","/::(","/::+","/:--b","/::Q","/::T","/:,@P",
    "/:,@-D","/::d","/:,@o","/::g","/:|-)","/::!","/::L",
    
    "/::>","/::,@","/:,@f","/::-S","/:?","/:,@x","/:,@@",
    "/::8","/:,@!","/:!!!","/:xx","/:bye","/:wipe","/:dig",
    "/:handclap","/:&-(","/:B-)","/:<@","/:@>","/::-O","/:>-|",
    "/:P-(","/::'|","/:X-)","/::*","/:@x","/:8*","/:pd",
    
    "/:<W>","/:beer","/:basketb","/:oo","/:coffee","/:eat","/:pig",
    "/:rose","/:fade","/:showlove","/:heart","/:break","/:cake","/:li",
    "/:bome","/:kn","/:footb","/:ladybug","/:shit","/:moon","/:sun",
    "/:gift","/:hug","/:strong","/:weak","/:share","/:v","/:@)",
    
    "/:jj","/:@@","/:bad","/:lvu","/:no","/:ok","/:love",
    "/:<L>","/:jump","/:shake","/:<O>","/:circle","/:kotow","/:turn",
    "/:skip","/:oY","/:#-0","/:hiphot","/:kiss","/:<&","/:&>"
};
const NSString* emoji_unicode6_table[] =
{
	@"\U0001f603",
	@"\U0001f637",
	@"\U0001f602",
	@"\U0001f61D",
	@"\U0001f632",
	@"\U0001f633",
	@"\U0001f631",
	@"\U0001f614",
	@"\U0001f609",
	@"\U0001f60C",
	@"\U0001f612",
    @"\U0001f618",
    @"\U0001f62D",
	@"\U0001f47F",
	@"\U0001f47B",
    @"\U0001f64F",
	@"\U0001f4AA",
    @"\U0001f44D",
    @"\u270C",
    @"\U0001f385",
    
	@"\U0001F444",
	@"\U0001F483",
	@"\U0001f459",
	@"\U0001f460",
	@"\U0001f48D",
	@"\U0001f48E",
    @"\u2614",
	@"\U0001f302",
	@"\u2600",
	@"\U0001f319",
	@"\U0001f3C1",
	@"\U0001f3CA",
	@"\U0001f3C0",
	@"\u26BD",
	@"\U0001f3C6",
	@"\U0001f3AC",
	@"\U0001f3A4",
	@"\U0001f4FA",
	@"\U0001f3A5",
	@"\U0001f3B5",
    
	@"\U0001f4B0",
	@"\U0001f49D",
    @"\u2764",
	@"\U0001f382",
	@"\U0001f370",
	@"\U0001f381",
	@"\U0001f389",
	@"\U0001f553",
	@"\U0001f384",
	@"\U0001f363",
	@"\U0001f359",
	@"\U0001f354",
	@"\U0001f35F",
	@"\U0001f37A",
    @"\U0001f366",
	@"\U0001f34E",
	@"\U0001f34A",
	@"\U0001f349",
	@"\U0001f353",
	@"\U0001f346",
};


static QLEmotionMap *kInstance = nil;
static NSMutableString *kChangeRex = nil;

@implementation QLEmotionMap

+ (QLEmotionMap*)intance
{
    @synchronized(self){
        if (nil == kInstance) {
            kInstance = [[QLEmotionMap alloc] init];
        }
        
        return kInstance;
    }
}

- (id)init
{
    if (self = [super init]) {
        _emotionLocalIndexArray = [[NSMutableArray alloc] initWithCapacity:kEmotionCount];
        _emotionStringArray = [[NSMutableArray alloc] initWithCapacity:kEmotionCount];
        _QQemotionStringArray = [[NSMutableArray alloc] initWithCapacity:kEmotionCount];
        _QQemotionEnStringArray = [[NSMutableArray alloc] initWithCapacity:kEmotionCount];
        _QQemotionEnMatchStringArray = [[NSMutableArray alloc] initWithCapacity:kEmotionCount];
        _emojiArray =  [[NSMutableArray alloc] initWithCapacity:KEmojiCount];
        _symbolArray = [[NSMutableArray alloc] initWithCapacity:KSymbolCount];
        
        for (NSInteger i=0; i<kEmotionCount; ++i) {
            [_emotionLocalIndexArray addObject:@(kEmotionLocalIndexArray[i])];
            [_emotionStringArray addObject:@(kEmotionStringArray[i])];
            [_QQemotionStringArray addObject:@(kQQEmotionStringArray[i])];
            [_QQemotionEnStringArray addObject:@(kQQEmotionEngStringArray[i])];
            [_QQemotionEnMatchStringArray addObject:@(kQQEmotionMatchStringArray[i])];
        }
        
        [self createEmojiList];
        kChangeRex = [[NSMutableString alloc] init];
        
        for (int k = 1; k <= kEmotionCount; ++k) {
            if (k !=1) {
                [kChangeRex appendFormat:@"|%@",[self emotionQQStringFromLocalIndex:k]];
            }else {
                [kChangeRex appendFormat:@"%@",[self emotionQQStringFromLocalIndex:k]];
            }
        }
        for (int k = 1; k <= kEmotionCount; ++k) {
            [kChangeRex appendFormat:@"|%@",[self emotionQQEnStringFromLocalIndex:k]];
        }
        
        NSArray *textKeys = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"EmotionTextKeys" ofType:@"plist"]];
        
        for(NSString *text in textKeys){
            
            [_symbolArray addObject:text];
        }

    }
    
    return self;
}

- (void)createEmojiList
{
    for(NSUInteger i = 0 ; i < TOTAL_IOS_COUNT; i++){
        
        //emoji_unicode6_table
        NSString* str_u = nil;
        {
            str_u = [NSString stringWithFormat:@"%@",emoji_unicode6_table[i]];
        }
        
        EMojiInfo* info = [[EMojiInfo alloc] init];
        info.index = i;
        info.emj = str_u;
        [_emojiArray addObject:info];
        [info release];
        info = nil;
    }
}

/*localIndex转换成string*/
- (NSString*)emotionStringFromLocalIndex:(NSInteger)localIndex
{
    NSInteger index = [_emotionLocalIndexArray indexOfObject:@(localIndex)];
    if (index != NSNotFound) {
        return _emotionStringArray[index];
    }
    
    return nil;
}
- (NSString*)emotionQQStringFromLocalIndex:(NSInteger)localIndex
{
    NSInteger index = [_emotionLocalIndexArray indexOfObject:@(localIndex)];
    if (index != NSNotFound) {
        return _QQemotionStringArray[index];
    }
    
    return nil;
}
- (NSString*)emotionQQEnStringFromLocalIndex:(NSInteger)localIndex
{
    NSInteger index = [_emotionLocalIndexArray indexOfObject:@(localIndex)];
    if (index != NSNotFound) {
        return _QQemotionEnStringArray[index];
    }
    
    return nil;
}

/*localIndex转换出文件名称*/
- (NSString*)emotionNameFromLocalIndex:(NSInteger)localIndex
{
    NSInteger index = [_emotionLocalIndexArray indexOfObject:@(localIndex)];
    if (index != NSNotFound) {
        return [NSString stringWithFormat:@"Expression_%@.png",_emotionLocalIndexArray[index]];
    }
    
    return nil;
}
/*string转换成localIndex*/
- (NSInteger)emotionLocalIndexFromEmotionString:(NSString*)emotionString
{
    NSInteger index = [_emotionStringArray indexOfObject:emotionString];
    if (index != NSNotFound) {
        return [_emotionLocalIndexArray[index] integerValue];
    }
    
    return -1;
}
- (NSInteger)emotionQQLocalIndexFromEmotionString:(NSString*)emotionString
{
    NSInteger index = [_QQemotionStringArray indexOfObject:emotionString];
    if (index != NSNotFound) {
        return [_emotionLocalIndexArray[index] integerValue];
    }
    
    return -1;
}
- (NSInteger)emotionQQLocalIndexFromEmotionEnString:(NSString*)emotionString
{
    NSInteger index = [_QQemotionEnStringArray indexOfObject:emotionString];
    if (index != NSNotFound) {
        return [_emotionLocalIndexArray[index] integerValue];
    }
    
    return -1;
}
- (NSInteger)emotionQQLocalIndexFromEmotionMatchEnString:(NSString*)emotionString
{
    NSInteger index = [_QQemotionEnMatchStringArray indexOfObject:emotionString];
    if (index != NSNotFound) {
        return [_emotionLocalIndexArray[index] integerValue];
    }
    
    return -1;
}
- (NSArray *)getEmotionStringArray{
    return _emotionStringArray;
}

- (NSArray *)getEmojiArray{
    return _emojiArray;
}
- (NSString*)getEmotionRexString
{
    return kChangeRex;
}

- (NSArray *)getSymBolArray{
    return _symbolArray;
}
@end
