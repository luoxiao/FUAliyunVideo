//
//  AliyunUploadViewController.m
//  qusdk
//
//  Created by Worthy on 2017/11/7.
//  Copyright © 2017年 Alibaba Group Holding Limited. All rights reserved.
//

#import "AliyunUploadViewController.h"
#import "AVC_ShortVideo_Config.h"
#import "AliyunPublishTopView.h"
#import "AliyunSVideoApi.h"
#import "AliyunVodPublishService.h"
#import <AVFoundation/AVFoundation.h>
#import <sys/utsname.h>

@interface AliyunUploadViewController () <AliyunPublishTopViewDelegate,AliyunIVodUploadCallback>
@property(nonatomic, strong) AliyunPublishTopView *topView;
@property(nonatomic, strong) UIProgressView *progressView;
@property(nonatomic, strong) UIView *playView;
@property(nonatomic, strong) UILabel *uploadLabel;
@property(nonatomic, strong) UIScrollView *playScrollView; //针对9：16增加滑动视图，解决由于顶部navbar视频显示不全问题
@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) AVPlayer *player;
@property(nonatomic, strong) AVPlayerItem *playerItem;
@property(nonatomic, strong) AVPlayerLayer *playerLayer;

@property(nonatomic, copy) NSString *videoId;
@property(nonatomic, copy) NSString *imageUrl;
@property(nonatomic, assign) BOOL finished;
@end

@implementation AliyunUploadViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setupSubviews];
  [self setupPlayer];
  [AliyunVodPublishService service].uploadCallback = self;
  [self uploadCoverImage];
}

- (void)setupSubviews {
  self.topView = [[AliyunPublishTopView alloc]
      initWithFrame:CGRectMake(0, 0, ScreenWidth, StatusBarHeight + 44)];
  self.topView.nameLabel.text = @"我的视频";
  self.topView.delegate = self;
  self.topView.finishButton.hidden = YES;
  [self.topView.cancelButton setImage:[AliyunImage imageNamed:@"cancel"]
                             forState:UIControlStateNormal];
  [self.topView.cancelButton setTitle:nil forState:UIControlStateNormal];
  [self.view addSubview:self.topView];
  self.view.backgroundColor = [AliyunIConfig config].backgroundColor;

  self.playScrollView = [[UIScrollView alloc]
      initWithFrame:CGRectMake(0, StatusBarHeight + 44, ScreenWidth,
                               ScreenHeight - StatusBarHeight - 44)];
  self.playScrollView.contentSize = CGSizeMake(
      ScreenWidth, ScreenWidth * _videoSize.height / _videoSize.width);
  self.playScrollView.showsHorizontalScrollIndicator = NO;
  [self.view addSubview:self.playScrollView];

  self.playView =
      [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth,
                                               ScreenWidth * _videoSize.height /
                                                   _videoSize.width)];
  [self.playScrollView addSubview:self.playView];

  self.progressView = [[UIProgressView alloc]
      initWithFrame:CGRectMake(0, StatusBarHeight + 44, ScreenWidth, 4)];
  self.progressView.backgroundColor = rgba(0, 0, 0, 0.6);
  self.progressView.progressTintColor =
      [AliyunIConfig config].timelineTintColor;
  [self.view addSubview:self.progressView];

  self.uploadLabel = [[UILabel alloc]
      initWithFrame:CGRectMake((ScreenWidth - 140) / 2,
                               StatusBarHeight + 44 + 24, 140, 32)];
  self.uploadLabel.backgroundColor = rgba(35, 42, 66, 0.5);
  self.uploadLabel.layer.cornerRadius = 2;
  self.uploadLabel.layer.masksToBounds = YES;
  self.uploadLabel.textColor = [UIColor whiteColor];
  [self.uploadLabel setFont:[UIFont systemFontOfSize:14]];
  self.uploadLabel.textAlignment = NSTextAlignmentCenter;
  self.uploadLabel.hidden = YES;
  [self.view addSubview:self.uploadLabel];

  self.titleLabel = [[UILabel alloc]
      initWithFrame:CGRectMake(20,
                               StatusBarHeight + 44 +
                                   (ScreenWidth * _videoSize.height /
                                    _videoSize.width),
                               ScreenWidth - 40, 40)];
  self.titleLabel.text = self.videoTitle;
  self.titleLabel.textColor = [UIColor whiteColor];
  [self.titleLabel setFont:[UIFont systemFontOfSize:12]];
  [self.view addSubview:self.titleLabel];
}

- (void)setupPlayer {
    NSURL *videoUrl = [NSURL fileURLWithPath:_videoPath];
    _playerItem = [[AVPlayerItem alloc] initWithURL:videoUrl];
    _player = [AVPlayer playerWithPlayerItem:_playerItem];
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];

    _playerLayer.frame = self.playView.bounds;
    [self.playView.layer addSublayer:_playerLayer];
    [self addObserver:self forKeyPath:@"_playerItem.status" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];

    _player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationWillResignActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  _playerLayer.frame = self.playView.bounds;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
//强制横屏
-(BOOL)shouldAutorotate{
    return NO;
}

- (void)dealloc {
  [self removeObserver:self forKeyPath:@"_playerItem.status"];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}



#pragma mark - notification

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    AVPlayerItem *p = [notification object];
    [p seekToTime:kCMTimeZero];
}

- (void)appWillEnterForeground:(id)sender {
    [_player play];
}

- (void)appDidEnterBackground:(id)sender {
    [_player pause];
}

#pragma mark - observe

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey, id> *)change
                       context:(void *)context {
  if ([keyPath isEqualToString:@"_playerItem.status"]) {
    AVPlayerItemStatus status = _playerItem.status;
    if (status == AVPlayerItemStatusReadyToPlay) {
      [_player play];
    }
  }
}

#pragma mark - upload

- (void)uploadCoverImage {
  [AliyunSVideoApi getImageUploadAuthWithTitle:@"testtitle"
                         filePath:self.coverImagePath
                             tags:@"testtag"
                          handler:^(NSString *_Nonnull uploadAddress,
                                    NSString *_Nonnull uploadAuth,
                                    NSString *_Nonnull imageURL,
                                    NSString *_Nonnull imageId,
                                    NSError *_Nonnull error) {
                            if (error) {
                              NSLog(@"error:%@", error.description);
                              return;
                            }
                            self.imageUrl = imageURL;
                            [[AliyunVodPublishService service] uploadImageWithPath:self.coverImagePath
                                      uploadAddress:uploadAddress
                                         uploadAuth:uploadAuth];
                          }];
}

- (void)uploadVideo {
  if (!self.videoTitle || [self.videoTitle isEqualToString:@""]) {
    self.videoTitle = @"test video";
  }
  [AliyunSVideoApi getVideoUploadAuthWithWithTitle:self.videoTitle
                             filePath:self.videoPath
                             coverURL:self.imageUrl
                                 desc:@"testdesc"
                                 tags:@"testtag"
                              handler:^(NSString *_Nonnull uploadAddress,
                                        NSString *_Nonnull uploadAuth,
                                        NSString *_Nonnull videoId,
                                        NSError *_Nonnull error) {
                                if (error) {
                                  NSLog(@"error:%@", error.description);
                                  return;
                                }
                                self.videoId = videoId;
                                [[AliyunVodPublishService service] uploadVideoWithPath:self.videoPath
                                          uploadAddress:uploadAddress
                                             uploadAuth:uploadAuth];
                              }];
}

- (void)refreshVideo {
  [AliyunSVideoApi refreshVideoUploadAuthWithVideoId:self.videoId
                                handler:^(NSString *_Nonnull uploadAddress,
                                          NSString *_Nonnull uploadAuth,
                                          NSError *_Nonnull error) {
                                  if (error) {
                                    NSLog(@"error:%@", error.description);
                                    return;
                                  }
                                  [[AliyunVodPublishService service]
                                      refreshWithUploadAuth:uploadAuth];
                                }];
}

#pragma mark - top view delegate

- (void)cancelButtonClicked {
  if (!_finished) {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"正在上传视频，确定要放弃上传吗？"
                                   message:nil
                                  delegate:self
                         cancelButtonTitle:@"取消上传"
                         otherButtonTitles:@"继续上传", nil];
    alert.tag = 101;
    [alert show];
  } else {
    [self.navigationController popToRootViewControllerAnimated:YES];
  }
}

- (void)finishButtonClicked {
}

#pragma mark -alert view delegate

- (void)alertView:(UIAlertView *)alertView
    clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (buttonIndex == 0) {
    if (alertView.tag == 101) {
      [[AliyunVodPublishService service] cancelUpload];
      [self.navigationController popToRootViewControllerAnimated:YES];
    }
  }
}

#pragma mark - vod upload callback

- (void)publishManagerUploadSuccess:(AliyunVodPublishManager *)manager {
  NSLog(@"upload success");
  if (manager.uploadState == AliyunVodUploadImage) {
    [self uploadVideo];
  } else {
    _finished = YES;
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
        dispatch_get_main_queue(), ^{
          _progressView.hidden = YES;
          _uploadLabel.hidden = YES;
        });
  }
}

- (void)publishManager:(AliyunVodPublishManager *)manager uploadFailedWithCode:(NSString *)code message:(NSString *)message
{
    NSLog(@"upload failed code:%@, message:%@", code, message);
    NSString *errMsg =@"";
    if (message && ![message isEqualToString:@""]) {
        NSData *jsonData = [message dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
        errMsg =@"";
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _progressView.hidden = YES;
        _uploadLabel.hidden = YES;
        UIAlertView *alert = [[UIAlertView alloc]
                initWithTitle:[NSString stringWithFormat:@"上传失败\ncode:%@\nmessage:%@", code, message] message:nil
                     delegate:self
            cancelButtonTitle:nil
            otherButtonTitles:@"确定", nil];
        [alert show];
    });
}

- (void)publishManager:(AliyunVodPublishManager *)manager
    uploadProgressWithUploadedSize:(long long)uploadedSize
                         totalSize:(long long)totalSize {
  if (totalSize && manager.uploadState == AliyunVodUploadVideo) {
    dispatch_async(dispatch_get_main_queue(), ^{
      CGFloat progress = uploadedSize / (double)totalSize;
      [_progressView setProgress:progress];
      [self updateUploadLabelWithProgress:progress];
    });
  }
}

- (void)publishManagerUploadTokenExpired:(AliyunVodPublishManager *)manager {
  if (manager.uploadState == AliyunVodUploadImage) {
    [self uploadCoverImage];
  } else {
    [self refreshVideo];
  }
}

- (void)publishManagerUploadRetry:(AliyunVodPublishManager *)manager {
}

- (void)publishManagerUploadRetryResume:(AliyunVodPublishManager *)manager {
}

#pragma mark - util

- (void)updateUploadLabelWithProgress:(CGFloat)progress {
  if (progress < 0) {
    return;
  }
  if (progress < 1) {
    self.uploadLabel.text =
        [NSString stringWithFormat:@"正在上传 %d%%", (int)(progress * 100)];
  } else {
    NSMutableAttributedString *attributedString =
        [[NSMutableAttributedString alloc] initWithString:@"  上传成功"];
    NSTextAttachment *textAttachment = [[NSTextAttachment alloc] init];
    textAttachment.image = [AliyunImage imageNamed:@"icon_upload_success"];
    NSAttributedString *attrStringWithImage =
        [NSAttributedString attributedStringWithAttachment:textAttachment];
    [attributedString replaceCharactersInRange:NSMakeRange(0, 1)
                          withAttributedString:attrStringWithImage];
    self.uploadLabel.attributedText = attributedString;
  }
  _uploadLabel.hidden = NO;
}

@end
