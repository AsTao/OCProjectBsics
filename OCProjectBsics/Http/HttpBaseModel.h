//
//  HttpBaseModel.h
//  AiCommunity
//
//  Created by Tao on 2018/4/13.
//  Copyright © 2018年 NorthStar. All rights reserved.
//


@import Foundation;

@interface HttpBaseModel : NSObject
@property (nonatomic, assign) NSInteger c;
@property (nonatomic, strong) NSString *m;
@property (nonatomic, strong) id d;
- (BOOL)success;
- (BOOL)notLogged;
@end
