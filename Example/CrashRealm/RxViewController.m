//
//  RxViewController.m
//  CrashRealm
//
//  Created by retval on 08/21/2019.
//  Copyright (c) 2019 retval. All rights reserved.
//

#import "RxViewController.h"
#import "RxConversation.h"
#import <Realm/Realm.h>
#import "RxScheduler.h"
#import <GameKit/GameKit.h>

static const NSUInteger __kRxTestArrayCapacity = 100;
static const NSUInteger __kRxTestSchedulerCapacity = 4;

@interface RxViewController () {
    NSString *_convsationIDs[__kRxTestArrayCapacity];
    NSString *_message_ids[__kRxTestArrayCapacity][__kRxTestArrayCapacity];
    RxScheduler *_schedulers[__kRxTestSchedulerCapacity];
    RxScheduler *_randomSchedulers[__kRxTestSchedulerCapacity];
    RLMNotificationToken *_testConversationTokens[__kRxTestArrayCapacity];
    RLMNotificationToken *_testMessagesToken[__kRxTestArrayCapacity];
    id<RxSchedulerCancellable> _schedulerToken;
    RxScheduler *_main;
}
@property (strong, nonatomic, readonly) NSString *conversationID;

@end

@implementation RxViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self __configureDataSources];
    [self __configureSchedulers];
    [self __resetDB];
    [self __initDB];
    _main = [RxScheduler schedulerWithRunLoop:[NSRunLoop currentRunLoop]];
    _schedulerToken = [_main after:[NSDate dateWithTimeIntervalSinceNow:0.1] repeatingEvery:1.0 withLeeway:0.1 schedule:^{
        for (NSInteger idx = 0; idx < __kRxTestArrayCapacity; idx++) {
            [self __startJob:idx];
        }
    }];
}

- (void)__configureSchedulers {
    for (NSUInteger idx = 0; idx < __kRxTestSchedulerCapacity; idx++) {
        _schedulers[idx] = [RxScheduler schedulerWithRunLoop:nil name:[NSString stringWithFormat:@"%@", @(idx)]];
        _randomSchedulers[idx] = [RxScheduler schedulerWithRunLoop:nil name:[NSString stringWithFormat:@"io-%@", @(idx)]];
    }
}

- (void)__configureDataSources {
    for (NSUInteger idx = 0; idx < __kRxTestArrayCapacity; idx++) {
        _convsationIDs[idx] = [[NSUUID UUID] UUIDString];
        for (NSUInteger messageIdx = 0; messageIdx < __kRxTestArrayCapacity; messageIdx++) {
            _message_ids[idx][messageIdx] = [[NSUUID UUID] UUIDString];
        }
    }
}

- (void)__resetDB {
    @autoreleasepool {
        RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
        NSLog(@"%@", configuration.fileURL.path);
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm transactionWithBlock:^{
            [realm deleteAllObjects];
        }];
    }
}

- (void)__initDB {
    @autoreleasepool {
        RLMRealm *realm = [RLMRealm defaultRealm];
        for (NSUInteger idx = 0; idx < __kRxTestArrayCapacity; idx++) {
            [self __initJob:idx inRealm:realm];
        }
    }
}

- (void)__initJob:(NSUInteger)idx inRealm:(RLMRealm *)realm {
    @autoreleasepool {
        [realm transactionWithBlock:^{
            RxConversation *conversation = [[RxConversation alloc] init];
            conversation.ID = _convsationIDs[idx];
            NSMutableArray<RxMessage *> *messages = [NSMutableArray new];
            for (NSUInteger messageIdx = 0; messageIdx < __kRxTestArrayCapacity; messageIdx++) {
                RxMessage *message = [[RxMessage alloc] init];
                message.ID = _message_ids[idx][messageIdx];
                message.conversationID = _convsationIDs[idx];
                [messages addObject:message];
            }
            [conversation.messageIDs addObjects:[NSArray arrayWithObjects:_message_ids[idx] count:100]];
            [realm addOrUpdateObjects:messages];
            [realm addOrUpdateObject:conversation];
            
            messages = nil;
            conversation = nil;
        }];
    }
}

- (void)__initConversationJob:(NSUInteger)idx {
    @autoreleasepool {
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm transactionWithBlock:^{
            RxConversation *conversation = [[RxConversation alloc] init];
            conversation.ID = _convsationIDs[idx];
            [conversation.messageIDs addObjects:[[NSArray arrayWithObjects:_message_ids[idx] count:100] shuffledArray]];
            [realm addOrUpdateObject:conversation];
            conversation = nil;
        }];
    }
}

- (void)__resetJob:(NSUInteger)idx {
    NSParameterAssert(idx < __kRxTestArrayCapacity);
    [_randomSchedulers[arc4random() % __kRxTestSchedulerCapacity] schedule:^{
        RLMRealm *database = [RLMRealm defaultRealm];
        NSString *convsationID = _convsationIDs[idx];
        [database transactionWithBlock:^{
            RxConversation *conversation = [RxConversation objectForPrimaryKey:convsationID];
            if (!conversation) {
                return;
            }
            [database deleteObject:conversation];
        }];
    }];
}

- (void)__notifyJob:(NSUInteger)idx {
    NSParameterAssert(idx < __kRxTestArrayCapacity);
    [_schedulers[arc4random() % __kRxTestSchedulerCapacity] schedule:^{
        NSString *convsationID = _convsationIDs[idx];
        NSMutableArray<RLMNotificationToken *> *tokens = [NSMutableArray new];
        [self __doJobWithCID:convsationID tokens:tokens];
        _testConversationTokens[idx] = tokens[0];
        _testMessagesToken[idx] = tokens[1];
        [tokens removeAllObjects];
    }];
}

- (void)__startJob:(NSUInteger)idx {
    NSParameterAssert(idx < __kRxTestArrayCapacity);
    __block BOOL flip = NO;
    [_schedulers[arc4random() % __kRxTestSchedulerCapacity] schedule:^{
        [self __notifyJob:idx];
    }];
    
    [_randomSchedulers[arc4random() % __kRxTestSchedulerCapacity] schedule:^{
        if (flip) {
            [self __resetJob:idx];
        } else {
            [self __initConversationJob:idx];
        }
        flip = !flip;
    }];
}

- (void)__doJobWithCID:(NSString *)cid tokens:(NSMutableArray<RLMNotificationToken *> *)tokens {
    RxConversation *conversation = [RxConversation objectForPrimaryKey:cid];
    NSParameterAssert(conversation);
    __weak RxConversation *wc = conversation;
    [tokens addObject:[conversation addNotificationBlock:^(BOOL deleted, NSArray<RLMPropertyChange *> * _Nullable changes, NSError * _Nullable error) {
        if (deleted) {
            return;
        }
        if (error) {
            return;
        }
        RxConversation *sc = wc;
        if (!sc) {
            return;
        }
        NSCParameterAssert(sc.invalidated == NO);
    }]];
    [tokens addObject:[conversation.messageIDs addNotificationBlock:^(RLMArray * _Nullable array, RLMCollectionChange * _Nullable changes, NSError * _Nullable error) {
        if (error) {
            return;
        }
        RxConversation *sc = wc;
        if (!sc) {
            return;
        }
        if ([sc isInvalidated]) {
            return;
        }
        NSCParameterAssert(array.invalidated == NO);
    }]];
    conversation = nil;
}

@end
