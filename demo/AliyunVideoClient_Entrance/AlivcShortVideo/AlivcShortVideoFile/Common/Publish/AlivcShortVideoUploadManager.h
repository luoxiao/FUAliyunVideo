//
//  AlivcShortVideoUploadManager.h
//  AliyunVideoClient_Entrance
//
//  Created by Zejian Cai on 2018/11/9.
//  Copyright © 2018年 Alibaba. All rights reserved.
//  上传管理器 - 注意：上传成功之后，设置的上传资源与delegate会被置空

#import <Foundation/Foundation.h>
#import <AliyunVideoSDKPro/AliyunPublishManager.h>

@class AliyunUploadSVideoInfo;
@class AlivcShortVideoUploadManager;

typedef NS_ENUM(NSInteger,AlivcUploadStatus){
    AlivcUploadStatusSuccess = 0,
    AlivcUploadStatusUploading,
    AlivcUploadStatusFailure,
    AlivcUploadStatusCancel,
};

@protocol AlivcShortVideoUploadManagerDelegate <NSObject>

/**
 上传状态回调

 @param manager manager
 @param newStatus 新的状态
 */
- (void)uploadManager:(AlivcShortVideoUploadManager *)manager uploadStatusChangedTo:(AlivcUploadStatus )newStatus;

/**
 上传进度回调

 @param manager manager
 @param progress 0-1
 */
- (void)uploadManager:(AlivcShortVideoUploadManager *)manager updateProgress:(CGFloat )progress;

@end

@interface AlivcShortVideoUploadManager : NSObject

/**
 单例 - 主要为了使用方便和模块间的低耦合

 @return 实例
 */
+ (instancetype)shared;

/**
 设置可以上传的资源
 @param imagePath 封面图片路径
 @param videoInfo 视频信息

 */
- (void)setCoverImagePath:(NSString *)imagePath videoInfo:(AliyunUploadSVideoInfo *)videoInfo;


/**
 本次上传发生事情的回调，是对AliyunIUploadCallback的二次封装
 */
@property (nonatomic, weak) id<AlivcShortVideoUploadManagerDelegate> managerDelegate;


/**
 上传

 @return 开始成功或者失败
 */
- (BOOL)startUpload;

/**
 取消上传
 */
- (void)cancelUpload;


- (AlivcUploadStatus)currentStatus;

- (NSString *)coverImagePath;
@end
