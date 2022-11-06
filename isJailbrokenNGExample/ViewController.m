//
//  ViewController.m
//  isJailbrokenNGExample
//
//  Created by Anthony Viriya on 11/6/22.
//

#import "ViewController.h"
#import "isJailbrokenNG.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    int jb = isJailbroken();
    NSLog(@"%d", jb);
    // Do any additional setup after loading the view.
}


@end
