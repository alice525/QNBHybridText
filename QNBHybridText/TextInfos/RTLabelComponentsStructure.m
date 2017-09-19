//
//  RTLabelComponentsStructure.m
//  richLabel-project
//
//  Created by alice on 14-10-15.
//  Copyright (c) 2014年 alicejhchen. All rights reserved.
//

#import "RTLabelComponentsStructure.h"

@implementation RTLabelComponentsStructure
@synthesize components = components_;
@synthesize plainTextData = plainTextData_;
@synthesize linkComponents = linkComponents_;
@synthesize imgComponents = imgComponents_;

- (void)dealloc {
    self.plainTextData = nil;
    self.components = nil;
    self.linkComponents = nil;
    self.imgComponents = nil;
    [super dealloc];
}

@end



