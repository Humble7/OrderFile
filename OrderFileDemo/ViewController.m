//
//  ViewController.m
//  OrderFileDemo
//
//  Created by ChenZhen on 2020/12/29.
//

#import "ViewController.h"
#import "OrderFile.h"

typedef void(^Block)(void);

@interface ViewController ()
@property (nonatomic, copy) Block block;
@end

@implementation ViewController

void c_function() {
    
}

+ (void)load {
    c_function();
}

+ (void)initialize {
    [super initialize];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.block = ^{
        NSLog(@"");
    };
    self.block();
    
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
