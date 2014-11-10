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
    EMControllerManagerConfigFileTypePlist,
    EMControllerManagerConfigFileTypeYAML
};

/**
 YAML Adapter
 
 YAML parser is not supported by system libraries.
 If you want to use YAML configuration files, you need to
 implement this protocol by yourself.
 */
@protocol EMControllerManagerYAMLAdapter <NSObject>

@required
/**
 Parse a YAML file to a dictionary
 
 @param data YAML file data
 @param error Error in parsing
 
 @return result dictionary
 */
- (NSDictionary *)dictionaryFromYAMLData:(NSData *)data error:(NSError **)error;

@end

@protocol EMControllerManagerInitProtocol <NSObject>

@optional
/**
 Init properties after a class being created.
 
 Useful values will be passed in the dict. The receiver can 
 initialize its properties accordingly.
 
 If not implemented, the EMControllerManager will inject 
 values through KVC.
 
 @param dict A dictionary that contains useful values
 */
- (void)initializePropertiesWithDictionary:(NSDictionary *)dict;

@end


@interface EMControllerConfigItem : NSObject

@property (nonatomic, unsafe_unretained) Class controllerClass;
@property (nonatomic, copy) NSString *controllerClassName;
@property (nonatomic, copy) NSString *classDescription;
@property (nonatomic, copy) NSDictionary *dependencies;
@property (nonatomic, unsafe_unretained) NSInteger tag;

@end


@interface EMControllerManager : NSObject

@property (nonatomic, strong) id<EMControllerManagerYAMLAdapter> yamlAdapter;

+ (instancetype)sharedInstance;

/**
 Load the configuration file
 
 The configuration file must be a JSON file or a plist file.
 
 Note that this method will override all configured classes.
 
 A typical JSON config file example:
 
     {
        "Test1":{
            "ClassName":"Test1ViewController",
            "Description":"hahahahahhahaha",
            "Tag":"100",
            "Dependencies":{
                "dependentString":"@hahahahahah",
                "dependentInt":1000,
                "dependentBool":true,
                "test2ViewController":"Test2"
            }
        },
        "Test2":"Test2ViewController"
     }
 
 @param path  The path of the configuration file.
 @param type  The type of the configuration file. There are two possible values.
 @param error If an error occured (e.g. file not exist or parsing JSON failed), the detailed error information will pass throungh this parameter.
 
 @return Return YES, if there's no problem. Return NO, if some problems occured during loading.
 */
- (BOOL)loadConfigFileOfPath:(NSString *)path
                    fileType:(EMControllerManagerConfigFileType)type
                       error:(NSError **)error;

/**
 Add configuration from a file.
 
 This won't override your old configuration, and allows you to load multiple config files in one app.
 
 @param path  The path of the configuration file.
 @param type  The type of the configuration file. There are two possible values.
 @param error If an error occured (e.g. file not exist or parsing JSON failed), the detailed error information will pass throungh this parameter.
 
 @return Return YES, if there's no problem. Return NO, if some problems occured during loading.
 */
- (BOOL)addConfigFileOfPath:(NSString *)path
                   fileType:(EMControllerManagerConfigFileType)type
                      error:(NSError **)error;

/**
 To cleanup the mapping.
 */
- (void)removeAllConfiguredClasses;

/**
 Create an instance according the view controller's name.
 
 @param viewControllerName The view controller's name, which you configured before.
 @param keyValueMap        Values of this dictionary will be set into the properties of the target view controller according to keys. Note that if the target view controller responds the `initializePropertiesWithDictionary:` selector, then this method will be called. Otherwise, values will be set using KVO.
 
 @return An instance of view controller.
 */
- (UIViewController *)createViewControllerInstanceNamed:(NSString *)viewControllerName withPropertyValues:(NSDictionary *)keyValueMap;

/**
 Get the class of a specific view controller.
 
 @param viewControllerName The name of the view controller that you configured.
 
 @return The class of the view controller. Return nil if not found.
 */
- (Class)classOfViewControllerNamed:(NSString *)viewControllerName;

/**
 To add the extra view controller configuration.
 
 Example:
 
     [cm addViewControllerConfigWithBlock:^(NSMutableDictionary *extraNameClassMapping) {
            
            EMControllerConfigItem *item1 = [[EMControllerConfigItem alloc]init];
            item1.controllerClassName = @"Test3ViewController";
            
            EMControllerConfigItem *item2 = [[EMControllerConfigItem alloc]init];
            item2.controllerClass = [Test4ViewController class];
            
            [extraNameClassMapping setObject:item1 forKey:@"Test3"];
            [extraNameClassMapping setObject:item2 forKey:@"Test4"];
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
