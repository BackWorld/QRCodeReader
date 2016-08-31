//
//  ViewController.m
//  QRCodeDemo
//
//  Created by zhuxuhong on 16/8/12.
//  Copyright © 2016年 zhuxuhong. All rights reserved.
//

#import "ViewController.h"
#import "QRCodeReaderController.h"

@interface ViewController ()<QRCodeReaderDelegate>

@end

@implementation ViewController
{
    UIButton *btn;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = CGRectMake(0, 0, 100, 40);
    btn.center = self.view.center;
    [btn setTitle:@"扫描" forState:UIControlStateNormal];
    btn.backgroundColor = [UIColor lightGrayColor];
    [btn addTarget:self action:@selector(scan:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

/**
 * open
 */
-(void)scan: (id)sender{
    QRCodeReaderViewController *vc = [[QRCodeReaderViewController alloc] initWithQRDelegate:self];
    [self presentViewController:vc animated:true completion:nil];
}

// qrcode delegate
-(void)qrcodeReaderController:(QRCodeReaderController *)qrcodeViewController resultForReading:(NSString *)string{
    NSLog(@"mine: %@",string);
}



@end
