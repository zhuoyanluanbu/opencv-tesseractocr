//
//  RecogizeCardManager.h
//  OpenCV
//
//  Created by Hu Youcheng on 2018/8/27.
//  Copyright © 2018年 com. All rights reserved.
//

#import <Foundation/Foundation.h>
@class UIImage;

typedef void (^CompleateBlock)(NSString *text);

@interface RecogizeCardManager : NSObject

+ (instancetype)recognizeCardManager;

- (void)recognizeCardWithImage:(UIImage *)cardImage compleate:(CompleateBlock)compleate;

- (UIImage *)opencvScanCard:(UIImage *)image;

- (void)tesseractRecognizeImage:(UIImage *)image compleate:(CompleateBlock)compleate;
@end
