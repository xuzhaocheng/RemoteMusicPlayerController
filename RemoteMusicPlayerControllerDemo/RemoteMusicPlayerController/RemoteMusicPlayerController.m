//
//  AVPlayerController.m
//  AVPlayerControllerDemo
//
//  Created by xuzhaocheng on 14/11/25.
//  Copyright (c) 2014年 xuzhaocheng. All rights reserved.
//

#import "RemoteMusicPlayerController.h"
#import <MediaPlayer/MediaPlayer.h>

@interface RemoteMusicPlayerController ()

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) id timeObserver;
@property (nonatomic) float restoreAfterSlidingRate;

@end

#define kTrackKey       @"tracks"
#define kStatusKey      @"status"
#define kPlayableKey    @"playable"
#define kRateKey        @"rate"

static const NSString *ItemStatusContext;
static const NSString *PlayerRateContext;

@implementation RemoteMusicPlayerController

#pragma mark - Properties
- (void)setEnableBackgroundMode:(BOOL)enableBackgroundMode
{
    _enableBackgroundMode = enableBackgroundMode;
    if (_enableBackgroundMode) {
        [self enableBackgroundPlaying];
    } else {
        [self disableBackgroundPlaying];
    }
}

- (void)setArtworkInfo:(NSDictionary *)artworkInfo
{
    _artworkInfo = artworkInfo;
    if ([MPNowPlayingInfoCenter class]) {
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:artworkInfo];
    }
}

- (UIColor *)disabledColor
{
    if (!_disabledColor) {
        _disabledColor = [UIColor grayColor];
    }
    return _disabledColor;
}

- (UIColor *)enabledColor
{
    if (!_enabledColor) {
        _enabledColor = [UIColor blackColor];
    }
    return _enabledColor;
}


#pragma mark - Life Cycle

- (id)initWithBackgroundModeEnabled:(BOOL)enabled
{
    self = [super init];
    if (self) {
        self.enableBackgroundMode = enabled;
    }
    return self;
}

- (void)dealloc
{
    [self removePlayerTimeObserver];
    if (self.player) {
        [self.player removeObserver:self forKeyPath:kRateKey context:&PlayerRateContext];
    }
    
    if (self.playerItem) {
        [self.playerItem removeObserver:self forKeyPath:kStatusKey context:&ItemStatusContext];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    NSLog(@"Player dealloc");
}


#pragma mark - Methods

- (void)loadAssetWithURLString:(NSString *)urlString
{
    [self syncUI];
    NSURL *url = [NSURL URLWithString:urlString];
    
    AVAsset *asset = [AVAsset assetWithURL:url];
    NSArray *requestKeys = @[kTrackKey, kPlayableKey];
    [asset loadValuesAsynchronouslyForKeys:requestKeys
                         completionHandler:^{
                             [self prepareToPlayAsset:asset withKeys:requestKeys];
                         }];
}

- (void)prepareToPlayAsset:(AVAsset *)asset withKeys:(NSArray *)requestKeys
{
    for (NSString *key in requestKeys) {
        NSError *error = nil;
        if ([asset statusOfValueForKey:key error:&error] == AVKeyValueStatusFailed) {
            [self assetFailedToPrepareForPlayback:error];
        }
    }
    
    if (!asset.playable) {
        NSString *localizedDescription = NSLocalizedString(@"Item cannot be played", @"Item cannot be played description");
        NSString *localizedFailureReason = NSLocalizedString(@"The assets tracks were loaded, but could not be make playable.", @"Item cannot be played failure reason");
        NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                   localizedDescription, NSLocalizedDescriptionKey,
                                   localizedFailureReason, NSLocalizedFailureReasonErrorKey, nil];
        NSError *cannotBePlayedError = [NSError errorWithDomain:@"AVPlayer" code:0 userInfo:errorDict];
        [self assetFailedToPrepareForPlayback:cannotBePlayedError];
    }
    
    if (self.playerItem) {
        [self.playerItem removeObserver:self forKeyPath:kStatusKey context:&ItemStatusContext];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
    }
    
    self.playerItem = [[AVPlayerItem alloc] initWithAsset:asset];
    [self.playerItem addObserver:self
                      forKeyPath:kStatusKey
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:&ItemStatusContext];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.playerItem];
    
    if (!self.player) {
        self.player = [[AVPlayer alloc] initWithPlayerItem:self.playerItem];
        [self.player addObserver:self
                      forKeyPath:kRateKey
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:&PlayerRateContext];
    }
    
    if (self.player.currentItem != self.playerItem) {
        [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
        [self.player pause];
        [self syncUI];
    }
}

- (BOOL)isPlaying
{
    return self.player.rate;
}

- (CMTime)playerItemDuration
{
    AVPlayerItem *thePlayerItem = self.player.currentItem;
    if (thePlayerItem.status == AVPlayerItemStatusReadyToPlay) {
        return thePlayerItem.duration;
    }
    return kCMTimeInvalid;
}

- (void)play
{
    [self.player play];
}

- (void)pause
{
    [self.player pause];
}

- (void)beginSliding:(UISlider *)slider
{
    self.restoreAfterSlidingRate = self.player.rate;
    [self.player pause];
    [self removePlayerTimeObserver];
}

- (void)endSliding:(UISlider *)slider
{
    if (!self.timeObserver) {
        CMTime playerDuration = [self playerItemDuration];
        if (CMTIME_IS_INVALID(playerDuration)) {
            return;
        }
        
        double duration = CMTimeGetSeconds(playerDuration);
        if (isfinite(duration)) {
            CGFloat width = CGRectGetWidth(slider.bounds);
            double interval = .5 * duration / width;
            [self addPlayerTimeObserverWithInterval:interval];
        }
    }
    
    self.player.rate = self.restoreAfterSlidingRate ? self.restoreAfterSlidingRate : 0.f;
}

- (void)sliding:(UISlider *)slider
{
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        double minValue = slider.minimumValue;
        double maxValue = slider.maximumValue;
        double time = duration * (slider.value - minValue) / (maxValue - minValue);
        [self.player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];
    }
}


#pragma mark - Background Playing
- (void)enableBackgroundPlaying
{
    NSError *sessionError = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
                                     withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker
                                           error:&sessionError];
    if (sessionError) {
        NSLog(@"Cannot enable background playing mode. Error: %@", sessionError);
        return;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleInterruption:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:[AVAudioSession sharedInstance]];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMediaServicesReset:)
                                                 name:AVAudioSessionMediaServicesWereResetNotification
                                               object:[AVAudioSession sharedInstance]];
}

- (void)disableBackgroundPlaying
{
    NSError *sessionError = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategorySoloAmbient
                                     withOptions:AVAudioSessionCategoryOptionMixWithOthers
                                           error:&sessionError];
    if (sessionError) {
        NSLog(@"Cannot disable background playing mode. Error: %@", sessionError);
        return;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVAudioSessionInterruptionNotification
                                                  object:[AVAudioSession sharedInstance]];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVAudioSessionMediaServicesWereResetNotification
                                                  object:[AVAudioSession sharedInstance]];
    
}

#pragma mark -AVAudioSession Notifications
- (void)handleInterruption: (NSNotification *)notification
{
    NSNumber *interruptionType = [[notification userInfo] objectForKey:AVAudioSessionInterruptionTypeKey];
    NSNumber *interruptionOption = [[notification userInfo] objectForKey:AVAudioSessionInterruptionOptionKey];
    
    switch (interruptionType.unsignedIntegerValue) {
        case AVAudioSessionInterruptionTypeBegan:{
            // • Audio has stopped, already inactive
            // • Change state of UI, etc., to reflect non-playing state
            [self syncUI];
        } break;
        case AVAudioSessionInterruptionTypeEnded:{
            // • Make session active
            // • Update user interface
            // • AVAudioSessionInterruptionOptionShouldResume option
            if (interruptionOption.unsignedIntegerValue == AVAudioSessionInterruptionOptionShouldResume) {
                // Here you should continue playback.
                [self.player play];
            }
        } break;
        default:
            break;
    }
}

- (void)handleMediaServicesReset:(NSNotification *)notification
{
    // • No userInfo dictionary for this notification
    // • Audio streaming objects are invalidated (zombies)
    // • Handle this notification by fully reconfiguring audio
    self.playerItem = nil;
    self.player = nil;
    [self syncUI];
}


#pragma mark -Remote Control

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent
{
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        switch (receivedEvent.subtype) {
            case UIEventSubtypeRemoteControlTogglePlayPause:
                [self isPlaying] ? [self.player pause] : [self.player play];
                break;
            case UIEventSubtypeRemoteControlPlay:
                [self.player play];
                break;
            case UIEventSubtypeRemoteControlPause:
                [self.player pause];
            case UIEventSubtypeRemoteControlBeginSeekingBackward:
            case UIEventSubtypeRemoteControlEndSeekingBackward:
            case UIEventSubtypeRemoteControlBeginSeekingForward:
            case UIEventSubtypeRemoteControlEndSeekingForward:
            case UIEventSubtypeRemoteControlNextTrack:
            case UIEventSubtypeRemoteControlPreviousTrack:
            case UIEventSubtypeRemoteControlStop:
            default:
                break;
        }
    }
}


#pragma mark - UI
- (void)syncUI
{
    [self syncPlayerButtons];
    [self syncPlayPauseButtons];
    [self syncSlider];
}


#pragma mark -Slider

- (void)initSliderTimer
{
    double interval = .1;
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        self.currentTimeLabel.text = @"00:00";
        CGFloat width = CGRectGetWidth(self.slider.bounds);
        interval = .5 * duration / width;
    }
    
    [self addPlayerTimeObserverWithInterval:interval];
}


- (void)syncSlider
{
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        self.slider.value = 0.f;
        self.currentTimeLabel.text = @"--:--";
        [self disableSlider];
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        double minValue = [self.slider minimumValue];
        double maxValue = [self.slider maximumValue];
        double time = CMTimeGetSeconds(self.player.currentTime);
        self.currentTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", (int)time / 60, (int)time % 60];
        self.slider.value = (maxValue - minValue) * time / duration + minValue;
    }
}

- (void)disableSlider
{
    self.slider.enabled = NO;
    [self.currentTimeLabel setTextColor:self.disabledColor];
}

- (void)enableSlider
{
    self.slider.enabled = YES;
    [self.currentTimeLabel setTextColor:self.enabledColor];
}

#pragma mark -Play Pause Buttons
- (void)syncPlayPauseButtons
{
    if ([self isPlaying]) {
        [self showPauseButton];
    } else {
        [self showPlayButton];
    }
}

- (void)syncPlayerButtons
{
    if (self.playerItem && self.playerItem.status == AVPlayerItemStatusReadyToPlay) {
        [self setPlayerButtonsEnabled:YES];
    } else {
        [self setPlayerButtonsEnabled:NO];
    }
}

- (void)showPauseButton
{
    self.playButton.hidden = YES;
    self.pauseButton.hidden = NO;
}

- (void)showPlayButton
{
    self.playButton.hidden = NO;
    self.pauseButton.hidden = YES;
}

- (void)setPlayerButtonsEnabled:(BOOL)enabled
{
    self.playButton.enabled = enabled;
    self.pauseButton.enabled = enabled;
}


#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &ItemStatusContext && [keyPath isEqualToString:kStatusKey]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self playerItemStatusChanged:[[change objectForKey:NSKeyValueChangeNewKey] integerValue] withObject:object];
        });
    } else if (context == &PlayerRateContext && [keyPath isEqualToString:kRateKey]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self syncPlayPauseButtons];
        });
    }
}


- (void)playerItemStatusChanged:(AVPlayerItemStatus)status withObject:(id)object
{
    [self syncPlayPauseButtons];
    [self syncPlayerButtons];
    switch (status) {
        case AVPlayerItemStatusFailed: {
            AVPlayerItem *thePlayerItem = (AVPlayerItem *)object;
            [self assetFailedToPrepareForPlayback:thePlayerItem.error];
        }
            break;
        case AVPlayerItemStatusReadyToPlay:
            [self enableSlider];
            [self initSliderTimer];
            
            if ([self.delegate respondsToSelector:@selector(playerItemDidGetReadyToPlay)]) {
                [self.delegate playerItemDidGetReadyToPlay];
            }
            
            break;
        case AVPlayerItemStatusUnknown:
            [self removePlayerTimeObserver];
            [self syncSlider];
            [self disableSlider];
            [self setPlayerButtonsEnabled:NO];
            break;
        default:
            break;
    }
}


#pragma mark - Player Time Observer

- (void)addPlayerTimeObserverWithInterval:(double)interval
{
    __weak RemoteMusicPlayerController *weakSelf = self;
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC)
                                                                  queue:dispatch_get_main_queue()
                                                             usingBlock:^(CMTime time) {
                                                                 [weakSelf syncSlider];
                                                                 if ([weakSelf.delegate respondsToSelector:@selector(playerCurrentTimeUpdate:)]) {
                                                                     [weakSelf.delegate playerCurrentTimeUpdate:CMTimeGetSeconds(time)];
                                                                 }
                                                             }];
}

- (void)removePlayerTimeObserver
{
    if (self.timeObserver) {
        [self.player removeTimeObserver:self.timeObserver];
        self.timeObserver = nil;
    }
}

#pragma mark - Handle Error

- (void)assetFailedToPrepareForPlayback:(NSError *)error
{
    [self removePlayerTimeObserver];
    [self syncSlider];
    [self disableSlider];
    [self setPlayerButtonsEnabled:NO];
    
    NSLog(@"%@", error);
}


#pragma mark - Notification

- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    [self.player seekToTime:kCMTimeZero];
}

@end
