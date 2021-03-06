//
//  NSString+Additions.h
//  AiCommunity
//
//  Created by Tao on 2018/4/12.
//  Copyright © 2018年 NorthStar. All rights reserved.
//

@import Foundation;
@import CoreGraphics;
@import UIKit;

@interface NSString (OCProjectBsics_Addtions)
- (CGSize)sizeCalculate:(UIFont *)font width:(CGFloat )width;
- (NSString *)md5;
///@"yyyy-MM-dd"
- (NSString *)dateFormat:(NSString *)format;

///@"yyyy-MM-dd HH:mm:ss"
- (NSDate *)dateFromString:(NSString *)format;
@end
