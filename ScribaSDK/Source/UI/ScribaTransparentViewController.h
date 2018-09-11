//
//  ScribaTransparentViewController.h
//  ScribaSDK
//
//  Created by lei_zhang on 10/22/16.
//  Copyright © 2016 Scriba. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ScribaActionNameView.h"
#import "ScribaStylusManager.h"

@interface ScribaTransparentViewController : UIViewController <ScribaActionNameViewDelegate>

@property (nonatomic) ScribaActionNameView *scribaActionNameView;

- (void) stylusConnected:(CBPeripheral *)peripheral;
- (void) stylusDisconnected:(CBPeripheral *)peripheral;

@end
