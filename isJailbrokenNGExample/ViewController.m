//
//  ViewController.m
//  isJailbrokenNGExample
//
//  Created by Anthony Viriya on 11/6/22.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController
- (IBAction)mainButton:(UIButton *)sender {
    UIAlertController * alert = [UIAlertController alertControllerWithTitle : @"Alert"
                                                                    message : @"Application is working"
                                                             preferredStyle : UIAlertControllerStyleAlert];

    UIAlertAction * ok = [UIAlertAction
                          actionWithTitle:@"OK"
                          style:UIAlertActionStyleDefault
                          handler:^(UIAlertAction * action)
                          { }];

    [alert addAction:ok];
    ViewController* viewController = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [viewController presentViewController:alert animated:YES completion:nil];
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}


@end
