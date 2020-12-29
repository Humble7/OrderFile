//
//  OrderFile.h
//  FuntionGrouping
//
//  Created by ChenZhen on 2020/12/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^Completion)(NSString *filePath);

@interface OrderFile : NSObject

/// 符号解析
/// @param path Order File 存储路径
+ (void)parseSymbolToFile:(NSString *)path;

/// 符号解析
/// @param path Order File 存储路径
/// @success 存储成功的回调
/// @fail 存储失败的回调
+ (void)parseSymbolToFile:(NSString *)path
                  success:(__nullable Completion)success
                     fail:(__nullable Completion)fail;

/// 符号解析, 默认存储路径为tmp/app.order
/// @success 存储成功的回调
/// @fail 存储失败的回调
+ (void)parseSymbolToFileWithSuccess:(__nullable Completion)success
                                fail:(__nullable Completion)fail;

/// 符号解析, 默认存储路径为tmp/app.order
+ (void)parseSymbolToFile;

@end

NS_ASSUME_NONNULL_END
