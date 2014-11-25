//
//  AVPlayerController.h
//  AVPlayerControllerDemo
//
//  Created by xuzhaocheng on 14/11/25.
//  Copyright (c) 2014年 xuzhaocheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol RemoteMusicPlayerDelegate <NSObject>
- (void)playerItemDidGetReadyToPlay;
- (void)playerCurrentTimeUpdate:(float)currentTime;
@end

@interface RemoteMusicPlayerController : NSObject

@property (nonatomic, weak) id <RemoteMusicPlayerDelegate> delegate;

@property (nonatomic, weak) UISlider *slider;
@property (nonatomic, weak) UIButton *playButton;
@property (nonatomic, weak) UIButton *pauseButton;
@property (nonatomic, weak) UILabel *currentTimeLabel;

@property (nonatomic, strong) UIColor *disabledColor;
@property (nonatomic, strong) UIColor *enabledColor;

- (void)loadAssetWithURLString:(NSString *)urlString;
- (void)play;
- (void)pause;

- (BOOL)isPlaying;
- (CMTime)playerItemDuration;

- (void)beginSliding:(UISlider *)slider;
- (void)endSliding:(UISlider *)slider;
- (void)sliding:(UISlider *)slider;

@end
