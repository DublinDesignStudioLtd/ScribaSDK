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
- (void) stylusConnected:(CBPeripheral *)peripheral
{
}

- (void) stylusDisconnected:(CBPeripheral *)peripheral
{
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
