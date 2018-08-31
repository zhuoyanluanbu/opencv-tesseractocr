//
//  ResultViewController.m
//  OpenCV
//
//  Created by Hu Youcheng on 2018/8/28.
//  Copyright © 2018年 com. All rights reserved.
//

#import "ResultViewController.h"
#import <Foundation/Foundation.h>

@interface ResultViewController ()
@end

@implementation ResultViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:(UIColor.whiteColor)];
    if (_image != nil) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(50, 200, 230, 72)];
//        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(50, 50, 230, 502)];
        imageView.image = _image;
        [self.view addSubview:imageView];
    }
    if (_text != nil) {
        UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, 100)];
        [textLabel setText:_text];
        textLabel.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:textLabel];
    }
    
}

@end

