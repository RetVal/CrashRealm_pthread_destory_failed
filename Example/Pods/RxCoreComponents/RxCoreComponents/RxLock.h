//
//  RxLock.h
//  RxCoreComponents
//
//  Created by closure on 3/1/17.
//  Copyright © 2017 closure. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol RxLocking <NSLocking>

- (BOOL)tryLock;
- (void)withCriticalScope:(NS_NOESCAPE void(^)(void))block;

@end

@interface RxLock : NSObject <RxLocking>

@property (strong, nonatomic, readonly, nullable) NSString *name;

- (instancetype)init;
- (void)withCriticalScope:(NS_NOESCAPE void(^)(void))block;

@end

@interface RxReadWriteLock : NSObject

@property (strong, nonatomic, readonly) id<RxLocking> readLock;
@property (strong, nonatomic, readonly) id<RxLocking> writeLock;

@property (strong, nonatomic, readonly, nullable) NSString *name;

+ (instancetype)new;
- (instancetype)init;

- (instancetype)initWithName:(NSString *_Nullable)name NS_DESIGNATED_INITIALIZER;

- (BOOL)isWriting;
- (BOOL)isReading;

@end

NS_ASSUME_NONNULL_END
