//
//  RTLabelComponentsStructure.h
//  richLabel-project
//
//  Created by alice on 14-10-15.
//  Copyright (c) 2014年 alicejhchen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RTLabelComponentsStructure :NSObject {
    NSArray *components_;
    NSString *plainTextData_;
    NSArray *linkComponents_;
    NSArray *imgComponents_;
}
@property(nonatomic,retain) NSArray *components;
@property(nonatomic,retain) NSArray *linkComponents;
@property(nonatomic,retain) NSArray *imgComponents;
@property(nonatomic, copy) NSString *plainTextData;
@end
