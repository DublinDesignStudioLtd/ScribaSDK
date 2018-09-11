//
//  ScribaTransparentViewController.m
//  ScribaSDK
//
//  Created by lei_zhang on 10/22/16.
//  Copyright © 2016 Scriba. All rights reserved.
//

#import "ScribaTransparentViewController.h"

@interface ScribaTransparentViewController ()

@end

@implementation ScribaTransparentViewController

@synthesize scribaActionNameView;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor clearColor];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark private methods
- (ScribaActionNameView *) scribaActionNameView
{
    if (!scribaActionNameView) {
        scribaActionNameView = [[ScribaActionNameView alloc] initWithFrame:CGRectMake(0,0,180,60)];
        [self.view addSubview:self.scribaActionNameView];
        
        scribaActionNameView.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
        scribaActionNameView.delegate = self;
    }
    
    return scribaActionNameView;
}

- (void) stylusConnected:(CBPeripheral *)peripheral
{
    [self.scribaActionNameView setConnectedDeviceName:peripheral.name];
}

- (void) stylusDisconnected:(CBPeripheral *)peripheral
{
    [self.scribaActionNameView setDisconnectedDeviceName:peripheral.name];
}

#pragma mark ScribaActionNameViewDelegate
- (void) fadingOutScribaActionNameView:(ScribaActionNameView *)actionNameView
{
    scribaActionNameView = nil;
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
