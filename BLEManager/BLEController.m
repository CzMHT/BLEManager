//
//  BLEController.m
//  Bluetooth
//
//  Created by YuanGu on 2017/11/24.
//  Copyright © 2017年 YuanGu. All rights reserved.
//

#import "BLEController.h"
#import "BLEManager.h"

@interface BLEController ()

@property (nonatomic ,strong) BLEManager *manager;
@property (nonatomic ,strong) UITextView *textView;

@end

@implementation BLEController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"BLE";
    
    _manager = [BLEManager shareManager];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    __block NSInteger count = 0;
    
    NSTimer *send = [NSTimer scheduledTimerWithTimeInterval:1.f repeats:YES block:^(NSTimer * _Nonnull timer) {
        
        count ++;
        
        [_manager sendToBBLEWithString:[NSString stringWithFormat:@"xxxxxxxxxxxxxxxxxxxxxxxxxx%d" ,count]];
    }];
}
@end

