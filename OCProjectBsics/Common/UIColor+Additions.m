//
//  UIColor+Ezon.m
//  EzonClient
//
//  Created by Tao on 2018/7/21.
//  Copyright © 2018年 Tao. All rights reserved.
//

#import "UIColor+Additions.h"

@implementation UIColor(OCProjectBsics_Addtions)
- (UIImage *)createImage{
    // 描述矩形
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    
    UIGraphicsBeginImageContext(rect.size);
    // 获取位图上下文
    CGContextRef context = UIGraphicsGetCurrentContext();
    // 使用color演示填充上下文
    CGContextSetFillColorWithColor(context, [self CGColor]);
    // 渲染上下文
    CGContextFillRect(context, rect);
    // 从上下文中获取图片
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    // 结束上下文
    
    return image;
}
@end
