//
//  ViewController.m
//  OrderFileDemo
//
//  Created by ChenZhen on 2020/12/29.
//

#import "ViewController.h"
#import "OrderFile.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [OrderFile parseSymbolToFileWithSuccess:^{
            [self alertWithContent:@"符号收集成功"];
    } fail:^{
        [self alertWithContent:@"符号收集失败"];
    }];
}

- (void)alertWithContent:(NSString *)content {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController * alert = [UIAlertController
                                    alertControllerWithTitle:@"Order file"
                                    message:content
                                    preferredStyle:UIAlertControllerStyleAlert];
       UIAlertAction* yesButton = [UIAlertAction
                                   actionWithTitle:@"好的"
                                   style:UIAlertActionStyleDefault
                                   handler:nil];

       [alert addAction:yesButton];

       [self presentViewController:alert animated:YES completion:nil];
    });
}

@end
