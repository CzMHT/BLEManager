//
//  BLEManager.h
//  Bluetooth
//
//  Created by YuanGu on 2017/11/24.
//  Copyright © 2017年 YuanGu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class CBPeripheral;

@protocol BLEManagerProtocol<NSObject>

@optional
- (void)connectSuccess;
- (void)connectClose;
- (void)updateScanBLEResultWith:(NSArray *)result;
@end

@interface BLEManager : NSObject

//单例
+ (BLEManager *)shareManager;

//包括 BLE是否打开 与 是否连接
- (BOOL)getIsConnect;

//获取BLE的名字
- (NSString *)getBLEConnectName;

//连接
- (void)startConnectPeripheral:(CBPeripheral *)ceripheral;

- (void)close;

//开始发送BLE数据
- (void)sendToBBLEWithString:(NSString *)content;

@property (nonatomic ,weak) id<BLEManagerProtocol> delegate;
@end
