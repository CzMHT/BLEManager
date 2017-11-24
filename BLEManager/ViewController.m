//
//  ViewController.m
//  Bluetooth
//
//  Created by YuanGu on 2017/11/24.
//  Copyright © 2017年 YuanGu. All rights reserved.
//

#import "ViewController.h"
#import "BLEManager.h"
#import "BLEController.h"
#import <CoreBluetooth/CoreBluetooth.h>

static NSString *resueID = @"Identifier";

@interface ViewController ()<BLEManagerProtocol ,UITableViewDelegate ,UITableViewDataSource>

@property (nonatomic ,strong) NSMutableArray *dataArray;
@property (nonatomic ,strong) BLEManager *manager;

@property (nonatomic ,strong) UITableView *TableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _dataArray = [[NSMutableArray alloc] init];
    
    _manager = [BLEManager shareManager];
    _manager.delegate = self;
    
    self.TableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.TableView.delegate = self;
    self.TableView.dataSource = self;
    [self.view addSubview:self.TableView];
    //[self.TableView registerNib:[UINib nibWithNibName:@"cell" bundle:nil] forCellReuseIdentifier:resueID];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"断开" style:UIBarButtonItemStyleDone target:self action:@selector(disConnect)];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)disConnect{
    
    [_manager close];
}

#pragma mark - BLEManagerProtocol

- (void)updateScanBLEResultWith:(NSArray *)result{
    
    _dataArray = [result mutableCopy];
    
    [_TableView reloadData];
}

- (void)connectSuccess{
    
    BLEController *vc = [[BLEController alloc] init];
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)connectClose{
    
    for (int i=0; i<_dataArray.count; i++) {
        
        UITableViewCell *cell = [self.TableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

#pragma mark - UITableViewDelegate ,UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _dataArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:resueID];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:resueID];
    }
    
    CBPeripheral *perioheral = _dataArray[indexPath.row];
    
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.text = perioheral.name;
    
    return cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    CBPeripheral *peripheral = _dataArray[indexPath.row];
    
    [_manager startConnectPeripheral:peripheral];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
}

@end

