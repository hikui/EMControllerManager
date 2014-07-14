//
//  EMControllerManager.m
//  EMControllerManager
//
//  Created by 缪和光 on 14-7-14.
//  Copyright (c) 2014年 EastMoney. All rights reserved.
//

#import "EMControllerManager.h"

@interface EMControllerManager()

@property (nonatomic, strong) NSMutableDictionary *controllerNameClassNameMapping;

@end

@implementation EMControllerManager

+ (instancetype)sharedInstance {
    static EMControllerManager *_sharedControllerManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedControllerManager = [[EMControllerManager alloc]init];
    });
    return _sharedControllerManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _controllerNameClassNameMapping = [[NSMutableDictionary alloc]init];
    }
    return self;
}

- (BOOL)loadConfigFileOfPath:(NSString *)path fileType:(EMControllerManagerConfigFileType)type error:(NSError **)error {
    
    static NSString *errorDomain = @"EMControllerManagerErrorDomain";
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]) {
        if (error != NULL) {
            NSError *e = [NSError errorWithDomain:errorDomain code:-1 userInfo:@{@"message":@"config file doesn't exist"}];
            *error = e;
        }
        return NO;
    }
    
    NSData *fileData = [NSData dataWithContentsOfFile:path];
    
    NSDictionary *configMapping = nil;
    
    switch (type) {
        case EMControllerManagerConfigFileTypeJSON:{
            NSError *jsonError = nil;
            configMapping = [NSJSONSerialization JSONObjectWithData:fileData options:0 error:&jsonError];
            if (jsonError) {
                if (error != NULL) {
                    *error = jsonError;
                }
                return NO;
            } else if(![configMapping isKindOfClass:[NSDictionary class]]) {
                if (error != NULL) {
                    NSError *e = [NSError errorWithDomain:errorDomain code:-1 userInfo:@{@"message":@"Your JSON root is not a dictionary"}];
                    *error = e;
                }
                return NO;
            }
        }
            break;
        case EMControllerManagerConfigFileTypePlist:{
            configMapping = [NSDictionary dictionaryWithContentsOfFile:path];
            if (![configMapping isKindOfClass: [NSDictionary class]]) {
                if (error != NULL) {
                    NSError *e = [NSError errorWithDomain:errorDomain code:-1 userInfo:@{@"message":@"Your Plist root is not a dictionary"}];
                    *error = e;
                }
                return NO;
            }
        }
            break;
            
        default: {
            if (error != NULL) {
                NSError *e = [NSError errorWithDomain:errorDomain code:-1 userInfo:@{@"message":@"Unsupported file type"}];
                *error = e;
            }
                
            return NO;
        }
            break;
    }
    
    [self.controllerNameClassNameMapping removeAllObjects];
    if (configMapping) {
        
        // check the validation of keys and values
        [configMapping enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if ([key isKindOfClass:[NSString class]] && [obj isKindOfClass:[NSString class]]) {
                [self.controllerNameClassNameMapping setObject:obj forKey:key];
            }
        }];
    }
    if (error != NULL) {
        *error = nil;
    }
    return YES;
}

- (id)createViewControllerInstanceNamed:(NSString *)viewControllerName withPropertyValues:(NSDictionary *)keyValueMap {
    NSString *className = self.controllerNameClassNameMapping[viewControllerName];
    Class aClass = NSClassFromString(className);
    id instance = nil;
    if (aClass) {
        instance = [[aClass alloc]init];
        if ([instance respondsToSelector:@selector(initializePropertiesWithDictionary:)]) {
            [((id<EMControllerManagerInitProtocol> )instance) initializePropertiesWithDictionary:keyValueMap];
        }else{
            [keyValueMap enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
                [instance setValue:obj forKeyPath:key];
            }];
        }
    }
    return instance;
}

- (void)addViewControllerConfigWithBlock:(void (^)(NSMutableDictionary *extraNameClassMapping))configBlock {
    
    NSMutableDictionary *extraNameClassMapping = [[NSMutableDictionary alloc]init];
    if (configBlock) {
        configBlock(extraNameClassMapping);
    }
    
    [extraNameClassMapping enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([key isKindOfClass:[NSString class]] && [obj isKindOfClass:[NSString class]]) {
            [self.controllerNameClassNameMapping setObject:obj forKey:key];
        }
    }];
}

- (void)removeViewControllerName:(NSString *)name {
    [self.controllerNameClassNameMapping removeObjectForKey:name];
}

@end
