//
//  BLEManager.m
//  Bluetooth
//
//  Created by YuanGu on 2017/11/24.
//  Copyright © 2017年 YuanGu. All rights reserved.
//

#import "BLEManager.h"
#import "BLEAssist.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface BLEManager()<CBCentralManagerDelegate ,CBPeripheralDelegate>{
    NSMutableData  *_receiveData; //接收数据 的 存储
}

@property (nonatomic ,strong) NSMutableArray    *BLEArray;
@property (nonatomic ,strong) NSString          *blueName;
@property (nonatomic ,strong) CBCentralManager  *central;
@property (nonatomic ,strong) CBPeripheral      *peripheral;
@property (nonatomic ,strong) CBCharacteristic  *characteristic;
@end

@implementation BLEManager

+ (BLEManager *)shareManager{
    
    static BLEManager *manager;
    static dispatch_once_t predicate;
    
    dispatch_once(&predicate, ^{
        manager = [[BLEManager alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        _receiveData = [[NSMutableData  alloc] init];
        
        _BLEArray = [[NSMutableArray alloc] init];
        
        self->_central = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
    }
    return self;
}

#pragma mark - Property

- (NSString *)getBLEConnectName{
    return self->_blueName;
}
- (BOOL)getIsConnect{
    if (_peripheral && _characteristic) {
        return YES;
    }
    
    return NO;
}
- (void)sendToBBLEWithString:(NSString *)content{
    
    //发送数据 转化为 data UTF8 格式
    NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];
    
    if (_characteristic && _peripheral){
        
        [_peripheral writeValue:data
              forCharacteristic:_characteristic
                           type:CBCharacteristicWriteWithResponse];
    }
}
- (void)startScanPeripheral{
    //这里如果出现 后台 连接不上的情况 ,需要针对特定服务去扫描
    [self->_central scanForPeripheralsWithServices:nil
                                           options:nil]; //@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES}];
}

- (void)close{
    
    if (_peripheral && _characteristic) [_central cancelPeripheralConnection:_peripheral];
}

- (void)startConnectPeripheral:(CBPeripheral *)ceripheral{
    
    [_central connectPeripheral:ceripheral options:nil];
}

#pragma mark - Action
/**
 * d    计算所得距离
 * RSSI 接收信号强度（负值）
 * A    发射端和接收端相隔1米时的信号强度  可以赋予:59
 * n    环境衰减因子  默认:2.0
 */
- (float)calculateDistanceWithRSSI:(int)rssi{
    
    int iRssi = abs(rssi);
    
    float power = (iRssi-59)/(10*2.0);
    
    return pow(10, power);
}

//清除
- (void)cleanup{
    
    // 如果没有连接则退出
    if (_peripheral.state != CBPeripheralStateConnected)  return;
    
    // 判断是否已经预定了特征
    if (_peripheral.services != nil) {
        
        for (CBService *service in _peripheral.services) {
            
            if (service.characteristics != nil) {
                
                for (CBCharacteristic *characteristic in service.characteristics) {
                    
                    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"FFE1"]]) {
                        
                        if (characteristic.isNotifying) {
                            
                            //停止接收特征通知
                            [_peripheral setNotifyValue:NO forCharacteristic:characteristic];
                            //断开与外设连接
                            [_central cancelPeripheralConnection:_peripheral];
                            
                            return;
                        }
                    }
                }
            }
        }
    }
    
    //断开与外设连接
    [_central cancelPeripheralConnection:_peripheral];
}

- (void)dealloc{
    [_central cancelPeripheralConnection:_peripheral];
}

#pragma mark - CBCentralManagerDelegate

//调用初始化执行的代理
//self->_central = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];回调
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    
    // Fallback on earlier versions
    if (central.state != CBCentralManagerStatePoweredOn) {
        
        NSLog(@"蓝牙 未开启");
        
        if(central.state == CBCentralManagerStatePoweredOff){
            
            _peripheral = nil;
            _characteristic = nil;
        }
    }else{
        NSLog(@"蓝牙 开启 ,开始扫描");
        
        [self startScanPeripheral];
    }
}

//调用 scanForPeripheralsWithServices... 执行的代理
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI{
    
    //NSLog(@"%s, line = %d, cetral = %@,peripheral = %@, advertisementData = %@, RSSI = %@", __FUNCTION__, __LINE__, central, peripheral, advertisementData, RSSI);

    //RSSI 是信号强度的 显式表现
    if (![_BLEArray containsObject:peripheral]) {
        
        NSLog(@"name:%@ UUID:%@ advertisementData:%@" ,peripheral.name ,peripheral.identifier.UUIDString ,advertisementData);
        
        [_BLEArray addObject:peripheral];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(updateScanBLEResultWith:)]) {
            [self.delegate updateScanBLEResultWith:_BLEArray];
        }
    }
}

//蓝牙连接成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    
    _peripheral = peripheral;
    
    //设置外设对象的委托为self
    _peripheral.delegate = self;
    //重置data属性
    [_receiveData setLength:0];
    //查找外设提供的,服务
    [_peripheral discoverServices:nil];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(connectSuccess)]) {
        [self.delegate connectSuccess];
    }
}

//蓝牙连接失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error{
    NSLog(@"连接蓝牙失败");
}

//蓝牙 断开
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error{
    if (peripheral == _peripheral) {
        
        _peripheral = nil;
        _characteristic = nil;
        
        NSLog(@"蓝牙断开成功");
    }
    
    if ([self.delegate respondsToSelector:@selector(connectClose)]) {
        [self.delegate connectClose];
    }
}

#pragma mark - CBPeripheralDelegate
//发现服务成功
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    
    if (error) {
        
        NSLog(@"Error discovering services: %@", [error localizedDescription]);
        
        [self cleanup];
    }else{
        //发现 特征
        for (CBService *service in peripheral.services) {
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
}
//发现特征成功
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    
    if (error) {
        NSLog(@"发现特征错误: %@", [error localizedDescription]);
        
        [self cleanup];
    }else{
        
        for ( CBCharacteristic *characteristic in service.characteristics) {
            
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            
            if ([characteristic.UUID.UUIDString isEqualToString:@"AF0BADB1-5B99-43CD-917A-A77BC549E3CC"]) {
                _characteristic = characteristic;
            }
        }
    }
}
//特征通知状态发生变化
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    
    if (error)  NSLog(@"特征通知状态变化错误: %@", error.localizedDescription);
    
    NSLog(@"特征值发生变化");
}
//特征值发生变化
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    
    if (error) {
        
        NSLog(@"发现特征错误:: %@", [error localizedDescription]);
    }else{
        
        NSLog(@"接收到 BLE 返回数据");
        
        [_receiveData appendData:characteristic.value];
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            NSString *receiveStrA = [BLEAssist getStringWithReceived:characteristic.value];
            NSString *receiveStrB = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
            NSString *receiveStr  = [[NSString alloc] initWithData:_receiveData encoding:NSUTF8StringEncoding];
            
            NSLog(@"receiveStrA:%@ ,receiveStrB:%@ \nreceiveStr:%@" ,receiveStrA ,receiveStrB ,receiveStr);
        });
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
    
    NSLog(@"%@" ,error);
}


@end
