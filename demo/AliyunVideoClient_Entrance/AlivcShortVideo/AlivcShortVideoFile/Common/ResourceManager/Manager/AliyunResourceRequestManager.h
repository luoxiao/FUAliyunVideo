//
//  AliyunResourceRequestManager.h
//  AliyunVideo
//
//  Created by TripleL on 17/3/6.
//  Copyright (C) 2010-2017 Alibaba Group Holding Limited. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface AliyunResourceRequestManager : NSObject



/**
 资源data 数据请求

 @param typeTag 素材类别 参考EffectResourceModel的AliyunEffectType注释
 @param success 成功回调
 @param failure 失败回调
 */
+ (void)requestWithEffectTypeTag:(NSInteger)typeTag
                         success:(void(^)(NSArray *resourceListArray))success
                         failure:(void(^)(NSError *error))failure __deprecated_msg("素材分发服务为官方demo演示使用，无法达到商业化使用程度。请自行搭建相关的服务");

@end
