//
//  OrderFile.m
//  FuntionGrouping
//
//  Created by ChenZhen on 2020/12/22.
//

#import "OrderFile.h"
#import <dlfcn.h>
#import <libkern/OSAtomicQueue.h>
#include <sanitizer/coverage_interface.h>

static OSQueueHead symbolQueue = OS_ATOMIC_QUEUE_INIT;

static BOOL isFinished = NO;

typedef struct {
    void *pc;
    void *next;
} PCNode;

// This callback is inserted by the compiler as a module constructor
// into every DSO. 'start' and 'stop' correspond to the
// beginning and end of the section with the guards for the entire
// binary (executable or DSO). The callback will be called at least
// once per DSO and may be called multiple times with the same parameters.
void __sanitizer_cov_trace_pc_guard_init(uint32_t *start,
                                                    uint32_t *stop) {
  static uint32_t N;  // Counter for the guards.
  if (start == stop || *start) return;  // Initialize only once.
  for (uint32_t *x = start; x < stop; x++)
    *x = ++N;  // Guards should start from 1.
}

// This callback is inserted by the compiler on every edge in the
// control flow (some optimizations apply).
// Typically, the compiler will emit the code like this:
//    if(*guard)
//      __sanitizer_cov_trace_pc_guard(guard);
// But for large functions it will emit a simple call:
//    __sanitizer_cov_trace_pc_guard(guard);
void __sanitizer_cov_trace_pc_guard(uint32_t *guard) {
    if (isFinished) return;
    //注释掉这行方法，不注释的话无法获取到load方法，执行load方法是*guard值为0
//  if (!*guard) return;  // Duplicate the guard check.
  // If you set *guard to 0 this code will not be called again for this edge.
  // Now you can get the PC and do whatever you want:
  //   store it somewhere or symbolize it and print right away.
  // The values of `*guard` are as you set them in
  // __sanitizer_cov_trace_pc_guard_init and so you can make them consecutive
  // and use them to dereference an array or a bit vector.
    void *PC = __builtin_return_address(0);
    PCNode *node = malloc(sizeof(PCNode));
    *node = (PCNode){PC, NULL};
    OSAtomicEnqueue(&symbolQueue, node, offsetof(PCNode, next));
}

@implementation OrderFile

+ (void)parseSymbolToFile:(NSString *)path {
    [self parseSymbolToFile:path success:nil fail:nil];
}

+ (NSString * _Nonnull)defaultFilePath {
    return [NSTemporaryDirectory() stringByAppendingPathComponent:@"app.order"];
}

+ (void)parseSymbolToFile {
    [self parseSymbolToFile:[self defaultFilePath]];
}

+ (void)parseSymbolToFileWithSuccess:(__nullable Completion)success
                                fail:(__nullable Completion)fail {
    [self parseSymbolToFile:[self defaultFilePath] success:success fail:fail];
}

+ (void)parseSymbolToFile:(NSString *)path
                  success:(void (^)(void))success
                     fail:(void (^)(void))fail {
    isFinished = YES;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSMutableArray<NSString *> * symbolNames = @[].mutableCopy;
        NSMutableDictionary *addressMap = @{}.mutableCopy;
        while (true) {
            PCNode * node = OSAtomicDequeue(&symbolQueue, offsetof(PCNode, next));
            if (node == NULL) {
                break;
            }
            
            // 执行dladdr（）之前，先对虚拟地址进行过滤
            // 相同的虚拟地址只解析一次
            NSString *address = [NSString stringWithFormat:@"%p", node->pc];
            if ([addressMap valueForKey:address]) {
                continue;
            }
            [addressMap setValue:address forKey:address];
            
            // 根据虚拟地址，解析符号相关的信息
            Dl_info info;
            dladdr(node->pc, &info);
            
            if (!info.dli_sname) {
                continue;
            }
            
            NSString * name = [NSString stringWithUTF8String:info.dli_sname];
            
            // 添加 _
            BOOL isObjc = [name hasPrefix:@"+["] || [name hasPrefix:@"-["];
            // C 函数命名规约
            NSString * symbolName = isObjc ? name : [@"_" stringByAppendingString:name];
            
            //去重
            if (![symbolNames containsObject:symbolName]) {
                [symbolNames addObject:symbolName];
            }
        }

        // 符号逆序处理，因为原子队列，结点入队内部采用头插法入队
        NSArray * symbolAry = [[symbolNames reverseObjectEnumerator] allObjects];
        
        //将结果写入到文件
        NSString * funcString = [symbolAry componentsJoinedByString:@"\n"];
        
        NSData * fileContents = [funcString dataUsingEncoding:NSUTF8StringEncoding];
        BOOL result = [[NSFileManager defaultManager] createFileAtPath:path contents:fileContents attributes:nil];
        if (result) {
            if (success) {
                success();
            }
        } else {
            if (fail) {
                fail();
            }
        }
    });
}

@end
