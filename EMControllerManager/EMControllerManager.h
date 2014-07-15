//
//  EMControllerManager.h
//  EMControllerManager
//
//  Created by 缪和光 on 14-7-14.
//  Copyright (c) 2014年 缪和光. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, EMControllerManagerConfigFileType) {
    EMControllerManagerConfigFileTypeJSON,
    EMControllerManagerConfigFileTypePlist
};


@protocol EMControllerManagerInitProtocol <NSObject>

@optional
- (void)initializePropertiesWithDictionary:(NSDictionary *)dict;

@end


@interface EMControllerConfigItem : NSObject

@property (nonatomic, unsafe_unretained) Class controllerClass;
@property (nonatomic, copy) NSString *controllerClassName;
@property (nonatomic, copy) NSString *description;
@property (nonatomic, copy) NSDictionary *dependencies;
@property (nonatomic, unsafe_unretained) NSInteger tag;

@end


@interface EMControllerManager : NSObject

+ (instancetype)sharedInstance;

/**
 Load the configuration file
 
 The configuration file must be a JSON file or a plist file.
 
 A typical JSON config file example:
 
     {
        "VCName1":"ViewControllerClassName1",
        "VCName1":"ViewControllerClassName1",
     }
 
 @param path  The path of the configuration file.
 @param type  The type of the configuration file. There are two possible values.
 @param error If an error occured (e.g. file not exist or parsing JSON failed), the detailed error information will pass throungh this parameter.
 
 @return Return YES, if there's no problem. Return NO, if some problems occured during loading.
 */
- (BOOL)loadConfigFileOfPath:(NSString *)path fileType:(EMControllerManagerConfigFileType)type error:(NSError **)error;

/**
 Create an instance according the view controller's name.
 
 @param viewControllerName The view controller's name, which you configured before.
 @param keyValueMap        Values of this dictionary will be set into the properties of the target view controller according to keys. Note that if the target view controller responds the `initializePropertiesWithDictionary:` selector, then this method will be called. Otherwise, values will be set using KVO.
 
 @return An instance of view controller.
 */
- (UIViewController *)createViewControllerInstanceNamed:(NSString *)viewControllerName withPropertyValues:(NSDictionary *)keyValueMap;

/**
 To add the extra view controller configuration.
 
 Example:
 
     [cm addViewControllerConfigWithBlock:^(NSMutableDictionary *extraNameClassMapping) {
            [extraNameClassMapping setObject:@"Test3ViewController" forKey:@"Test3"];
            [extraNameClassMapping setObject:NSStringFromClass([Test4ViewController class]) forKey:@"Test4"];
     }];
 
 Notice the second approach, it is a better practice because it can be treated properly when you are renaming the class with Xcode's refactor tool.
 
 @param configBlock block
 */
- (void)addViewControllerConfigWithBlock:(void (^)(NSMutableDictionary *extraNameClassMapping))configBlock;


/**
 To remove a view controller setting.
 
 @param name view controller's name.
 */
- (void)removeViewControllerName:(NSString *)name;

@end