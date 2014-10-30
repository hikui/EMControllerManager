//
//  EMControllerManager.m
//  EMControllerManager
//
//  Created by 缪和光 on 14-7-14.
//  Copyright (c) 2014年 缪和光. All rights reserved.
//

#import "EMControllerManager.h"

static NSString *kEMControllerConfigKeyClassName    = @"ClassName";
static NSString *kEMControllerConfigKeyDescription  = @"Description";
static NSString *kEMControllerConfigKeyDependencies = @"Dependencies";
static NSString *kEMControllerCOnfigKeyTag          = @"Tag";

static NSString *errorDomain = @"EMControllerManagerErrorDomain";

@implementation EMControllerConfigItem @end

@interface EMControllerManager()

@property (nonatomic, strong) NSMutableDictionary *controllerConfigMap;

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
        _controllerConfigMap = [[NSMutableDictionary alloc]init];
    }
    return self;
}

- (BOOL)addConfigFileOfPath:(NSString *)path
                   fileType:(EMControllerManagerConfigFileType)type
                      error:(NSError **)error {
    
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
                    NSError *e = [NSError errorWithDomain:errorDomain code:-1 userInfo:@{@"message":@"JSON file cannot be parsed to a dictionary"}];
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
                    NSError *e = [NSError errorWithDomain:errorDomain code:-1 userInfo:@{@"message":@"Plist file cannot be parsed to a dictionary"}];
                    *error = e;
                }
                return NO;
            }
        }
            break;
        case EMControllerManagerConfigFileTypeYAML:{
            if (!self.yamlAdapter) {
                if (error != NULL) {
                    NSError *e = [NSError errorWithDomain:errorDomain code:-1 userInfo:@{@"message":@"Missing YAML adapter"}];
                    *error = e;
                }
                return NO;
            }
            NSError *e = nil;
            configMapping = [self.yamlAdapter dictionaryFromYAMLData:fileData error:&e];
            if (![configMapping isKindOfClass:[NSDictionary class]]) {
                if (error != NULL) {
                    if (!e) {
                        e = [NSError errorWithDomain:errorDomain code:-1 userInfo:@{@"message":@"YAML file cannot be parsed to a dictionary"}];
                    }
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
    
    if (configMapping) {

        // validate keys and values
        [configMapping enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            
            if (![key isKindOfClass:[NSString class]]) {
                [self notifyInvalidConfigAtKey:[key description]];
                return;
            }
            
            if ([obj isKindOfClass:[NSString class]]) {
                Class aControllerClass = NSClassFromString((NSString *)obj);
                if (aControllerClass == nil) {
                    // The class doesn't exist.
                    [self notifyInvalidConfigAtKey:key];
                    return;
                }
                EMControllerConfigItem *anItem = [[EMControllerConfigItem alloc]init];
                anItem.controllerClass = aControllerClass;
                anItem.classDescription = (NSString *)obj;
                [self.controllerConfigMap setObject:anItem forKey:key];
            }else if([obj isKindOfClass:[NSDictionary class]]){
                NSDictionary *dict = (NSDictionary *)obj;
                NSString *className = dict[kEMControllerConfigKeyClassName];
                Class aControllerClass = nil;
                if (className.length > 0) {
                    aControllerClass = NSClassFromString(className);
                }
                if (aControllerClass == nil) {
                    // The class doesn't exist.
                    [self notifyInvalidConfigAtKey:key];
                    return;
                }
                EMControllerConfigItem *anItem = [[EMControllerConfigItem alloc]init];
                anItem.controllerClass = aControllerClass;
                anItem.classDescription = dict[kEMControllerConfigKeyDescription];
                if (anItem.classDescription.length == 0) {
                    anItem.classDescription = className; // To ensure that it has a value.
                }
                //We don't have to check the validation of the dependencies. Only to check it when we are creating an instance.
                anItem.dependencies = dict[kEMControllerConfigKeyDependencies];
                anItem.tag = [dict[kEMControllerCOnfigKeyTag]integerValue];
                [self.controllerConfigMap setObject:anItem forKey:key];
            }else {
                [self notifyInvalidConfigAtKey:key];
            }
        }];
    }
    if (error != NULL) {
        *error = nil;
    }
    return YES;

}

- (BOOL)loadConfigFileOfPath:(NSString *)path
                    fileType:(EMControllerManagerConfigFileType)type
                       error:(NSError **)error {
    
    [self.controllerConfigMap removeAllObjects];
    return [self addConfigFileOfPath:path fileType:type error:error];
    
}

- (void)removeAllConfiguredClasses {
    [self.controllerConfigMap removeAllObjects];
}

- (id)createViewControllerInstanceNamed:(NSString *)viewControllerName
                     withPropertyValues:(NSDictionary *)keyValueMap {
    
    EMControllerConfigItem *configItem = self.controllerConfigMap[viewControllerName];
    Class aClass = configItem.controllerClass;
    if (aClass == nil && configItem.controllerClassName.length > 0) {
        aClass = NSClassFromString(configItem.controllerClassName);
        configItem.controllerClass = aClass; // Cache the class
    }
    id instance = nil;
    if (aClass) {
        instance = [[aClass alloc]init];
        
        // Inject dependencies into the instance
        // We should notice that a dependent item is not necessarily a configured class, it can be a string, a bool, or a number.
        // However, if a dependent item is a string, it should start with '@', or it would be considered as a configured class name.
        [configItem.dependencies enumerateKeysAndObjectsUsingBlock:^(NSString *propertyName, id obj, BOOL *stop) {
            if (![propertyName isKindOfClass:[NSString class]]) {
                [self notifyInvalidDependencyWithDependencyName:propertyName targetControllerName:viewControllerName];
                return;
            }
            
            if ([obj isKindOfClass:[NSString class]]) {
                // Now that we know it's a string, we should determine if it's a configured class name or a simple string
                NSString *str = (NSString *)obj;
                if ([str hasPrefix:@"@"]) {
                    // it's a simple string, remove "@".
                    if (str.length > 1) {
                        str = [str substringFromIndex:1];
                    }else{
                        str = @"";
                    }
                    
                    [instance setValue:str forKeyPath:propertyName];
                    return;
                }else{
                    NSString *dependentControllerName = str;
                    if ([dependentControllerName isEqualToString:viewControllerName]) {
                        // It's a recursive config, should be omit.
                        NSLog(@"Recursive config, omit.");
                        [self notifyInvalidDependencyWithDependencyName:propertyName targetControllerName:viewControllerName];
                        return;
                    }
                    id dependentViewController = [self createViewControllerInstanceNamed:dependentControllerName withPropertyValues:nil];
                    if (dependentViewController == nil) {
                        [self notifyInvalidDependencyWithDependencyName:propertyName targetControllerName:viewControllerName];
                        return;
                    }
                    
                    if ([instance respondsToSelector:NSSelectorFromString(propertyName)]) {
                        [instance setValue:dependentViewController forKeyPath:propertyName];
                    }
                }
            }else{
                if ([instance respondsToSelector:NSSelectorFromString(propertyName)]) {
                    // To ensure that the existence of a property.
                    [instance setValue:obj forKeyPath:propertyName];
                }
            }
        }];

        
        if ([instance respondsToSelector:@selector(initializePropertiesWithDictionary:)]) {
            [((id<EMControllerManagerInitProtocol> )instance) initializePropertiesWithDictionary:keyValueMap];
        }else{
            [keyValueMap enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
                if ([instance respondsToSelector:NSSelectorFromString(key)]) {
                    [instance setValue:obj forKeyPath:key];
                }
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
        if ([key isKindOfClass:[NSString class]] && [obj isKindOfClass:[EMControllerConfigItem class]]) {
            [self.controllerConfigMap setObject:obj forKey:key];
        }else{
            [self notifyInvalidConfigAtKey:[key description]];
        }
    }];
}

- (void)removeViewControllerName:(NSString *)name {
    [self.controllerConfigMap removeObjectForKey:name];
}

- (void)notifyInvalidConfigAtKey:(NSString *)key {
    NSLog(@"EMControllerManager warning: the key \"%@\" is not valid!",key);
}

- (void)notifyInvalidDependencyWithDependencyName:(NSString *)name
                             targetControllerName:(NSString *)controllerName {
    NSLog(@"EMControllerManager warning: dependency property \"%@\" for \"%@\" is not valid!",name,controllerName);
}

@end
