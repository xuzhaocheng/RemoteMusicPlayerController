//
//  ViewController.m
//  AVPlayerControllerDemo
//
//  Created by xuzhaocheng on 14/11/25.
//  Copyright (c) 2014年 xuzhaocheng. All rights reserved.
//

#import "ViewController.h"
#import "RemoteMusicPlayerController.h"
#import <MediaPlayer/MediaPlayer.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *pauseButton;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (nonatomic, strong) RemoteMusicPlayerController *player;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.player = [[RemoteMusicPlayerController alloc] initWithBackgroundModeEnabled:YES];
    self.player.playButton = self.playButton;
    self.player.pauseButton = self.pauseButton;
    self.player.slider = self.slider;
    self.player.currentTimeLabel = self.currentTimeLabel;
    
    NSDictionary *nowPlaying = @{ MPMediaItemPropertyArtist: @"Test Atrtist",
                                  MPMediaItemPropertyAlbumTitle: @"Test Title" };

    self.player.artworkInfo = nowPlaying;
    [self.player loadAssetWithURLString:@"http://img3.dangdang.com/newimages/music/online/zgx_wmzt.mp3"];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
    [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    [self.player remoteControlReceivedWithEvent:event];
}


- (IBAction)play:(id)sender {
    [self.player play];
}

- (IBAction)pause:(id)sender {
    [self.player pause];
}

- (IBAction)beginSliding:(id)sender {
    [self.player beginSliding:sender];
}

- (IBAction)sliding:(id)sender {
    [self.player sliding:sender];
}

- (IBAction)endSliding:(id)sender {
    [self.player endSliding:sender];
}

@end
