//
//  Test1ViewController.h
//  EMControllerManager
//
//  Created by 缪和光 on 14-7-14.
//  Copyright (c) 2014年 EastMoney. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Test2ViewController;

@interface Test1ViewController : UIViewController

@property (nonatomic, strong) UIColor *color;
@property (nonatomic, unsafe_unretained) NSInteger number;

@property (nonatomic, copy) NSString *dependentString;
@property (nonatomic, unsafe_unretained) BOOL dependentBool;
@property (nonatomic, unsafe_unretained) NSInteger dependentInt;

@property (nonatomic, strong) Test2ViewController *test2ViewController;

@end
