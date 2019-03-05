//
//  AVC_ET_HomeViewController.m
//  AliyunVideoClient_Entrance
//
//  Created by Zejian Cai on 2018/3/22.
//  Copyright © 2018年 Alibaba. All rights reserved.
//

#import "AlivcHomeViewController.h"
#include <sys/param.h>
#include <sys/mount.h>

#import "AVC_ET_ModuleItemCCell.h"
#import "AVC_ET_ModuleDefine.h"
#import "AlivcUserInfoViewController.h"
#import "ELCVFlowLayout.h"
#import "AlivcLiveEnvManager.h"
#import <AliyunVideoSDKPro/AliyunVideoSDKInfo.h>

//helper
#import "UIImage+AlivcHelper.h"
#import "MBProgressHUD+AlivcHelper.h"

#import "UIApplication+AlivcHelper.h"


#import "SDKVersionManager.h"





NS_ASSUME_NONNULL_BEGIN

static CGFloat deviceInCollectionView = 12; //两个item之间的距离
static CGFloat besise = 16; //collectionView的边距
static CGFloat lableDevideToTop = 44; //阿里云视频label距离顶部的距离


@interface AlivcHomeViewController ()<UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,UIScrollViewDelegate>


/**
 模块描述字符串集合
 */
@property (strong, nonatomic) NSArray <AVC_ET_ModuleDefine *>*dataArray;


/**
 阿里云视频的label
 */
@property (strong, nonatomic) UILabel *aliLabel;

/**
 欢迎label
 */
@property (strong, nonatomic) UILabel *welcomeLabel;

/**
 用户设置按钮
 */
@property (strong, nonatomic) UIButton *userSettingButton;

/**
 展示列表
 */
@property (strong, nonatomic) UICollectionView *collectionView;

/**
 列表的页数
 */
@property (strong, nonatomic, nullable) UIPageControl *pageController;

@property (assign, nonatomic) BOOL isClipConfig;


/**
 环境
 */
@property (strong, nonatomic) UIButton *envButton;
@property (nonatomic, assign) int envMode;
/**
 环境
 */
@property (nonatomic, assign) BOOL isChangedRow;


/**
 简单路由
 */
//@property (nonatomic, strong) AlivcShortVideoRoute *alivcRoute;

@property (nonatomic,copy)NSString *plistString;
@end

@implementation AlivcHomeViewController


#pragma mark - System

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.isChangedRow = NO;
    
    [self configBaseData];
    [self configBaseUI];
    [self setDefaultEnv];
    
    [self hasNewVersion];
    [self checkFreeDiskSpaceInBytes];
}

- (void)hasNewVersion{
    AVC_ET_ModuleDefine *module = self.dataArray[0];
    if((self.dataArray.count == 1)&&(module.type == AVC_ET_ModuleType_ShortVideo)){
        // 趣视频单独包版本更新
        self.plistString = @"https://vod-download.cn-shanghai.aliyuncs.com/apsaravideo-upgrade/ios/littleVideo.plist";
        [self checkVersion];
        
    }else if (self.dataArray.count>=5){
        // 全量包版本更新
        self.plistString = @"https://vod-download.cn-shanghai.aliyuncs.com/apsaravideo-upgrade/ios/ApsaraVideo.plist";
        [self checkVersion];
    }
}

- (void)checkVersion{
    
    
    NSDictionary *dic = [NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:self.plistString]];
    NSString *releaseNote = dic[@"items"][0][@"metadata"][@"releaseNote"];
    NSString *onLineVersion = dic[@"items"][0][@"metadata"][@"bundle-version"];
    
   
    
    NSString *localVerson = [UIApplication sharedApplication].appVersion;
    
    if([localVerson compare:onLineVersion options:NSNumericSearch] == NSOrderedAscending){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"检测到新版本，是否更新？" message:releaseNote delegate:self cancelButtonTitle:nil otherButtonTitles:@"更新", nil];
        
        [alert show];
    }
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (@available(iOS 10.0, *)) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"itms-services://?action=download-manifest&url=%@",self.plistString]] options:@{} completionHandler:nil];
    } else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"itms-services://?action=download-manifest&url=%@",self.plistString]]];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        exit(0);
    });
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //导航栏设置
    self.navigationController.navigationBar.hidden = true;
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
//    self.navigationController.navigationBar.hidden = false;
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - 旋转
- (BOOL)shouldAutorotate{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return UIInterfaceOrientationPortrait;
}

#pragma mark - Lazy init
- (UILabel *)aliLabel{
    if (!_aliLabel) {
        _aliLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 100, 30)];
        _aliLabel.font = [UIFont systemFontOfSize:26];
        _aliLabel.textColor = [UIColor whiteColor];
        _aliLabel.text = [@"alivc_yun_video" localString];
        [_aliLabel sizeToFit];
        CGFloat heightAliLabel = CGRectGetHeight(_aliLabel.frame);
        CGFloat widthAlilabel = CGRectGetWidth(_aliLabel.frame);
        _aliLabel.center = CGPointMake(besise + widthAlilabel / 2,lableDevideToTop + heightAliLabel / 2);
        _aliLabel.userInteractionEnabled =YES;
        
        UITapGestureRecognizer *taps =[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(showSdkInfo)];
        taps.numberOfTapsRequired =3;
        taps.delaysTouchesBegan =YES;
        [_aliLabel addGestureRecognizer:taps];
    }
    return _aliLabel;
}
- (UILabel *)welcomeLabel{
    if (!_welcomeLabel) {
        _welcomeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 100, 30)];
        _welcomeLabel.font = [UIFont systemFontOfSize:14];
        _welcomeLabel.textColor = [UIColor whiteColor];
        _welcomeLabel.text = [@"WELCOME TO START THE VIDEO JOURNEY" localString];
        [_welcomeLabel sizeToFit];
        CGFloat heightWLabel = CGRectGetHeight(_welcomeLabel.frame);
        CGFloat widthWLabel = CGRectGetWidth(_welcomeLabel.frame);
        _welcomeLabel.center = CGPointMake(besise + widthWLabel / 2, lableDevideToTop + self.aliLabel.frame.size.height + 16 + heightWLabel / 2);
    }
    return _welcomeLabel;
}

- (UIButton *)userSettingButton{
    if (!_userSettingButton) {
        UIButton *button = [[UIButton alloc]initWithFrame:CGRectMake(PortraitScreenWidth - 66, lableDevideToTop, 36, 46)];
        [button setBackgroundImage:nil forState:UIControlStateNormal];
        [button setBackgroundImage:[UIImage imageNamed:@"avcUserIcon"] forState:UIControlStateNormal];
        [button setBackgroundImage:[UIImage imageNamed:@"avcUserIcon"] forState:UIControlStateSelected];
        [button sizeToFit];
        [button addTarget:self action:@selector(userSetting) forControlEvents:UIControlEventTouchUpInside];
        button.center = CGPointMake(PortraitScreenWidth - besise - button.frame.size.width / 2, lableDevideToTop + button.frame.size.height / 2);
        _userSettingButton = button;
    }
    return _userSettingButton;
}

- (UICollectionView *)collectionView{
    if (!_collectionView) {
        
        CGFloat cWidth = PortraitScreenWidth - 2 * besise;
        CGFloat cItemWidth = (cWidth - deviceInCollectionView) / 2;
        CGFloat cItemHeight = 120;
        CGFloat cHeight = cItemHeight * 3 + deviceInCollectionView * 2;
        CGFloat cDevideToTop = ((ScreenHeight-CGRectGetMaxY(_welcomeLabel.frame)-30)-cHeight)/2.0+CGRectGetMaxY(_welcomeLabel.frame);
        CGRect cFrame = CGRectMake(besise, cDevideToTop, cWidth, cHeight);
        ELCVFlowLayout *layout = [[ELCVFlowLayout alloc]init];
        layout.itemSize = CGSizeMake(cItemWidth, cItemHeight);
        [layout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
        UICollectionView *cView = [[UICollectionView alloc]initWithFrame:cFrame collectionViewLayout:layout];
        [cView registerNib:[UINib nibWithNibName:@"AVC_ET_ModuleItemCCell" bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:@"AVC_ET_ModuleItemCCell"];
        cView.dataSource = self;
        cView.delegate = self;
        cView.pagingEnabled = true;
        cView.scrollEnabled = YES;
        cView.backgroundColor = [UIColor clearColor];
        cView.showsVerticalScrollIndicator = false;
        cView.showsHorizontalScrollIndicator = false;
        _collectionView = cView;
    }
    return _collectionView;
}

- (UIPageControl *__nullable)pageController{
    if (!_pageController && self.dataArray.count > 6) {
        _pageController = [[UIPageControl alloc]init];
        NSInteger shang = self.dataArray.count / 6;
        NSInteger yushu = self.dataArray.count % 6;
        if (yushu) {
            shang += 1;
        }
        _pageController.numberOfPages = shang;
        CGFloat cx = PortraitScreenWidth / 2;
        CGFloat cy = PortraitScreenHeight - 20;
        _pageController.center = CGPointMake(cx, cy);
    }
    return _pageController;
}

- (UIButton *)envButton{
    if (!_envButton) {
        UIButton *button = [[UIButton alloc]initWithFrame:CGRectMake(ScreenWidth - 50, lableDevideToTop+50, 60, 46)];
        button.titleLabel.font = [UIFont systemFontOfSize:10];
        [button setTitle:[@"note_city_PreRelease" localString] forState:UIControlStateNormal];
        [button sizeToFit];
        button.titleLabel.adjustsFontSizeToFitWidth = YES;
        CGRect rect = button.frame;
        rect.size.width += 10;
        button.frame = rect;
        [button addTarget:self action:@selector(envButtonTouched) forControlEvents:UIControlEventTouchUpInside];
        
        if (self.pageController.center.y > 0) {
            button.center = CGPointMake(ScreenWidth - besise - button.frame.size.width / 2,
                                        self.pageController.center.y);
        }else{
            button.center = CGPointMake(ScreenWidth - besise - button.frame.size.width / 2,
                                        ScreenHeight - button.bounds.size.height - 20);
        }
        
        _envButton = button;
    }
    return _envButton;
}

#pragma mark - EnvManager
- (void)envButtonTouched{
#ifdef DEBUG
    [self debugEnvChanged];
#else
    [self releaseEnvChanged];
#endif
}

- (void)debugEnvChanged{
    _envMode = _envMode+1;
    if (_envMode == 4) {
        _envMode = 0;
    }
    switch (_envMode) {
        case 0:
            [_envButton setTitle:[@"note_city_Shanghai" localString] forState:UIControlStateNormal];
            break;
        case 1:
             [_envButton setTitle:[@"note_city_Singapore" localString] forState:UIControlStateNormal];
            break;
        case 2:
            [_envButton setTitle:[@"note_city_PreRelease" localString] forState:UIControlStateNormal];
            break;
        case 3:
           [_envButton setTitle:[@"note_city_Daily" localString] forState:UIControlStateNormal];
            break;
        default:
            break;
    }
    [AlivcLiveEnvManager AlivcAppServerSetTestEnvMode:_envMode];
}

- (void)releaseEnvChanged{
    _envMode = _envMode+1;
    if (_envMode == 2) {
        _envMode = 0;
    }
    if (_envMode == 0) {
        [_envButton setTitle:[@"note_city_Shanghai" localString] forState:UIControlStateNormal];
        [AlivcLiveEnvManager AlivcAppServerSetTestEnvMode:0];
        
    }else{
        [_envButton setTitle:[@"note_city_Singapore" localString] forState:UIControlStateNormal];
        [AlivcLiveEnvManager AlivcAppServerSetTestEnvMode:1];
    }
}

- (void)setDefaultEnv{
    [_envButton setTitle:[@"note_city_Shanghai" localString] forState:UIControlStateNormal];
    [AlivcLiveEnvManager AlivcAppServerSetTestEnvMode:0];
}



#pragma mark - BaseSet
/**
 适配基本的数据
 */
- (void)configBaseData{
    
    NSMutableArray *mArray = [[NSMutableArray alloc]init];
    
    //功能配置
    NSInteger shouldAddValue = 0b111;    for (int i = 0; i < 16; i ++) {
        NSInteger typeValue = 1 << i;
        BOOL shouldAdd = shouldAddValue & typeValue;
        if (shouldAdd) {
            AVC_ET_ModuleType type = (AVC_ET_ModuleType)typeValue;
            AVC_ET_ModuleDefine *module = [[AVC_ET_ModuleDefine alloc]initWithModuleType:type];
            [mArray addObject:module];
        }
    }
    self.dataArray = (NSArray *)mArray;
}

/**
 适配基本的UI
 */
- (void)configBaseUI{
    
    // 背景图
    UIImageView *bg = [[UIImageView alloc] initWithFrame:CGRectMake(60, 0, ScreenWidth-60, (ScreenWidth-60)*378/644.0)];
    bg.image = [UIImage imageNamed:@"bg_home"];
    bg.userInteractionEnabled =YES;
    [self.view addSubview:bg];
    
    //ali label
    [self.view addSubview:self.aliLabel];
    
    //welcome label
    [self.view addSubview:self.welcomeLabel];
    
    //user setting
    [self.view addSubview:self.userSettingButton];
    
    //env
    [self.view addSubview:self.envButton];
    
    //CollectionView
    [self.view addSubview:self.collectionView];
    
    //pageController
    if (self.pageController) {
        [self.view addSubview:self.pageController];
    }
}


#pragma mark - Response

- (void)userSetting{
    AlivcUserInfoViewController *targetVC = [[AlivcUserInfoViewController alloc]init];
    self.navigationController.navigationBar.hidden = false;
    [self.navigationController pushViewController:targetVC animated:true];
}


#pragma mark - Custom Method
- (void)pushTargetVCWithClassString:(NSString *)classString{
    Class viewControllerClass = NSClassFromString(classString);
    if (viewControllerClass) {
        UIViewController *targetVC = [[viewControllerClass alloc]init];
        if (targetVC) {
            [self.navigationController pushViewController:targetVC animated:true];
        }
    }
    
}

- (void)pushTargetVCWithClassString:(NSString *)classString value:(id)value valueString:(NSString *)valueString{
    Class viewControllerClass = NSClassFromString(classString);
    if (viewControllerClass) {
        UIViewController *targetVC = [[viewControllerClass alloc]init];
        if (targetVC) {
            if (value && valueString) {
                [targetVC setValue:value forKey:valueString];
            }
            [self.navigationController pushViewController:targetVC animated:true];
        }
    }
}

-(void)showSdkInfo{
    NSString *version =[AliyunVideoSDKInfo version];
    NSString *alivcCommitId =[AliyunVideoSDKInfo alivcCommitId];
    NSString *mediaCoreCommitId =[AliyunVideoSDKInfo mediaCoreCommitId];
    NSString *videoSDKCommitId =[AliyunVideoSDKInfo videoSDKCommitId];
    NSString *videoSDKBuildId =[AliyunVideoSDKInfo videoSDKBuildId];
    NSString *msg =[NSString stringWithFormat:@" version:%@ \n alivcCommitId:%@ \n mediaCoreCommitId:%@ \n videoSDKCommitId:%@ \n videoSDKBuildId:%@",version,alivcCommitId,mediaCoreCommitId,videoSDKCommitId,videoSDKBuildId];
    UIAlertView *alert =[[UIAlertView alloc]initWithTitle:@"SDK版本信息" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
}


#pragma mark - UICollectionViewDelegateFlowLayout

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    return deviceInCollectionView;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section{
    return deviceInCollectionView;
}



#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.dataArray.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    AVC_ET_ModuleItemCCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"AVC_ET_ModuleItemCCell" forIndexPath:indexPath];
    if (self.dataArray.count > indexPath.row) {
        AVC_ET_ModuleDefine *define = self.dataArray[indexPath.row];
        [cell configWithModule:define];
    }
    return cell;
}



#pragma mark - UICollectionViewDelegate

- (void)repeatDelay{
    self.isChangedRow = false;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    if (self.isChangedRow == NO) {
        self.isChangedRow = YES;
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(repeatDelay) object:nil];
        [self performSelector:@selector(repeatDelay) withObject:nil afterDelay:0.5];
        
        if (indexPath.row < self.dataArray.count) {
            AVC_ET_ModuleDefine *module = self.dataArray[indexPath.row];
            [self configImageBundleWithType:module.type];
            switch (module.type) {
                    // 视频拍摄
                case AVC_ET_ModuleType_VideoShooting:
                    [self pushTargetVCWithClassString:@"AliyunRecordParamViewController"];break;
                    
                    // 视频编辑
                case AVC_ET_ModuleType_VideoEdit:
                     [self pushTargetVCWithClassString:@"AliyunConfigureViewController" value:@"NO" valueString:@"isClipConfig"];break;
                    
                    // 视频裁剪
                case AVC_ET_ModuleType_VideoClip:
                    [self pushTargetVCWithClassString:@"AliyunConfigureViewController" value:@"YES" valueString:@"isClipConfig"];break;
                    
                    // 趣视频
                case AVC_ET_ModuleType_ShortVideo:
                    [self pushTargetVCWithClassString:@"AlivcShortVideoPlayViewControler"];break;
                    
                    // 视频拍摄 - 基础版
                case AVC_ET_ModuleType_VideoShooting_Basic:
                    [self pushTargetVCWithClassString:@"AlivcBase_RecordParamViewController"];break;
                    
                    // 视频裁剪 - 基础版
                case AVC_ET_ModuleType_VideoClip_Basic:[self pushTargetVCWithClassString:@"AlivcBase_ConfigureViewController"];break;
                    
                    
                case AVC_ET_ModuleType_PushFlow:[self pushTargetVCWithClassString:@"AlivcLivePushRootViewController"];break;
                    
                    
                    
                case AVC_ET_ModuleType_RTC_Audio:[self pushTargetVCWithClassString:@"AlivcRTCAudioHomeViewController"];break;
                    //互动白板
                case AVC_ET_ModuleType_Smartboard:[self pushTargetVCWithClassString:@"AlivcSmartboardLoginViewController"];break;
                    
                default:
                    break;
            }
        }else{
            NSAssert(false, @"数组越界test");
        }
    }else{
        return;
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    CGPoint offset = scrollView.contentOffset;
    NSInteger currentPage = offset.x / scrollView.frame.size.width;
    if (currentPage < self.pageController.numberOfPages) {
        self.pageController.currentPage = currentPage;
    }
}


- (void)dealloc{
    if ([self respondsToSelector:@selector(repeatDelay)]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(repeatDelay) object:nil];
    }
}

#pragma mark - ImageBundleConfig

- (void)configImageBundleWithType:(AVC_ET_ModuleType)type{
    switch (type) {
        case AVC_ET_ModuleType_VideoShooting:
            [AlivcImage setImageBundleName:@"AlivcShortVideoImage"];
            break;
        case AVC_ET_ModuleType_VideoEdit:
            [AlivcImage setImageBundleName:@"AlivcShortVideoImage"];
            break;
        case AVC_ET_ModuleType_VideoClip:
            [AlivcImage setImageBundleName:@"AlivcShortVideoImage"];
            break;
        case AVC_ET_ModuleType_ShortVideo:
            [AlivcImage setImageBundleName:@"AlivcShortVideoImage"];
            break;
            
        default:
            break;
    }
}


- (void)checkFreeDiskSpaceInBytes{
    CGFloat freeSpace =[self freeDiskSpaceInBytes]-160;
    if (freeSpace<100 && freeSpace>0.1) {
        UIAlertController *alert =[UIAlertController alertControllerWithTitle:@"提示" message:@"设备内存不足，请及时清理" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action =[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:action];
        [self presentViewController:alert animated:NO completion:nil];
    }
    NSLog(@"设备剩余内存%f",freeSpace);
}


// 空余硬盘大小
- (CGFloat)freeDiskSpaceInBytes{
    
    CGFloat totalFreeSpace = 0.0;
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
    
    if (dictionary) {
        NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
        totalFreeSpace = (([freeFileSystemSizeInBytes floatValue]/1024.f)/1024.f);
    } else {
        NSLog(@"Error Obtaining System Memory Info: Domain = %@, Code = %@", [error domain], [error code]);
    }
    
//    if (@available(iOS 11.0, *)) {
//        NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:NSTemporaryDirectory()];
//        NSDictionary *results = [fileURL resourceValuesForKeys:@[NSURLVolumeAvailableCapacityForImportantUsageKey] error:&error];
//        if (!results) {
//            NSLog(@"Error retrieving resource keys: %@%@",[error localizedDescription], [error userInfo]);
//            abort();
//
//        }
//        NSLog(@"Available capacity for important usage: %lf",[[results objectForKey:NSURLVolumeAvailableCapacityForImportantUsageKey] floatValue]);
//        totalFreeSpace = [[results objectForKey:NSURLVolumeAvailableCapacityForImportantUsageKey] floatValue]/1000.f/1000.f;
//    } else {
//
//    }
    return totalFreeSpace;
    
}

@end

NS_ASSUME_NONNULL_END
