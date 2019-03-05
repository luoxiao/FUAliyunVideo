//
//  AlivcShortVideoUploadManager.m
//  AliyunVideoClient_Entrance
//
//  Created by Zejian Cai on 2018/11/9.
//  Copyright © 2018年 Alibaba. All rights reserved.
//

#import "AlivcShortVideoUploadManager.h"
#import "AliyunPublishService.h"
#import <sys/utsname.h>

@interface AlivcShortVideoUploadManager()<AliyunIUploadCallback>

@property (nonatomic, copy) NSString *coverImagePath;
@property (nonatomic, copy) AliyunUploadSVideoInfo *videoInfo;
@property (nonatomic, assign) AlivcUploadStatus newStatus;

@end

static AlivcShortVideoUploadManager *_instance = nil;

@implementation AlivcShortVideoUploadManager

#pragma mark - 单例

+ (instancetype)shared{
    if (_instance == nil) {
        
        _instance = [[AlivcShortVideoUploadManager alloc] init];
    
    }
    
    return _instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone{
    
    if (_instance == nil) {
        
        _instance = [super allocWithZone:zone];
    }
    
    return _instance;
}

- (id)copy{
    
    return self;
    
}

- (id)mutableCopy{
    
    return self;
    
}

- (id)copyWithZone:(NSZone *)zone{
    
    return self;
    
}

- (id)mutableCopyWithZone:(NSZone *)zone{
    
    return self;
    
}

#pragma Public Method

- (void)setCoverImagePath:(NSString *)imagePath videoInfo:(AliyunUploadSVideoInfo *)videoInfo{
    _coverImagePath = imagePath;
    _videoInfo = videoInfo;
}

- (BOOL)haveUploadSource{
    if (_coverImagePath && _videoInfo) {
        return YES;
    }
    return NO;
}

- (BOOL)startUpload{
    if (![self haveUploadSource]) {
        return NO;
    }
    [self requestSTSWithHandler:^(NSString *keyId, NSString *keySecret, NSString *token, NSString *expireTime, NSError *error) {
        if (error) {
            _newStatus = AlivcUploadStatusFailure;
            if (_managerDelegate && [_managerDelegate respondsToSelector:@selector(uploadManager:uploadStatusChangedTo:)]) {
                [_managerDelegate uploadManager:self uploadStatusChangedTo:AlivcUploadStatusFailure];
            }
            return ;
        }
        [AliyunPublishService service].uploadCallback = self;
        [[AliyunPublishService service] uploadWithImagePath:_coverImagePath svideoInfo:_videoInfo accessKeyId:keyId accessKeySecret:keySecret accessToken:token];
        _newStatus = AlivcUploadStatusUploading;
        if (_managerDelegate && [_managerDelegate respondsToSelector:@selector(uploadManager:uploadStatusChangedTo:)]) {
            [_managerDelegate uploadManager:self uploadStatusChangedTo:AlivcUploadStatusUploading];
        }
    }];
    return YES;
}

- (void)cancelUpload{
    _newStatus = AlivcUploadStatusCancel;
    [[AliyunPublishService service] cancelUpload];
    if (_managerDelegate && [_managerDelegate respondsToSelector:@selector(uploadManager:uploadStatusChangedTo:)]) {
        [_managerDelegate uploadManager:self uploadStatusChangedTo:AlivcUploadStatusCancel];
    }
}

- (AlivcUploadStatus)currentStatus{
    return _newStatus;
}
- (NSString *)coverImagePath{
    return _coverImagePath;
}

#pragma mark - Private Method
- (void)requestSTSWithHandler:(void (^)(NSString *keyId, NSString *keySecret, NSString *token,NSString *expireTime,  NSError * error))handler {
    // 测试用请求地址
    NSString *params = [NSString stringWithFormat:@"BusinessType=vodai&TerminalType=iphone&DeviceModel=%@&UUID=%@&AppVersion=1.0.0", [self getDeviceId], [self getDeviceModel]];
    NSString *testRequestUrl = [NSString stringWithFormat:@"https://demo-vod.cn-shanghai.aliyuncs.com/voddemo/CreateSecurityToken?%@",params];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionTask *task = [session dataTaskWithURL:[NSURL URLWithString:testRequestUrl] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            handler(nil,nil,nil,nil, error);
            return ;
        }
        if (data == nil) {
            NSError *emptyError = [[NSError alloc] initWithDomain:@"Empty Data" code:-10000 userInfo:nil];
            handler(nil,nil,nil,nil, emptyError);
            return ;
        }
        id jsonObj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
        if (error) {
            handler(nil,nil,nil,nil, error);
            return;
        }
        NSDictionary *dict = [jsonObj objectForKey:@"SecurityTokenInfo"];
        NSString *keyId = [dict valueForKey:@"AccessKeyId"];
        NSString *keySecret = [dict valueForKey:@"AccessKeySecret"];
        NSString *token = [dict valueForKey:@"SecurityToken"];
        NSString *expireTime = [dict valueForKey:@"Expiration"];
        if (!keyId || !keySecret || !token || !expireTime) {
            NSError *emptyError = [[NSError alloc] initWithDomain:@"Empty Data" code:-10000 userInfo:nil];
            handler(nil,nil,nil,nil, emptyError);
            return ;
        }
        handler(keyId, keySecret, token, expireTime, error);
    }];
    [task resume];
}

- (NSString *)getDeviceId {
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

- (NSString*)getDeviceModel{
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    return deviceString;
}

#pragma mark - AliyunIUploadCallback

-(void)uploadProgressWithUploadedSize:(long long)uploadedSize
                            totalSize:(long long)totalSize {
    if (totalSize) {
        _newStatus = AlivcUploadStatusUploading;
        if (_managerDelegate && [_managerDelegate respondsToSelector:@selector(uploadManager:updateProgress:)]) {
            CGFloat progressValue = uploadedSize / (double)totalSize;
            [_managerDelegate uploadManager:self updateProgress:progressValue];
        }
    }
}

-(void)uploadTokenExpired {
    [self requestSTSWithHandler:^(NSString *keyId, NSString *keySecret, NSString *token, NSString *expireTime, NSError *error) {
        if (error) {
            [[AliyunPublishService service] cancelUpload];
        }else {
            [[AliyunPublishService service] refreshWithAccessKeyId:keyId accessKeySecret:keySecret accessToken:token expireTime:expireTime];
        }
    }];
}

-(void)uploadFailedWithCode:(NSString *)code message:(NSString *)message {
    NSLog(@"upload failed code:%@, message:%@", code, message);
    dispatch_async(dispatch_get_main_queue(), ^{
        _newStatus = AlivcUploadStatusFailure;
        if (_managerDelegate && [_managerDelegate respondsToSelector:@selector(uploadManager:uploadStatusChangedTo:)]) {
            [_managerDelegate uploadManager:self uploadStatusChangedTo:AlivcUploadStatusFailure];
        }
    });
}

-(void)uploadSuccessWithVid:(NSString *)vid imageUrl:(NSString *)imageUrl {
    NSLog(@"upload success vid:%@, imageurl:%@", vid, imageUrl);
    _newStatus = AlivcUploadStatusSuccess;
    if (_managerDelegate && [_managerDelegate respondsToSelector:@selector(uploadManager:uploadStatusChangedTo:)]) {
        [_managerDelegate uploadManager:self uploadStatusChangedTo:AlivcUploadStatusSuccess];
    }
    _videoInfo = nil;
    _coverImagePath = nil;
    _managerDelegate = nil;
}

-(void)uploadRetry {
    
}

-(void)uploadRetryResume {
    
}




@end
