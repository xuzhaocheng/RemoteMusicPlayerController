RemoteMusicPlayerController
===========================
## Introduction
`RemoteMusicPlayerController` makes it simple to play audio with URL.
You can get rid of syncing slider and player buttons.

## Usage
You create yourself `playButton`, `pauseButton`, `slider`, `currentTimeLabel` in your view controller.
Note that each of them is optional, cause you may not need `slider` or `currentTimeLabel`, etc. 
```objective-c
self.player = [[RemoteMusicPlayerController alloc] init];
self.player.playButton = self.playButton;
self.player.pauseButton = self.pauseButton;
self.player.slider = self.slider;
self.player.currentTimeLabel = self.currentTimeLabel;
NSString *urlString = @"";
[self.player loadAssetWithURLString:urlString];
```

There are also two delegate methods to help you do something you might want.
```objective-c
@protocol RemoteMusicPlayerDelegate <NSObject>
- (void)playerItemDidGetReadyToPlay;
- (void)playerCurrentTimeUpdate:(float)currentTime;
@end
```
