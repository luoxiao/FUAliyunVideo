//
//  AliyunRecordBeautyView.m
//  AliyunVideoClient_Entrance
//
//  Created by 张璠 on 2018/7/6.
//  Copyright © 2018年 Alibaba. All rights reserved.
//

#import "AliyunRecordBeautyView.h"
#import "AliyunToolView.h"
#import "AlivcRecordFliterView.h"
#import "AliyunMagicCameraEffectCell.h"
#import "AliyunPasterInfo.h"
#import <UIImageView+WebCache.h>
#import "AliyunEffectFilterCell.h"
#import "AliyunDBHelper.h"
#import "AliyunResourceRequestManager.h"
#import "AliyunEffectResourceModel.h"
#import "AliyunResourceDownloadManager.h"
#import "AliyunEffectModelTransManager.h"
#import "UIView+AlivcHelper.h"
#import "AlivcPushBeautyDataManager.h"
#import "AlivcLiveBeautifySettingsViewController.h"
#import "MBProgressHUD+AlivcHelper.h"
#import "AlivcShortVideoFaceUnityManager.h"
#import "AVC_ShortVideo_Config.h"
#import "FUMusicPlayer.h"

#define musicIndx  8
typedef enum : NSUInteger {
    AliyunEditSouceClickTypeNone = 0,
    AliyunEditSouceClickTypeFilter,
    AliyunEditSouceClickTypePaster,
    AliyunEditSouceClickTypeCaption,
    AliyunEditSouceClickTypeMV,
    AliyunEditSouceClickTypeMusic,
    AliyunEditSouceClickTypePaint,
    AliyunEditSouceClickTypeTimeFilter
} AliyunEditSouceClickType;

@interface AliyunRecordBeautyView()<AliyunToolViewDelegate,AliyunEffectFilter2ViewDelegate,UICollectionViewDelegate,UICollectionViewDataSource,AlivcLiveBeautifySettingsViewControllerDelegate
>

/**
 滤镜view
 */
@property (nonatomic, strong) AlivcRecordFliterView *filterView;

/**
 美颜view
 */
@property (nonatomic, strong) UIView *beautySkinView;

/**
 美肌view
 */
@property (nonatomic, strong) UIView *beautyFaceView;

/**
 动图view
 */
@property (nonatomic, strong) UICollectionView *gifCollectionView;

/**
 MV view
 */
@property (nonatomic, strong) UICollectionView *mvCollectionView;

/**
itme view
 */
@property (nonatomic, strong) UICollectionView *itmeCollectionView;

///**
// 动漫 view
// */
//@property (nonatomic, strong) UICollectionView *comicCollectionView;
//
///**
// haha镜 view
// */
//@property (nonatomic, strong) UICollectionView *hahaCollectionView;

/**
 文字数组
 */
@property (nonatomic, strong) NSArray *titleArray;

/**
 正在显示的view
 */
@property (nonatomic, weak) UIView *frontView;

/**
 顶部按钮序号
 */
@property (nonatomic, assign) CGFloat buttonTag;

/**
 MV选中的序号
 */
@property (nonatomic, assign) NSInteger selectIndex;

/**
 人脸动图选中的序号
 */
@property (nonatomic, assign) NSInteger selectGifIndex;

/**
 贴纸选中的序号
 */
@property (nonatomic, assign) NSInteger itemSelIndex;

/**
 选中道具所在tag
 */
@property (nonatomic, assign) NSInteger selItemBtnTag;

/**
 对FMDB包装类的对象
 */
@property (nonatomic, strong) AliyunDBHelper *dbHelper;

/**
 顶部view
 */
@property (nonatomic, strong) AliyunToolView *toolView;

/**
 美颜类型
 */
@property (nonatomic, assign) AliyunBeautyType beautyType;
@property (nonatomic, strong) AlivcLiveBeautifySettingsViewController *beatyFaceSettingViewControl;//高级美颜界面
@property (nonatomic, strong) AlivcLiveBeautifySettingsViewController *beatySkinSettingViewControl;//美肌界面

@property (nonatomic, strong) AlivcPushBeautyDataManager *beautyFaceDataManager_normal;     //普通美颜的数据管理器
@property (nonatomic, strong) AlivcPushBeautyDataManager *beautyFaceDataManager_advanced;   //高级美颜的数据管理器
@property (nonatomic, strong) AlivcPushBeautyDataManager *beautySkinDataManager;            //美肌的数据管理器

/**
 滤镜view的父view
 */
@property (nonatomic, strong) UIView *contentView;

/**
 点击这个button，此类的view消失
 */
@property (nonatomic, strong) UIButton *dismissButton;

@property (nonatomic, copy) NSArray *effectItems; //动图
@property (nonatomic, strong) NSMutableArray *mvItems; //mv
@property (nonatomic, copy) NSArray <NSString *>*itemsArray;
@property (nonatomic, copy) NSArray <NSArray *>*itemsTotalArray; //贴纸

@end

@implementation AliyunRecordBeautyView

-(instancetype)initWithFrame:(CGRect)frame titleArray:(NSArray *)titleArray  imageArray:(NSArray *)imageArray{
    self = [super initWithFrame:frame];
    if (self) {
        
        _beautyFaceDataManager_normal = [[AlivcPushBeautyDataManager alloc]initWithType:AlivcPushBeautyParamsTypeShortVideo customSaveString:@"beautyFaceDataManager_normal"];
        _beautyFaceDataManager_advanced = [[AlivcPushBeautyDataManager alloc]initWithType:AlivcPushBeautyParamsTypeShortVideo customSaveString:@"beautyFaceDataManager_advanced"];
        _beautySkinDataManager = [[AlivcPushBeautyDataManager alloc]initWithType:AlivcPushBeautyParamsTypeShortVideo customSaveString:@"beautySkinDataManager"];
        
        [self setup:titleArray imageArray:imageArray];
        self.titleArray = titleArray;
        self.mvItems = [[NSMutableArray alloc] init];
        
        NSArray *array0 = @[@"mask_hat",@"yazui",@"yuguan",@"bling",@"fengya_ztt_fu",@"hudie_lm_fu",@"juanhuzi_lm_fu",@"touhua_ztt_fu"];
        NSArray *array1 = @[@"fuzzytoonfilter"];
        NSArray *array2 = @[@"facewarp2",@"facewarp3",@"facewarp4",@"facewarp5",@"facewarp6"];
        NSArray *array3 = @[@"baimao_Animoji",@"douniuquan_Animoji",@"frog_Animoji",@"hashiqi_Animoji",@"hetun_Animoji",@"huangya_Animoji",@"kuloutou_Animoji"];
        NSArray *array4 = @[@"gufeng_zh_fu",@"hez_ztt_fu",@"ice_lm_fu",@"men_ztt_fu",@"sea_lm_fu",@"xiandai_ztt_fu"];
        NSArray *array5 = @[@"fu_lm_koreaheart",@"fu_ztt_live520",@"ssd_thread_cute",@"ssd_thread_six",@"ssd_thread_thumb",@"ctrl_rain",@"ctrl_snow",@"ctrl_flower"];
        NSArray *array6 = @[@"bluebird_180718",@"lanhudie",@"fenhudie",@"tiger_huang_180718",@"tiger_bai_180718",@"afd",@"baozi",@"tiger",@"xiongmao",@"armesh",@"armesh_ex"];
        
        NSArray *musicArray = @[@"douyin_01",@"douyin_02"];
        NSArray *array8 = @[@"future_warrior",@"jet_mask",@"sdx2",@"luhantongkuan_ztt_fu",@"qingqing_ztt_fu",@"xiaobianzi_zh_fu",@"baozi",@"xiaoxueshen_ztt_fu"];
        
        _itemsTotalArray = @[array0,array3,array2,array4,array1,array5,array6,musicArray,array8];
        
        /* 后台监听 */
        [self addObserver];
    }
    return self;
}

- (void)setGifSelectedIndex:(NSInteger)selectedIndex{
    self.selectGifIndex = selectedIndex;
    [self.gifCollectionView reloadData];
}


/**
 初始化的一些设置

 @param titleArray 文字数组
 @param imageArray 图片数组
 */
- (void)setup:(NSArray *)titleArray imageArray:(NSArray *)imageArray{

    self.backgroundColor = [UIColor clearColor];
    if ([titleArray[0] isEqualToString:@"滤镜"]) {
        
        self.contentView = [[UIView alloc]initWithFrame:CGRectMake(0, 78, ScreenWidth, self.frame.size.height - 78)];
        [self addSubview:self.contentView];
        [self.contentView addVisualEffect];
        self.toolView = [[AliyunToolView alloc] initWithItems:titleArray imageArray:imageArray frame:CGRectMake(0, 0, ScreenWidth, 45)];
        self.toolView.delegate = self;
        [self.contentView addSubview:self.toolView];
        [self.contentView addSubview:self.filterView];
    //    [self.filterView reloadDataWithEffectType:4];
        self.frontView = self.filterView;
        
        _dismissButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.width, 78)];
        _dismissButton.backgroundColor = [UIColor clearColor];
        [self addSubview:_dismissButton];
        [_dismissButton addTarget:self action:@selector(disMissSelf:) forControlEvents:UIControlEventTouchUpInside];
    }else if([titleArray[0] isEqualToString:@"人脸贴纸"]){
        [self addVisualEffect];
        self.toolView = [[AliyunToolView alloc] initWithItems:titleArray  imageArray:imageArray frame:CGRectMake(0, 0, ScreenWidth, 45)];
        self.toolView.delegate = self;
        [self addSubview:self.toolView];
        
        [self addSubview:self.gifCollectionView];
        self.frontView = self.gifCollectionView;
        [self.dbHelper openResourceDBSuccess:nil failure:nil];
    }
}

/**
 _dismissButton的点击时间

 @param button _dismissButton
 */
- (void)disMissSelf:(UIButton *)button{
    if (self.delegate && [self.delegate respondsToSelector:@selector(recordBeautyView:dismissButtonTouched:)]) {
        [self.delegate recordBeautyView:self dismissButtonTouched:button];
    }
}


- (void)setEffectItems:(NSArray *)effectItems
{
    _effectItems = effectItems;
    [_gifCollectionView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
}

- (void)AliyunToolView:(AliyunToolView *)toolView didClickedButton:(NSInteger)buttonTag{
    [self.frontView removeFromSuperview];
    if ([self.titleArray[0] isEqualToString:@"滤镜"]) {
        if (buttonTag==0) {
            [self.contentView addSubview:self.filterView];
        //    [self.filterView reloadDataWithEffectType:4];
            self.frontView = self.filterView;
        }else if(buttonTag == 1){
            [self addSubview:self.beautyFaceView];
            self.frontView = self.beautyFaceView;
//            [self bringSubviewToFront:self.dismissButton];
        }else if(buttonTag == 2){
            [self addSubview:self.beautySkinView];
            self.frontView = self.beautySkinView;
//            [self bringSubviewToFront:self.dismissButton];
            
        }
    }else if([self.titleArray[0] isEqualToString:@"人脸贴纸"]){
//       [self addSubview:self.gifCollectionView];
//        self.frontView = self.gifCollectionView;
        if (buttonTag == 0) {
            [self addSubview:self.gifCollectionView];
            self.frontView = self.gifCollectionView;
            
        }else{
            if (buttonTag == 3) {
                [[AlivcShortVideoFaceUnityManager shareManager] loadAnimojiFaxxBundle];
            }
            _itemsArray = _itemsTotalArray[buttonTag - 1];
            [self addSubview:self.itmeCollectionView];
            self.frontView = self.itmeCollectionView;
            [_itmeCollectionView reloadData];
        }
    }
    self.buttonTag = buttonTag;
    
}

- (AlivcRecordFliterView *)filterView {
    if (!_filterView) {
        
        _filterView = [[AlivcRecordFliterView alloc] initWithFrame:CGRectMake(0, 50, ScreenWidth, 102)];
        _filterView.backgroundColor = [UIColor clearColor];
        _filterView.delegate = (id<AliyunEffectFilter2ViewDelegate>)self;
   //     _filterView.hideTop = YES;
    }
    return _filterView;
}



- (UIView *)beautyFaceView {
    if (!_beautyFaceView) {
        //默认档位
        
        NSInteger level = [_beautyFaceDataManager_advanced getBeautyLevel];
        //可供微调的选择
        NSArray *dics = @[[_beautyFaceDataManager_advanced SkinPolishingDic],[_beautyFaceDataManager_advanced SkinWhiteningDic],[_beautyFaceDataManager_advanced SkinShiningDic]];
        
        self.beatyFaceSettingViewControl = [AlivcLiveBeautifySettingsViewController settingsViewControllerWithLevel:level detailItems:dics];
        
        //因为control没有展示在界面上，所有view手动设置frame
        self.beatyFaceSettingViewControl.view.frame = CGRectMake(0, 0, ScreenWidth, self.frame.size.height);
        
        //设置高低级美颜
        AlivcBeautySettingViewStyle style = [[NSUserDefaults standardUserDefaults] integerForKey:@"shortVideo_beautyType"];
        if (style == AlivcBeautySettingViewStyle_ShortVideo_BeautyFace_Base) {
            [self.beatyFaceSettingViewControl setUIStyle:AlivcBeautySettingViewStyle_ShortVideo_BeautyFace_Base];
            //设置档位
            NSInteger level = [self.beautyFaceDataManager_normal getBeautyLevel];
            [self.beatyFaceSettingViewControl updateLevel:level];
        }else{
            [self.beatyFaceSettingViewControl setUIStyle:AlivcBeautySettingViewStyle_ShortVideo_BeautyFace_Advanced];
            //设置档位
            NSInteger level = [self.beautyFaceDataManager_advanced getBeautyLevel];
            [self.beatyFaceSettingViewControl updateLevel:level];
        }
        
        self.beatyFaceSettingViewControl.delegate = self;
        for (NSInteger i = 0; i < 3; i ++) {
            __block AliyunRecordBeautyView *weakSelf = self;
            [self.beatyFaceSettingViewControl setAction:^{
                [weakSelf.toolView clickTithTag:i];
            } withTag:i];
        }
       
        _beautyFaceView = self.beatyFaceSettingViewControl.view;
        
    }
    return _beautyFaceView;
}


- (UIView *)beautySkinView {
    if (!_beautySkinView) {
        //默认档位
        NSInteger level = [_beautySkinDataManager getBeautyLevel];
        //可供微调的选择
        NSArray *dics = @[[_beautySkinDataManager EyeWideningDic],[_beautySkinDataManager FaceSlimmingDic]];
        self.beatySkinSettingViewControl = [AlivcLiveBeautifySettingsViewController settingsViewControllerWithLevel:level detailItems:dics];
        
        [self.beatySkinSettingViewControl setUIStyle:AlivcBeautySettingViewStyle_ShortVideo_BeautySkin];
        self.beatySkinSettingViewControl.delegate = self;
        for (NSInteger i = 0; i < 3; i ++) {
            __block AliyunRecordBeautyView *weakSelf = self;
            [self.beatySkinSettingViewControl setAction:^{
                [weakSelf.toolView clickTithTag:i];
            } withTag:i];
        }
        //因为control没有展示在界面上，所有view手动设置frame
        self.beatySkinSettingViewControl.view.frame = CGRectMake(0, 0, ScreenWidth, self.frame.size.height);
        
        _beautySkinView = self.beatySkinSettingViewControl.view;
    }
    return _beautySkinView;
}

- (UICollectionView *)gifCollectionView {
    if (!_gifCollectionView) {
        
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.sectionInset = UIEdgeInsetsMake(15, 22, 20, 22);
        flowLayout.minimumInteritemSpacing = 20;
        flowLayout.minimumLineSpacing = 20;
        _gifCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 45, ScreenWidth, 165) collectionViewLayout:flowLayout];
        _gifCollectionView.backgroundColor = [UIColor clearColor];
        _gifCollectionView.delegate = (id)self;
        _gifCollectionView.dataSource = (id)self;
        [_gifCollectionView registerClass:[AliyunMagicCameraEffectCell class] forCellWithReuseIdentifier:@"AliyunMagicCameraEffectCell"];
        
    }
    return _gifCollectionView;
}

- (AliyunDBHelper *)dbHelper {
    
    if (!_dbHelper) {
        _dbHelper = [[AliyunDBHelper alloc] init];
    }
    return _dbHelper;
}


- (UICollectionView *)mvCollectionView{
    if (!_mvCollectionView) {
        
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.sectionInset = UIEdgeInsetsMake(15, 22, 20, 22);
        layout.minimumInteritemSpacing = 20;
        layout.minimumLineSpacing = 20;
//        layout.itemSize = CGSizeMake(50, 70);
        
        _mvCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 45, ScreenWidth, 165) collectionViewLayout:layout];
        _mvCollectionView.backgroundColor = [UIColor clearColor];
        _mvCollectionView.showsHorizontalScrollIndicator = NO;
        [_mvCollectionView registerNib:[UINib nibWithNibName:@"AliyunEffectFilterCell" bundle:nil] forCellWithReuseIdentifier:@"AliyunEffectFilterCell"];
        [_mvCollectionView registerNib:[UINib nibWithNibName:@"AliyunEffectFilterCell" bundle:nil] forCellWithReuseIdentifier:@"AliyunEffectFilterFuncCell"];
        _mvCollectionView.dataSource = (id<UICollectionViewDataSource>)self;
        _mvCollectionView.delegate = (id<UICollectionViewDelegate>)self;
        
    }
    return _mvCollectionView;
}

-(UICollectionView *)itmeCollectionView{
    if (!_itmeCollectionView) {
        
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.sectionInset = UIEdgeInsetsMake(15, 22, 20, 22);
        layout.minimumInteritemSpacing = 20;
        layout.minimumLineSpacing = 20;
        //        layout.itemSize = CGSizeMake(50, 70);
        
        _itmeCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 45, ScreenWidth, 165) collectionViewLayout:layout];
        _itmeCollectionView.backgroundColor = [UIColor clearColor];
        _itmeCollectionView.showsHorizontalScrollIndicator = NO;
        [_itmeCollectionView registerClass:[AliyunMagicCameraEffectCell class] forCellWithReuseIdentifier:@"AliyunMagicCameraEffectCell2"];
        _itmeCollectionView.dataSource = (id<UICollectionViewDataSource>)self;
        _itmeCollectionView.delegate = (id<UICollectionViewDelegate>)self;
    }
    return _itmeCollectionView;
}



#pragma mark - AliyunEffectFilter2ViewDelegate
- (void)didSelectEffectFilter:(AliyunEffectFilterInfo *)filter {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectEffectFilter:)]) {
        [self.delegate didSelectEffectFilter:filter];
    }

}

#pragma mark - UICollectionViewDataSource && UICollectionViewDelegate -

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if(self.buttonTag == 0){
        return self.effectItems.count;
    }else{
        return _itemsArray.count + 1;
    }
    
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.buttonTag == 0) {
        //动图
        
        AliyunMagicCameraEffectCell *effectCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"AliyunMagicCameraEffectCell" forIndexPath:indexPath];
        NSLog(@"\n-----动图下载测试：%ld,%p-------\n",(long)indexPath.row,effectCell);
        AliyunPasterInfo *pasterInfo = [self.effectItems objectAtIndex:indexPath.row];
        
        if (pasterInfo.bundlePath != nil) {
            UIImage *iconImage = [UIImage imageWithContentsOfFile:pasterInfo.icon];
            [effectCell.imageView setImage:iconImage];
            [effectCell shouldDownload:NO];
            NSLog(@"动图下载测试刷新图片：bundlePath：%@",pasterInfo.bundlePath);
        } else {
            
            if ([pasterInfo fileExist] && pasterInfo.icon) {
                NSLog(@"动图下载测试刷新图片 存在：icon：%@ ",pasterInfo.icon);
                UIImage *iconImage = [UIImage imageWithContentsOfFile:pasterInfo.icon];
                if (!iconImage) {
                    NSURL *url = [NSURL URLWithString:pasterInfo.icon];
                    [effectCell.imageView sd_setImageWithURL:url];
                    NSLog(@"动图下载测试url");
                } else {
                    [effectCell.imageView setImage:iconImage];
                    NSLog(@"动图下载测试iconImage");
                }
            } else {
                NSLog(@"动图下载测试刷新图片 不存在：icon：%@\n",pasterInfo.icon);
                NSURL *url = [NSURL URLWithString:pasterInfo.icon];
                [effectCell.imageView sd_setImageWithURL:url];
                
            }
            if (pasterInfo.icon == nil) {
                [effectCell shouldDownload:NO];
            } else {
                BOOL shouldDownload = ![pasterInfo fileExist];
                [effectCell shouldDownload:shouldDownload];
                NSLog(@"动图下载测试:下载按钮:%d",shouldDownload);
            }
            
        }
        if (indexPath.row == 0) {
            effectCell.imageView.contentMode = UIViewContentModeCenter;
            effectCell.imageView.backgroundColor = rgba(255, 255, 255, 0.2);
            effectCell.imageView.layer.cornerRadius = effectCell.imageView.frame.size.width/2;
            effectCell.imageView.layer.masksToBounds = YES;
            effectCell.imageView.image = [AlivcImage imageNamed:@"shortVideo_clear"];
            
        }else{
            effectCell.imageView.contentMode = UIViewContentModeScaleAspectFill;
            effectCell.imageView.backgroundColor = [UIColor clearColor];
            effectCell.imageView.layer.cornerRadius = 50/2;
            effectCell.imageView.layer.masksToBounds = YES;
        }
        if (indexPath.row == _selectGifIndex) {
            [effectCell setApplyed:YES];
            
            NSLog(@"动图下载测试选择效果设置为YES");
        }else{
            [effectCell setApplyed:NO];
             NSLog(@"动图下载测试选择效果设置为NO");
        }
        return effectCell;
    }else{
        AliyunMagicCameraEffectCell *effectCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"AliyunMagicCameraEffectCell2" forIndexPath:indexPath];
        [effectCell shouldDownload:NO];
        
        if (indexPath.row == 0) {
            effectCell.imageView.contentMode = UIViewContentModeCenter;
            effectCell.imageView.backgroundColor = rgba(255, 255, 255, 0.2);
            effectCell.imageView.layer.cornerRadius = effectCell.imageView.frame.size.width/2;
            effectCell.imageView.layer.masksToBounds = YES;
            effectCell.imageView.image = [AlivcImage imageNamed:@"shortVideo_clear"];
            
        }else{
            effectCell.imageView.contentMode = UIViewContentModeScaleAspectFill;
            effectCell.imageView.backgroundColor = [UIColor clearColor];
            effectCell.imageView.layer.cornerRadius = 50/2;
            effectCell.imageView.layer.masksToBounds = YES;
            
            NSString *filePath = [[NSBundle mainBundle] pathForResource:_itemsArray[indexPath.row -1] ofType:@"png"];
            UIImage *iconImage = [UIImage imageWithContentsOfFile:filePath];
            [effectCell.imageView setImage:iconImage];
            
        }
        if (_selItemBtnTag == _buttonTag) {
            if (indexPath.row == _itemSelIndex) {
                [effectCell setApplyed:YES];
                
                NSLog(@"动图下载测试选择效果设置为YES");
            }else{
                [effectCell setApplyed:NO];
                NSLog(@"动图下载测试选择效果设置为NO");
            }
        }else{
            if (indexPath.row == 0
                ) {
                [effectCell setApplyed:YES];
                
                NSLog(@"动图下载测试选择效果设置为YES");
            }else{
                [effectCell setApplyed:NO];
                NSLog(@"动图下载测试选择效果设置为NO");
            }
        }
       
        return effectCell;
    }
        
        
    
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.buttonTag == 0) {
        
        AliyunMagicCameraEffectCell *cell = (AliyunMagicCameraEffectCell *)[self.gifCollectionView cellForItemAtIndexPath:indexPath];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(focusItemIndex:cell:)]) {
                [self.delegate focusItemIndex:indexPath.row cell:cell];
            
                [[AlivcShortVideoFaceUnityManager shareManager] loadItem:nil];
                [[FUMusicPlayer sharePlayer] stop];
            }
        });
    }else{
        self.selItemBtnTag = self.buttonTag;
        _itemSelIndex = indexPath.row;
        [self.itmeCollectionView reloadData];
        if (indexPath.row == 0) {
            [[AlivcShortVideoFaceUnityManager shareManager] loadItem:nil];
            [[FUMusicPlayer sharePlayer] stop];
            return;
        }else{
            [[AlivcShortVideoFaceUnityManager shareManager] loadItem:_itemsArray[indexPath.row - 1]];
            
            NSString *hintStr = [[AlivcShortVideoFaceUnityManager shareManager] getHintForItemStr:_itemsArray[indexPath.row - 1]];
            if (hintStr) {//需要提示
               // [MBProgressHUD showMessage:hintStr inView:self];
                [MBProgressHUD showMessage:hintStr inView:[UIApplication sharedApplication].keyWindow];
            }
            
            if (self.buttonTag == musicIndx) {
                [[FUMusicPlayer sharePlayer] playMusic:@"douyin.mp3"];
            }else{
                [[FUMusicPlayer sharePlayer] stop];
            }
            
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(focusItemIndex:cell:)]) {
                [self.delegate focusItemIndex:0 cell:nil];
            }
        });
    
      

    }
    
}

#pragma mark - AlivcLiveBeautifySettingsViewControllerDelegate

- (void)settingsViewController:(AlivcLiveBeautifySettingsViewController *)viewController didChangeLevel:(NSInteger)level{
    //更新对应的选项
    if(viewController == self.beatyFaceSettingViewControl){
        //美颜
        switch (viewController.currentStyle) {
            case AlivcBeautySettingViewStyle_ShortVideo_BeautyFace_Advanced:
                {
                    [_beautyFaceDataManager_advanced saveBeautyLevel:level];
                    AlivcPushBeautyParams *params = [_beautyFaceDataManager_advanced getBeautyParamsOfLevel:level];
                    //高级美颜
                    NSLog(@"高级美颜改变档位:%d,美白:%d,磨皮：%d，红润：%d",(int)level,params.beautyWhite,params.beautyBuffing,params.beautyRuddy);
                    NSLog(@"高级美颜短视频当前版本：%d",SDK_VERSION);
                    [self.delegate didChangeAdvancedBeautyWhiteValue:params.beautyWhite];
                    [self.delegate didChangeAdvancedBlurValue:params.beautyBuffing];
                    [self.delegate didChangeAdvancedBuddy:params.beautyRuddy];
                    //更新详细参数的界面
                    NSArray *dics = @[[_beautyFaceDataManager_advanced SkinPolishingDic],[_beautyFaceDataManager_advanced SkinWhiteningDic],[_beautyFaceDataManager_advanced SkinShiningDic]];
                    [viewController updateDetailItems:dics];
                }
                break;
            case AlivcBeautySettingViewStyle_ShortVideo_BeautyFace_Base:
                {
                    //基础美颜
                    [_beautyFaceDataManager_normal saveBeautyLevel:level];
                    NSLog(@"基础美颜");
                    [self.delegate didChangeBeautyValue:level];
                }
                break;
            default:
                break;
        }
      
    }else if (viewController == self.beatySkinSettingViewControl){
        //美肌
        NSLog(@"美肌");
        
        [_beautySkinDataManager saveBeautyLevel:level];
        AlivcPushBeautyParams *params = [_beautySkinDataManager getBeautyParamsOfLevel:level];
        [self.delegate didChangeAdvancedSlimFace:params.beautySlimFace];
        [self.delegate didChangeAdvancedBigEye:params.beautyBigEye];
        
        NSArray *dics = @[[_beautySkinDataManager EyeWideningDic],[_beautySkinDataManager FaceSlimmingDic]];
        [viewController updateDetailItems:dics];
    }
    
}

- (void)settingsViewController:(AlivcLiveBeautifySettingsViewController *)viewController didChangeValue:(NSDictionary *)info{
    
    //更新对应的选项
    if(viewController == self.beatyFaceSettingViewControl){
        //美颜
        switch (viewController.currentStyle) {
            case AlivcBeautySettingViewStyle_ShortVideo_BeautyFace_Advanced:
            {
                //高级美颜
                [_beautyFaceDataManager_advanced saveParamWithInfo:info];
                AlivcPushBeautyParams *params = [_beautyFaceDataManager_advanced getBeautyParamsOfLevel:[_beautyFaceDataManager_advanced getBeautyLevel]];
                [self.delegate didChangeAdvancedBeautyWhiteValue:params.beautyWhite];
                [self.delegate didChangeAdvancedBlurValue:params.beautyBuffing];
                [self.delegate didChangeAdvancedBuddy:params.beautyRuddy];
                NSLog(@"高级美颜改变值,美白:%d,磨皮：%d，红润：%d",params.beautyWhite,params.beautyBuffing,params.beautyRuddy);
                NSLog(@"高级美颜短视频当前版本：%d",SDK_VERSION);

            }
                break;
            case AlivcBeautySettingViewStyle_ShortVideo_BeautyFace_Base:
            {
                //基础美颜
                NSLog(@"基础美颜");
                NSAssert(false, @"基础美颜怎么会调用到这里来，请开发人员仔细看下原因");
                
            }
                break;
            default:
                break;
        }
        
    }else if (viewController == self.beatySkinSettingViewControl){
        //美肌
        NSLog(@"美肌");
        
        [_beautySkinDataManager saveParamWithInfo:info];
        AlivcPushBeautyParams *params = [_beautySkinDataManager getBeautyParamsOfLevel:[_beautySkinDataManager getBeautyLevel]];
        [self.delegate didChangeAdvancedSlimFace:params.beautySlimFace];
        [self.delegate didChangeAdvancedBigEye:params.beautyBigEye];
    
    }

}

- (void)settingsViewController:(AlivcLiveBeautifySettingsViewController *)viewController didChangeUIStyle:(AlivcBeautySettingViewStyle)uiStyle{
    NSInteger level = 0;
    switch (uiStyle) {
        case AlivcBeautySettingViewStyle_ShortVideo_BeautyFace_Base:
            NSLog(@"基础美颜");
            level = [_beautyFaceDataManager_normal getBeautyLevel];
            [self.delegate didChangeCommonMode];
            self.beautyType = AliyunBeautyTypeBase;
            break;
        case AlivcBeautySettingViewStyle_ShortVideo_BeautyFace_Advanced:
            level = [_beautyFaceDataManager_advanced getBeautyLevel];
            NSLog(@"高级美颜");
            [self.delegate didChangeAdvancedMode];
            self.beautyType = AliyunBeautyTypeAdvanced;
            break;
            
        default:
            break;
    }
    //更新ui
    [self.beatyFaceSettingViewControl updateLevel:level];
}


/**
 动图应用上去之后更新UI状态
 */
- (void)refreshUIWhenThePasterInfoApplyedWithIndex:(NSInteger)applyedIndex{
    NSInteger newIndex = applyedIndex;
    if (newIndex != _selectGifIndex) {
         AliyunMagicCameraEffectCell *cell = (AliyunMagicCameraEffectCell *)[self.gifCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:_selectGifIndex inSection:0]];
        if (cell) {
            [cell setApplyed:NO];
        }else{
            //获取不到cell表明用户在下载过程中滑动到其他地方去了
            [self.gifCollectionView reloadData];
        }
        
        NSLog(@"\n动图下载测试把%ld选中设为NO %p\n",_selectGifIndex,cell);
    }
    if (newIndex < self.effectItems.count) {
        AliyunMagicCameraEffectCell *cell = (AliyunMagicCameraEffectCell *)[self.gifCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:newIndex inSection:0]];
        if (cell) {
            [cell setApplyed:YES];
            cell.downloadImageView.hidden = YES;
        }else{
            //获取不到cell表明用户在下载过程中滑动到其他地方去了
            [self.gifCollectionView reloadData];
        }
        _selectGifIndex = newIndex;
        NSLog(@"\n动图下载测试把%ld选中设为YES %p\n",_selectGifIndex,cell);
    }    
}

/**
 根据新的动图数组刷新ui
 
 @param effectItems 新的动图数组
 */
- (void)refreshUIWithGifItems:(NSArray *)effectItems{
    self.effectItems = effectItems;
    [self.gifCollectionView reloadData];
}


/**
 根据新的mv数组刷新ui
 
 @param mvItems 新的mv数组
 */
- (void)refreshUIWithMVItems:(NSArray *)mvItems{
    self.mvItems = [[NSMutableArray alloc]initWithArray:mvItems];
    [self.mvCollectionView reloadData];
}


#pragma mark -  Observer

- (void)addObserver{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)willResignActive{
    [[FUMusicPlayer sharePlayer] stop];
}


- (void)didBecomeActive{
    if (self.buttonTag == musicIndx && _itemSelIndex != 0) {
    [[FUMusicPlayer sharePlayer] playMusic:@"douyin.mp3"];
    }
}

-(void)dealloc{
     [[FUMusicPlayer sharePlayer] stop];
}

@end
