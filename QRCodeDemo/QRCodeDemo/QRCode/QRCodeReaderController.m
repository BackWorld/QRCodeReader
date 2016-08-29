//
//  QRCodeReaderController.m
//  QRCodeDemo
//
//  Created by zhuxuhong on 16/8/12.
//  Copyright © 2016年 zhuxuhong. All rights reserved.
//

#import "QRCodeReaderController.h"
#import <AVFoundation/AVFoundation.h>

/**
 nav controller
 */
@implementation QRCodeReaderViewController

-(instancetype)initWithQRDelegate: (id)delegate{
    return [super initWithRootViewController: [[QRCodeReaderController alloc] initWithDelegate:delegate]];
}

-(void)viewDidLoad{
    [super viewDidLoad];
}

-(BOOL)shouldAutorotate{
    return true;
}

// 默认方向
//-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
//    return UIInterfaceOrientationPortrait;
//}

@end


/**
 *  root vc
 */
@interface QRCodeReaderController ()<AVCaptureMetadataOutputObjectsDelegate>

// camera video device
@property(nonatomic, strong)AVCaptureDevice *device;

/**
 *  capture output
 */
@property(nonatomic, strong)AVCaptureMetadataOutput *output;
/**
 *  capture session
 */
@property(nonatomic, strong)AVCaptureSession *session;

@property(nonatomic,weak)id<QRCodeReaderDelegate> delegate;

@end

@implementation QRCodeReaderController
{
    AVCaptureVideoPreviewLayer *preview;
    UIImageView *scanningBox;
    UIView *maskView;
}

-(instancetype)initWithDelegate:(id)delegate{
    if (self = [super init]) {
        _delegate = delegate;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [self barButtonItemWithTitle:@"取消" viewTag:102];
    if ([self isDevicesAvailable] && [self isSuportedSystemVersion]) {// 真机+iOS7
        [self setupCamera];
        [self setupUI];
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    // 指定扫描区域
    [self outputInterestRect];
}

// mask layer
-(void)buildMaskLayer{
    // 挖空层
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    UIBezierPath *rectPath = [UIBezierPath bezierPathWithRect:maskView.bounds];
    if ([self iOS7]) {
        [rectPath appendPath:[[UIBezierPath bezierPathWithRoundedRect:[self scanningBoxFrame] cornerRadius:0] bezierPathByReversingPath]];
    }
    else{
        [rectPath appendPath:[[UIBezierPath bezierPathWithRect:[self scanningBoxFrame]] bezierPathByReversingPath]];
    }
    maskLayer.path = rectPath.CGPath;
    maskView.layer.mask = maskLayer;
}

-(void)outputInterestRect{
    if ([preview.connection isVideoOrientationSupported]){
        preview.connection.videoOrientation = [self videoOrientationFromDeviceOrientation];
    }
    // 坐标转换等在 viewDidAppear里好使
    CGRect interestRect = [preview metadataOutputRectOfInterestForRect: [self scanningBoxFrame]];
    _output.rectOfInterest = interestRect;// 指定扫描区域
//    NSLog(@"rect: %@",NSStringFromCGRect(interestRect));
}

-(CGRect)scanningBoxFrame{
    CGSize size = CGSizeMake(300, 300);
    CGFloat x = preview.bounds.size.width/2 - size.width/2;
    CGFloat y = preview.bounds.size.height/2 - size.height/2;
    return CGRectMake(x, y, 300, 300);
}

/**
 *  setup camera
 */
-(void)setupCamera{
    // 相机
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // input
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:_device error:&error];
    
    // output
    _output = [AVCaptureMetadataOutput new];
    [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    // session
    _session = [AVCaptureSession new];
    _session.sessionPreset = AVCaptureSessionPresetHigh;
    if ([_session canAddInput:input]) {
        [_session addInput:input];
    }
    if ([_session canAddOutput:_output]) {
        [_session addOutput:_output];
    }

    // video preview layer
    preview = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    UIDeviceOrientation orien = [UIDevice currentDevice].orientation;
    CGRect frame = self.view.bounds;
    if ([self iOS7] && (orien == UIDeviceOrientationLandscapeRight || orien == UIDeviceOrientationLandscapeLeft)) {
        frame = CGRectMake(0, 0, frame.size.height, frame.size.width);
    }
    
    preview.frame = frame;
    [self.view.layer insertSublayer:preview atIndex:0];
    
    _output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
    [_session startRunning];
}


-(BOOL)isSuportedSystemVersion{
    BOOL is = [[UIDevice currentDevice].systemVersion floatValue] >= 7.0;
    if (!is) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"系统版本须要7.0以上才行哦" message:nil delegate:nil cancelButtonTitle:@"好吧" otherButtonTitles:nil];
        [alert show];
    }
    return is;
}

-(BOOL)iOS7{
    float version = [[UIDevice currentDevice].systemVersion floatValue];
    return version >= 7.0 && version < 8.0;
}

-(BOOL)isDevicesAvailable{
    if ([[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count] <= 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"你的相机不可用哦" message:nil delegate:nil cancelButtonTitle:@"好吧" otherButtonTitles:nil];
        [alert show];
        return NO;
    }
    
    if([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] == AVAuthorizationStatusDenied) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"你要允许访问摄像机" message:nil delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil];
        [alert show];
        return NO;
    }
    return YES;
}

/**
 *  setup UI
 */
-(void)setupUI{
    self.navigationItem.title = @"扫描IP地址";
    self.navigationController.navigationBar.translucent = false;
    self.view.backgroundColor = [UIColor blackColor];
    
    // 蒙版层
    maskView = [UIView new];
    maskView.frame = preview.bounds;
    maskView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    [self.view addSubview:maskView];
    [self buildMaskLayer];
    
    // 扫描框
    scanningBox = [UIImageView new];
    scanningBox.frame = [self scanningBoxFrame];
    scanningBox.layer.borderColor = [UIColor cyanColor].CGColor;
    scanningBox.layer.borderWidth = 2;
    [self.view addSubview:scanningBox];
    
    // 扫描线
    UIImageView *scanningLine = [UIImageView new];
    scanningLine.frame = CGRectMake(5, 10, 300 - 10, 2);
    scanningLine.backgroundColor = [UIColor orangeColor];
    // 扫描线动画
    [self startScanningLineAnimation:scanningLine];
    [scanningBox addSubview:scanningLine];
    
    // 按钮
    if (_device.isTorchAvailable) {
        self.navigationItem.rightBarButtonItem = [self barButtonItemWithTitle:@"手电筒" viewTag:101];
    }
    
    // 约束
//    [self layoutForScanningBox:scanningBox scanningLine:scanningLine];
    
}

// create button
-(UIButton*)createButtonWithTitle: (NSString*)title viewTag: (NSInteger)tag{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    btn.backgroundColor = [UIColor cyanColor];
    btn.tag = tag;
    [btn addTarget:self action:@selector(buttonDidClick:) forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

// bar button item
-(UIBarButtonItem*)barButtonItemWithTitle: (NSString*)title viewTag: (NSInteger)tag{
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:self action:@selector(buttonDidClick:)];
    item.tag = tag;
    return item;
}

// button click
-(void)buttonDidClick: (UIControl*)sender{
    switch (sender.tag) {
        case 101:
            [self turnOnOffDeviceLight];
            break;
            
        case 102:
            [_session stopRunning];
            [self dismissPageWithReadingResultString:nil];
            break;
            
        default:
            break;
    }
}

// turn on/off device light
-(void)turnOnOffDeviceLight{
    // 开灯
    if(_device.torchMode != AVCaptureTorchModeOn ||
       _device.flashMode != AVCaptureFlashModeOn){
        [_device lockForConfiguration:nil];
        [_device setTorchMode:AVCaptureTorchModeOn];
        [_device setFlashMode:AVCaptureFlashModeOn];
        [_device unlockForConfiguration];
    }
    // 关灯
    else if(_device.torchMode != AVCaptureTorchModeOff ||
            _device.flashMode != AVCaptureFlashModeOff){
        [_device lockForConfiguration:nil];
        [_device setTorchMode:AVCaptureTorchModeOff];
        [_device setFlashMode:AVCaptureFlashModeOff];
        [_device unlockForConfiguration];
    }
}

// 扫描线动画
-(void)startScanningLineAnimation: (UIImageView*)line{
    // 这种动画方式 - present模式下失效
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:2.0];
    [UIView setAnimationRepeatAutoreverses:true];
    [UIView setAnimationRepeatCount: 100000];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    CGRect frame = line.frame;
    frame.origin.y = 290; // 300 - 10 - 10
    line.frame = frame;
    [UIView commitAnimations];
}

// auto layouts
-(void)layoutForScanningBox: (UIView*)box
               scanningLine: (UIView*)line{
    
    box.translatesAutoresizingMaskIntoConstraints = false; // !!!
    line.translatesAutoresizingMaskIntoConstraints = false; // !!!
    [self.view addSubview:box];
    [box addSubview:line];
    
    /**
     *  box
     */
    // center x
    [NSLayoutConstraint constraintWithItem:box attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0].active = true;
    // center y
    [NSLayoutConstraint constraintWithItem:box attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0 constant: -100].active = true;
    // width
    [NSLayoutConstraint constraintWithItem:box attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:300].active = true;
    // height
    [NSLayoutConstraint constraintWithItem:box attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:300].active = true;
    
    /**
     *  line
     */
    // left
    [NSLayoutConstraint constraintWithItem:line attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:box attribute:NSLayoutAttributeLeft multiplier:1.0 constant:5].active = true;
    // top
    [NSLayoutConstraint constraintWithItem:line attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:box attribute:NSLayoutAttributeTop multiplier:1.0 constant:10].active = true;
    // right
    [NSLayoutConstraint constraintWithItem:line attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:box attribute:NSLayoutAttributeRight multiplier:1.0 constant:-5].active = true;
    // height
    [NSLayoutConstraint constraintWithItem:line attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:2].active = true;
}

/**
 *  avcapture delegate
 */
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (metadataObjects.count > 0) {
        NSString *string = [metadataObjects[0] stringValue];
        BOOL respondsSelector = [_delegate respondsToSelector:@selector(qrcodeReaderController:resultForReading:)];
        NSAssert(respondsSelector, @"请实现<QRCodeReaderDelegate>的方法");
        [self dismissPageWithReadingResultString:string];
    }
}

-(void)dismissPageWithReadingResultString: (NSString*)string{
    [_session stopRunning];
    [_delegate qrcodeReaderController:self resultForReading:[string stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]]];
    [self.navigationController dismissViewControllerAnimated:true completion:nil];
}

/**
 *  相机方向
 */
-(AVCaptureVideoOrientation)videoOrientationFromDeviceOrientation {
    UIDeviceOrientation deviceOr = [UIDevice currentDevice].orientation;
    AVCaptureVideoOrientation result = AVCaptureVideoOrientationPortrait;
//    NSLog(@"or: %d",[UIDevice currentDevice].orientation);
    if (deviceOr == UIDeviceOrientationPortrait || deviceOr == UIDeviceOrientationFaceUp) {
        result = AVCaptureVideoOrientationPortrait;
    }
    else if (deviceOr == UIDeviceOrientationPortraitUpsideDown || deviceOr == UIDeviceOrientationFaceDown) {
        result = AVCaptureVideoOrientationPortraitUpsideDown;
    }
    else if (deviceOr == UIDeviceOrientationLandscapeLeft ){
        result = AVCaptureVideoOrientationLandscapeRight;
    }
    else if (deviceOr == UIDeviceOrientationLandscapeRight ){
        result = AVCaptureVideoOrientationLandscapeLeft;
    }
    return result;
}

// 转屏
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    NSLog(@"%@",NSStringFromCGRect(self.view.bounds));
    preview.frame = self.view.bounds;
    maskView.frame = preview.bounds;
    scanningBox.frame = [self scanningBoxFrame];
    [self buildMaskLayer];
    [self outputInterestRect];
}

@end
