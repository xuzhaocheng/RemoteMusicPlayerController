//
//  ViewController.m
//  AVPlayerControllerDemo
//
//  Created by xuzhaocheng on 14/11/25.
//  Copyright (c) 2014年 xuzhaocheng. All rights reserved.
//

#import "ViewController.h"
#import "RemoteMusicPlayerController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *pauseButton;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (nonatomic, strong) RemoteMusicPlayerController *player;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.player = [[RemoteMusicPlayerController alloc] init];
    self.player.playButton = self.playButton;
    self.player.pauseButton = self.pauseButton;
    self.player.slider = self.slider;
    self.player.currentTimeLabel = self.currentTimeLabel;
    [self.player loadAssetWithURLString:@"http://img3.dangdang.com/newimages/music/online/zgx_wmzt.mp3"];
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
