
#import <UIKit/UIKit.h>

@interface ScribaActionNameView : UIView
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UILabel *messageLabel;

+ (ScribaActionNameView *) sharedInstance;

- (void) setConnectedDeviceName:(NSString *)deviceName inViewController:(UIViewController*)vc;
- (void) setDisconnectedDeviceName:(NSString *)deviceName inViewController:(UIViewController*)vc;

@end

