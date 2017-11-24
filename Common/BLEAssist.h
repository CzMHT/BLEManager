//
//  BLEAssist.h
//  Bluetooth
//
//  Created by YuanGu on 2017/11/24.
//  Copyright © 2017年 YuanGu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BLEAssist : NSObject

+ (NSString *)getStringWithReceived:(NSData *)data;
    
@end
