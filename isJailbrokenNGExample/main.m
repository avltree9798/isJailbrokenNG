//
//  main.m
//  isJailbrokenNGExample
//
//  Created by Anthony Viriya on 11/6/22.
//

#import <UIKit/UIKit.h>
#import "isJailbrokenNG.h"
#import "AppDelegate.h"

int main(int argc, char * argv[]) {
    NSString * appDelegateClassName;
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([AppDelegate class]);
    }
    HIDE_CODE;
    isJailbroken(true);
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
