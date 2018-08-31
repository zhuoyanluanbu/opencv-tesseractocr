//
//  RecogizeCardManager.m
//  OpenCV
//
//  Created by Hu Youcheng on 2018/8/27.
//  Copyright © 2018年 com. All rights reserved.
//
#import "RecogizeCardManager.h"
#import <opencv2/opencv.hpp>
#import <opencv2/imgproc/types_c.h>
#import <opencv2/imgcodecs/ios.h>
#import <TesseractOCR/TesseractOCR.h>

@implementation RecogizeCardManager

+ (instancetype)recognizeCardManager {
    static RecogizeCardManager *recognizeCardManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        recognizeCardManager = [[RecogizeCardManager alloc] init];
    });
    return recognizeCardManager;
}

- (void)recognizeCardWithImage:(UIImage *)cardImage compleate:(CompleateBlock)compleate {
    
}

//opencv处理图片
- (UIImage *)opencvScanCard:(UIImage *) image {
    cv::Mat resultImage;
    UIImageToMat(image, resultImage);
    //转化为灰度
    cv::cvtColor(resultImage, resultImage, cv::COLOR_BGR2GRAY);
    //利用阈值二值化
    cv::threshold(resultImage, resultImage, 120, 240, CV_THRESH_BINARY);
    //腐蚀，填充（腐蚀是让黑色点变大）
    cv::Mat erodeElement = getStructuringElement(cv::MORPH_RECT,cv::Size(14,14));
    cv::erode(resultImage,resultImage,erodeElement);
    //轮廊检测
    std::vector<std::vector<cv::Point>> contours;//定义一个容器来存储所有检测到的轮廊
    cv::findContours(resultImage, contours, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE, cvPoint(0, 0));
    //取出想要的区域
    std::vector<cv::Rect> rects;
    cv::Rect numberRect = cv::Rect(0,0,0,0);
    std::vector<std::vector<cv::Point>>::const_iterator itContours = contours.begin();
    for ( ; itContours != contours.end(); ++itContours) {
        cv::Rect rect = cv::boundingRect(*itContours);
        rects.push_back(rect);
        printf("width:%d , height:%d , divide:%f \n",rect.width,rect.height,((double)rect.height)/(double)rect.width);
        //这里需要把指定的rect筛选出来，可以用宽高值来检测
        if ( ((double)rect.height)/(double)rect.width <= 5 &&
            ((double)rect.height)/(double)rect.width >= 2.5 && rect.width >=25 && rect.width <= 45) {
            numberRect = rect;
            break;
        }
    }
    if (numberRect.width == 0 || numberRect.height == 0) {
        return nil;
    }
    cv::Mat matImage;
    UIImageToMat(image, matImage);
    resultImage = matImage(numberRect);
    cvtColor(resultImage, resultImage, cv::COLOR_BGR2GRAY);
    cv::threshold(resultImage, resultImage, 80, 255, CV_THRESH_BINARY);
    
    cv::Mat kernel(3,3,CV_32F,cv::Scalar(0));
    kernel.at<float>(1,1) = 3.6;
//    kernel.at<float>(0,1) = -1.0;
//    kernel.at<float>(1,0) = -1.0;
//    kernel.at<float>(1,2) = -1.0;
//    kernel.at<float>(2,1) = -1.0;
    cv::filter2D(resultImage, resultImage, resultImage.depth(), kernel);
    //将Mat转换成UIImage
    MatToUIImage(resultImage);

//    return numberImage;
    return MatToUIImage(resultImage);
}

//TesseractOCR识别文字
- (void)tesseractRecognizeImage:(UIImage *)image compleate:(CompleateBlock)compleate {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        G8Tesseract *tesseract = [[G8Tesseract alloc] initWithLanguage:@"num_sxe"];
        tesseract.image = [image g8_blackAndWhite];
//        tesseract.image = image;
        // Start the recognition
        [tesseract recognize];
//        printf("识别的文字：%s",tesseract.recognizedText);
        //执行回调
        compleate(tesseract.recognizedText);
    });
}


@end

