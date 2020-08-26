//
//  GCDTestViewController.m
//  ConcurrencyDemo
//
//  Created by LongMa on 2020/8/26.
//  Copyright © 2020 Hossam Ghareeb. All rights reserved.
//

#import "GCDTestViewController.h"

@interface GCDTestViewController ()

@end

@implementation GCDTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"2s后执行");
    });
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
