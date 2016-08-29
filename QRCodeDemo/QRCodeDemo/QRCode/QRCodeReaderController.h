//
//  QRCodeReaderController.h
//  QRCodeDemo
//
//  Created by zhuxuhong on 16/8/12.
//  Copyright © 2016年 zhuxuhong. All rights reserved.
//

#import <UIKit/UIKit.h>

@class QRCodeReaderController;

// protocol
@protocol QRCodeReaderDelegate <NSObject>

-(void)qrcodeReaderController: (QRCodeReaderController*)qrcodeViewController resultForReading: (NSString*)string;

@end

// nav vc
@interface QRCodeReaderViewController : UINavigationController

-(instancetype)initWithQRDelegate: (id)delegate;

@end


// root vc
@interface QRCodeReaderController : UIViewController
-(instancetype)initWithDelegate: (id)delegate;
@end
