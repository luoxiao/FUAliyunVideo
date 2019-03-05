//
//  AppDelegate.m
//  AliyunVideoClient_Entrance
//
//  Created by Zejian Cai on 2018/3/22.
//  Copyright © 2018年 Alibaba. All rights reserved.
//

#import "AppDelegate.h"
#import "AlivcHomeViewController.h"
#import "AlivcBaseNavigationController.h"
#import "UIImage+AlivcHelper.h"
//crash collect
#import <AliHAAdapter4Cloud/AliHAAdapter.h>
#import <TBCrashReporter/TBCrashReporter.h>
#import <UT/UTAnalytics.h>

#import <AliyunVideoSDKPro/AliyunVideoSDKPro.h>


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // Override point for customization after application launch.
    [[UIApplication sharedApplication] setStatusBarHidden:NO]; 
    // 初始化根视图控制器
    self.window = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
    
    AlivcHomeViewController *vc_root = [[AlivcHomeViewController alloc]init];
    
    AlivcBaseNavigationController *nav_root = [[AlivcBaseNavigationController alloc]initWithRootViewController:vc_root];
    //导航栏设置
    [self setBaseNavigationBar:nav_root];
    self.window.rootViewController = nav_root;
    [self.window makeKeyAndVisible];
    [self redirectNSlogToDocumentFolder];    //crash init
    [self initCrash];
    return YES;
}


- (void)redirectNSlogToDocumentFolder
{
    [AliyunVideoSDKInfo setLogLevel:AlivcLogVerbose];
    NSArray *paths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *documentDirectory = [paths objectAtIndex:0];
    NSString *fileName = [NSString stringWithFormat:@"app.log"];
    NSString *logFilePath = [documentDirectory stringByAppendingPathComponent:fileName];
    //先删除已经存在的文件
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    [defaultManager removeItemAtPath:logFilePath error:nil];
    // 将log输入到文件
    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding],"a+", stdout);
    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding],"a+", stderr);
}



- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window{
    
    UINavigationController *navigationController = (id)self.window.rootViewController;
    if ([navigationController isKindOfClass:[UINavigationController class]]) {
        return [navigationController.visibleViewController supportedInterfaceOrientations];
    }
    return navigationController.supportedInterfaceOrientations;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    NSLog(@"\n ===> 程序暂停 !");
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    NSLog(@"\n ===> 进入后台 ！");
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


#pragma mark - Public Method
- (void)initCrash{
    NSString *appKey = @"25283053"; //appId
    NSString *secret = @"6e276ca1bc62ab79aa8ff5cc1a4f92df"; //appSecret
    NSString *channel = @"Aliyun"; //渠道标记
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];//app版本
    [[UTAnalytics getInstance] setAppKey:appKey secret:secret];
    [[UTAnalytics getInstance] setChannel:channel];
    [[UTAnalytics getInstance] setAppVersion:appVersion];
    id<AliHAPluginProtocol> crashPlugin = [TBCrashReporter sharedReporter];
    NSArray<id<AliHAPluginProtocol>> *plugins = @[crashPlugin];
    [AliHAAdapter initWithAppKey:appKey appVersion:appVersion channel:channel plugins:
     plugins nick:nil];
}

/**
 导航栏设置，全局有效
 */
- (void)setBaseNavigationBar:(UINavigationController *)nav{
    //
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    
    [nav.navigationBar setBackgroundImage:[UIImage avc_imageWithColor:[AlivcUIConfig shared].kAVCBackgroundColor] forBarMetrics:UIBarMetricsDefault];
    [nav.navigationBar setShadowImage:[UIImage new]];
    nav.navigationBar.tintColor = [UIColor whiteColor];
    [nav.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
}


@end
