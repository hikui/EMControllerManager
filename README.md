# EMControllerManager使用说明

## 用途
用于iOS中对UIViewController进行解耦。比如ViewController1需要push ViewController2，标准写法是：

ViewController1:

	#import "ViewController2.h"
	...
	- (void)buttonPushOnTouch:(id)sender {
		...
		ViewController2 *vc2 = [[ViewController2 alloc]init]];
		[self.navigationViewController pushViewController:vc2 animate:YES];
	}
	
此时，ViewController1和ViewController2就是紧密耦合了。不易于复用。

如果使用EMControllerManager，则代码如下：

ViewController1:

	...
	- (void)buttonPushOnTouch:(id)sender {
		...
		EMControllerManager *cm = [EMControllerManager sharedInstance];
		UIViewController *vc2 = [cm createViewControllerInstanceNamed:@"ViewController2" withPropertyValues:@{@"color":[UIColor redColor],@"number":@(1)}]; // 这里的name根据配置文件来，不一定是ViewController2
		[self.navigationViewController pushViewController:vc2 animate:YES];
	}
	
这样一来，ViewController1就不需要知道任何ViewController2的任何信息了。

## 配置文件
配置文件可以是JSON格式，也可以是plist。以JSON格式为例，一个典型的配置文件如下：

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

其中

* `Test1`被成为`Controller Name`，和`createViewControllerInstanceNamed:withPropertyValues:`中的`name`相对应。
* `ClassName`是这个view controller的类名，如果在这边写了一个错误的名称，则create时不能生成对应实体（返回nil）。
* `Description`和`Tag`是辅助字段，可有可无。
* `Dependencies`是依赖关系注入，是个Dictionary，里面的key为目标view controller的一个property，value可以是string, int, float, bool等基本类型，也可以是配置文件里面的另一个`Controller Name`，如本例里面的`"test2ViewController":"Test2"`。**需要注意**：如果希望注入的是一个简单的string，则string必须以'@'开头，否则会被当做配置文件里面的另一个Controller Name。

另外，你也可以使用plist，规则和JSON是一样的。

## 额外配置
除配置文件之外，还可以在程序中动态增加配置。

例如：

	[cm addViewControllerConfigWithBlock:^(NSMutableDictionary *extraNameClassMapping) {
	        
	        EMControllerConfigItem *item1 = [[EMControllerConfigItem alloc]init];
	        item1.controllerClassName = @"Test3ViewController";
	        
	        EMControllerConfigItem *item2 = [[EMControllerConfigItem alloc]init];
	        item2.controllerClass = [Test4ViewController class];
	        
	        [extraNameClassMapping setObject:item1 forKey:@"Test3"];
	        [extraNameClassMapping setObject:item2 forKey:@"Test4"];
	 }];
	 
其中，一个config item中，`controllerClassName`和`controllerClass`必须有其中一个，否则将被视为无效配置。一个config item可以有用Dictionary组成的dependencies，规则和配置文件中一样。

## 使用
典型的使用代码：

	// In application:didFinishLaunchingWithOptions:
	EMControllerManager *cm = [EMControllerManager sharedInstance];
	NSString *path = [[NSBundle mainBundle]pathForResource:@"ViewControllerConfig" ofType:@"json"];
	NSError *e = nil;
	[cm loadConfigFileOfPath:path fileType:EMControllerManagerConfigFileTypeJSON error:&e];
	if (e) {
	    NSLog(@"%@",[e localizedDescription]);
	}
	
	//=======================================================
	
	// In a view controller
	// Initialize properties using two methods
	UIViewController *vc = [cm createViewControllerInstanceNamed:@"Test1" withPropertyValues:@{@"color":[UIColor redColor],@"number":@(1)}];
	
其中，`createViewControllerInstanceNamed:withPropertyValues:`中的`propertyValues`是一个Dictionary，用于对目标controller的property注入。当目标view controller实现了`EMControllerManagerInitProtocol`，则会去调用目标view controller的`initializePropertiesWithDictionary:`方法，否则直接用KVO注入。
