# The Introduction of EMControllerManager

## Purpose
It's a common scenario that we want to push a view controller inside another view controller. Assume that we have `ViewController1` and `ViewController2`. Now, we want to push `ViewController2` when a button in the `ViewController1` is touched. A standard practice would be:

ViewController1:

	#import "ViewController2.h"
	...
	- (void)buttonPushOnTouch:(id)sender {
		...
		ViewController2 *vc2 = [[ViewController2 alloc]init]];
		[self.navigationViewController pushViewController:vc2 animate:YES];
	}
	
In this situation, `ViewController1` should know the existance of `ViewController2` before it can alloc one. They are tightly coupled and hardly to reuse.

With EMControllerManager, you can write code like:

ViewController1:

	...
	- (void)buttonPushOnTouch:(id)sender {
		...
		EMControllerManager *cm = [EMControllerManager sharedInstance];
		UIViewController *vc2 = [cm createViewControllerInstanceNamed:@"ViewController2" withPropertyValues:@{@"color":[UIColor redColor],@"number":@(1)}]; // The name follows your config file, not necessarily ViewController2.
		[self.navigationViewController pushViewController:vc2 animate:YES];
	}
	
In this way, `ViewController1` doesn't need to know `ViewController2`, and you don't need to import `ViewController2` into `ViewController1.m`

## Configuration
The configuration file can be either a JSON file or a plist file. Take JSON file as an example, a typical configuration code should be like this:

	{
	    "Test1":{
	        "ClassName":"Test1ViewController",
	        "Description":"The homepage of the app",
	        "Tag":"100",
	        "Dependencies":{
	            "dependentString":"@Yes, you can inject a string using the config file",
	            "dependentInt":1000,
	            "dependentBool":true,
	            "test2ViewController":"Test2"
	        }
	    },
	    "Test2":"Test2ViewController"
	}

* `Test1` and `Test2` are controller names. You can name that as you wish. And when you are using `createViewControllerInstanceNamed:withPropertyValues:`, the parameter `Named` should follow this field.
* `ClassName` is the real class name of the view controller. It should match the interface name. If you fill a wrong value to this field, the `createViewControllerInstanceNamed:withPropertyValues:` is impossible to create an instance (will return `nil`), and you will receive a warning, though this won't crash your app.
* `Description` and `Tag` are optional, actually they are just comments (JSON doesn't support comments, so I have to use a redundant field).
* `Dependencies` are something that can be injected into the new instance. It support all basic types that are supported both by JSON and Objective C, e.g. string, int, float, bool. Furthermore, you can inject another controller name that are configured in this file. The manager will create an instance of that class and inject it. However, you should pay attention that if you want to inject a string rather than a configured class reference, you need to add an `'@'` as the prefix, otherwise the string will be recognized as the controller name of another configured class. 

Also, you can use a plist instead, the rules are the same as that for JSON.

## Additional configuration
Besides configuration files, you can also add configurations dynamically in your code.

Here is an example:

	[cm addViewControllerConfigWithBlock:^(NSMutableDictionary *extraNameClassMapping) {
	        
	        EMControllerConfigItem *item1 = [[EMControllerConfigItem alloc]init];
	        item1.controllerClassName = @"Test3ViewController";
	        
	        EMControllerConfigItem *item2 = [[EMControllerConfigItem alloc]init];
	        item2.controllerClass = [Test4ViewController class];
	        
	        [extraNameClassMapping setObject:item1 forKey:@"Test3"];
	        [extraNameClassMapping setObject:item2 forKey:@"Test4"];
	 }];
	 
You create an `EMControllerConfigItem`, then add it into the given mutable dictionary. Notice that you should at least assign one of `controllerClassName` and `controllerClass`. And if `controllerClass` is assigned, then `controllerClassName` will be omited.

Again, you can add dependencies into an item. The rule is the same as above. 

## Usage

A piece of typical code is like

In AppDelegate.m:

	EMControllerManager *cm = [EMControllerManager sharedInstance];
	NSString *path = [[NSBundle mainBundle]pathForResource:@"ViewControllerConfig" ofType:@"json"];
	NSError *e = nil;
	[cm loadConfigFileOfPath:path fileType:EMControllerManagerConfigFileTypeJSON error:&e];
	if (e) {
	    NSLog(@"%@",[e localizedDescription]);
	}

In your view controller:

	// Initialize properties using two methods
	UIViewController *vc = [cm createViewControllerInstanceNamed:@"Test1" withPropertyValues:@{@"color":[UIColor redColor],@"number":@(1)}];
	
`createViewControllerInstanceNamed:withPropertyValues:` will create an instance of a configured class. You can pass a dictionary through `PropertyValues`. How these values are handled depends on the instance. If it conforms the `EMControllerManagerInitProtocol` and responds to `initializePropertiesWithDictionary:`, then this method will be called, otherwise, the values in the dictionary will be injected into the instance directly by KVC.
