//
//  BLEAssist.m
//  Bluetooth
//
//  Created by YuanGu on 2017/11/24.
//  Copyright © 2017年 YuanGu. All rights reserved.
//

#import "BLEAssist.h"

@implementation BLEAssist


+ (NSString *)getStringWithReceived:(NSData *)data{
    
    if (!data) return nil;
    
    Byte *bytes = (Byte *)[data bytes];
    
    //获得16进制的字符串
    NSString *string = [[NSString alloc] init];
    
    for (int i=0; i<data.length; i++) {
        
        NSString *newHexStr = [NSString stringWithFormat:@"%x",bytes[i]&0xff];///16进制数
        
        //进行数据拼接
        if([newHexStr length] == 1) newHexStr = [@"0" stringByAppendingString:newHexStr];
        
        string = [string stringByAppendingString:newHexStr];
    }
    
    if (string.length < 2) return @"";
    
    //把16进制的字符串进行转换
    char *myBuffer = (char *)malloc((int)[string length] / 2 + 1);
    
    bzero(myBuffer, [string length] / 2 + 1);
    
    for (int i = 0; i < [string length] - 1; i += 2) {
        
        unsigned int anInt;
        
        NSString * hexCharStr = [string substringWithRange:NSMakeRange(i, 2)];
        
        NSScanner * scanner = [[NSScanner alloc] initWithString:hexCharStr];
        
        [scanner scanHexInt:&anInt];
        
        myBuffer[i / 2] = (char)anInt;
    }
    
    NSString *csStr = [NSString stringWithCString:myBuffer encoding:4];
    
    return (!csStr) ? @"": csStr;
}

@end
