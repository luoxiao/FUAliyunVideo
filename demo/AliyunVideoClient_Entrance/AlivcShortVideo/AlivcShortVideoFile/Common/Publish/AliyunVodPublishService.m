//
//  AliyunVodPublishService.m
//  qusdk
//
//  Created by Worthy Zhang on 2019/1/2.
//  Copyright © 2019 Alibaba Group Holding Limited. All rights reserved.
//

#import "AliyunVodPublishService.h"

@implementation AliyunVodPublishService

+ (AliyunVodPublishManager *)service {
  static dispatch_once_t onceToken;
  static AliyunVodPublishManager *manager = NULL;
  dispatch_once(&onceToken, ^{
    manager = [[AliyunVodPublishManager alloc] init];
  });
  return manager;
}

@end
