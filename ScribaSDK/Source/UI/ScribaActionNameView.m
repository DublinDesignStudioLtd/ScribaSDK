

#import "ScribaActionNameView.h"

#define kWDActionNameFadeDelay          0.666f
#define kWDActionNameFadeOutDuration    0.2f
#define kWDActionNameCornerRadius       9

@implementation ScribaActionNameView

@synthesize titleLabel;
@synthesize messageLabel;

static ScribaActionNameView *scribaActionNameView = nil;

+ (ScribaActionNameView *) sharedInstance
{
    
    if (!scribaActionNameView) {
        scribaActionNameView = [[ScribaActionNameView alloc] initWithFrame:CGRectMake(0,0,180,60)];
    }
    
    return scribaActionNameView;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (!self) {
        return nil;
    }
    
    self.opaque = NO;
    self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5f];
    self.autoresizesSubviews = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin |
        UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    CALayer *layer = self.layer;
    layer.cornerRadius = kWDActionNameCornerRadius;
    
    frame = CGRectInset(self.bounds, 10, 5);
    frame.size.height /= 2;
    self.titleLabel = [[UILabel alloc] initWithFrame:frame];
    titleLabel.font = [UIFont boldSystemFontOfSize:20.0f];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.backgroundColor = nil;
    titleLabel.opaque = NO;
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.shadowColor = [UIColor blackColor];
    titleLabel.shadowOffset = CGSizeMake(0,1);
    [self addSubview:titleLabel];
    
    frame = CGRectOffset(frame, 0, CGRectGetHeight(frame));
    self.messageLabel = [[UILabel alloc] initWithFrame:frame];
    messageLabel.font = [UIFont systemFontOfSize:17.0f];
    messageLabel.textAlignment = NSTextAlignmentCenter;
    messageLabel.backgroundColor = nil;
    messageLabel.opaque = NO;
    messageLabel.textColor = [UIColor whiteColor];
    messageLabel.adjustsFontSizeToFitWidth = YES;
    [self addSubview:messageLabel];
    
    return self;
}

- (void) fadeOut:(id)obj
{
    [UIView animateWithDuration:kWDActionNameFadeOutDuration animations:^{
        self.alpha = 0.0f;
        self.transform = CGAffineTransformMakeScale(0.01f, 0.01f);
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        scribaActionNameView = nil;
    }];
}

- (void) setConnectedDeviceName:(NSString *)deviceName inViewController:(UIViewController*)vc
{
    if(![self promptScribaActivityAlert:vc])
    {
        return;
    }
    
    titleLabel.text = NSLocalizedString(@"Connected", @"Connected");
    messageLabel.text = deviceName;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(fadeOut:) withObject:nil afterDelay:kWDActionNameFadeDelay];
}

- (void) setDisconnectedDeviceName:(NSString *)deviceName inViewController:(UIViewController*)vc
{
    if(![self promptScribaActivityAlert:vc])
    {
        return;
    }
    
    titleLabel.text = NSLocalizedString(@"Disconnected", @"Disconnected");
    messageLabel.text = deviceName;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(fadeOut:) withObject:nil afterDelay:kWDActionNameFadeDelay];
}

- (BOOL) promptScribaActivityAlert:(UIViewController*)vc
{
    if (vc && vc.view)
    {
        [vc.view addSubview:self];
        self.center = CGPointMake(CGRectGetMidX(vc.view.bounds), CGRectGetMidY(vc.view.bounds));
        return YES;
    }
    else
    {
        NSLog(@"No view controller available to promot scriba alert");
        return NO;
    }

}


@end

