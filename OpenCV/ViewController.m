//
//  ViewController.m
//  OpenCV
//
//  Created by Hu Youcheng on 2018/8/13.
//  Copyright © 2018年 com. All rights reserved.
//

#import "ViewController.h"
#import "ResultViewController.h"
#import "RecogizeCardManager.h"

@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>
@end

@implementation ViewController

AVCaptureSession *session;
AVCapturePhotoOutput *photoOutput;
AVCaptureVideoDataOutput *videoDataOutput;
AVCaptureVideoPreviewLayer *previewLayer;

- (void)viewDidLoad {
    self.times = 0;
    [super viewDidLoad];
    NSError *error = nil;
    session = [AVCaptureSession new];
    //设置session显示分辨率
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        [session setSessionPreset:AVCaptureSessionPreset640x480];
    else
        [session setSessionPreset:AVCaptureSessionPresetPhoto];
    
    // 2 获取摄像头device,并且默认使用的后置摄像头,并且将摄像头加入到captureSession中
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    
    if ([session canAddInput:deviceInput]){
        [session addInput:deviceInput];
    }
    
    //output
    videoDataOutput = [[AVCaptureVideoDataOutput alloc]init];
    NSDictionary *rgbOutputSettings = [NSDictionary dictionaryWithObject:
                                       [NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    [videoDataOutput setVideoSettings:rgbOutputSettings];
    [videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    [videoDataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    if ([session canAddOutput:videoDataOutput]){
        [session addOutput:videoDataOutput];
    }
    
//    [[videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:NO];
    AVCaptureConnection *videoCon = [videoDataOutput connectionWithMediaType:AVMediaTypeVideo];

    // 原来的刷脸没有这句话.因此录制出来的视频是有90度转角的, 这是默认情况
    if ([videoCon isVideoOrientationSupported]) {
        videoCon.videoOrientation = AVCaptureVideoOrientationPortrait;
        // 下面这句是默认系统video orientation情况!!!!,如果要outputsample图片输出的方向是正的那么需要将这里设置称为portrait
        //videoCon.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
    }

    previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    [previewLayer setBackgroundColor:[[UIColor blackColor] CGColor]];
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];// 犹豫使用的aspectPerserve
    CALayer *rootLayer = [[self view] layer];
    [rootLayer setMasksToBounds:YES];
    [previewLayer setFrame:[rootLayer bounds]];
    [rootLayer addSublayer:previewLayer];
    
    [session startRunning];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    self.times++;
    if (self.times % 10 == 0){
        UIImage *image = [self getImageBySampleBufferref:sampleBuffer];
        image = [[RecogizeCardManager recognizeCardManager] opencvScanCard:image];
        image = [self rotate:image rotation:UIImageOrientationLeft];
        [[RecogizeCardManager recognizeCardManager] tesseractRecognizeImage:image compleate:^(NSString* text){
            
            if (text != nil && text != @""){
                text = [text stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                NSUInteger len = [text length];
                if (len == 14) {
                    NSRange rang1 = NSMakeRange(4,1);
                    text = [text stringByReplacingCharactersInRange:rang1 withString:@"-"];
                    NSRange rang2 = NSMakeRange(9,1);
                    text = [text stringByReplacingCharactersInRange:rang2 withString:@"-"];
                    UIAlertController *alertVc =[UIAlertController alertControllerWithTitle:@"识别" message:text preferredStyle:UIAlertControllerStyleAlert];
                    [self presentViewController:alertVc animated:NO completion:nil];
                    NSLog(text);
                    dispatch_async(dispatch_get_main_queue(), ^(){
                        [session stopRunning];
                    });
                }
            }
        }];
//        ResultViewController *rvc = [[ResultViewController alloc]init];
//        rvc.image = image;
//        [self.navigationController pushViewController:(rvc) animated:(YES)];
    
        self.times = 0;
    }

}

- (UIImage *)getImageBySampleBufferref:(CMSampleBufferRef)sampleBuffer {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef newImage = CGBitmapContextCreateImage(newContext);
    CGContextRelease(newContext);
    
    CGColorSpaceRelease(colorSpace);
    UIImage *image= [UIImage imageWithCGImage:newImage scale:1.0 orientation:UIImageOrientationRight];
    NSLog(@"%@", image);
    CGImageRelease(newImage);
    return image;
}

- (UIImage *)rotate:(UIImage *)image rotation:(UIImageOrientation)orientation
{
    long double rotate = 0.0;
    CGRect rect;
    float translateX = 0;
    float translateY = 0;
    float scaleX = 1.0;
    float scaleY = 1.0;
    
    switch (orientation) {
        case UIImageOrientationLeft:
            rotate = M_PI_2;
            rect = CGRectMake(0, 0, image.size.height, image.size.width);
            translateX = 0;
            translateY = -rect.size.width;
            scaleY = rect.size.width/rect.size.height;
            scaleX = rect.size.height/rect.size.width;
            break;
        case UIImageOrientationRight:
            rotate = 33 * M_PI_2;
            rect = CGRectMake(0, 0, image.size.height, image.size.width);
            translateX = -rect.size.height;
            translateY = 0;
            scaleY = rect.size.width/rect.size.height;
            scaleX = rect.size.height/rect.size.width;
            break;
        case UIImageOrientationDown:
            rotate = M_PI;
            rect = CGRectMake(0, 0, image.size.width, image.size.height);
            translateX = -rect.size.width;
            translateY = -rect.size.height;
            break;
        default:
            rotate = 0.0;
            rect = CGRectMake(0, 0, image.size.width, image.size.height);
            translateX = 0;
            translateY = 0;
            break;
    }
    
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    //做CTM变换
    CGContextTranslateCTM(context, 0.0, rect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextRotateCTM(context, rotate);
    CGContextTranslateCTM(context, translateX, translateY);
    
    CGContextScaleCTM(context, scaleX, scaleY);
    //绘制图片
    CGContextDrawImage(context, CGRectMake(0, 0, rect.size.width, rect.size.height), image.CGImage);
    
    UIImage *newPic = UIGraphicsGetImageFromCurrentImageContext();
    
    return newPic;
}

@end
