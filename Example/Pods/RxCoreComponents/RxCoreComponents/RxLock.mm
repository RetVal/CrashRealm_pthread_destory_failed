//
//  RxLock.m
//  RxCoreComponents
//
//  Created by closure on 3/1/17.
//  Copyright © 2017 closure. All rights reserved.
//

#import <RxCoreComponents/RxLock.h>
#include <RxFoundation/RxFoundation.h>

@interface RxLock () {
@private
    Rx::MutexLock _mutex;
}
@end

@implementation RxLock

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

- (void)withCriticalScope:(NS_NOESCAPE void (^)(void))block {
    Rx::LockGuard<Rx::MutexLock> lock(_mutex);
    block();
}

- (void)lock {
    _mutex.lock();
}

- (void)unlock {
    _mutex.unlock();
}

@end

@interface __RxReadWriteReadLock : NSObject <RxLocking> {
    Rx::SharedPtr<Rx::ReadWriteLock> _rwl;
}
- (instancetype)initWithImp:(Rx::SharedPtr<Rx::ReadWriteLock>)imp;
@end

@interface __RxReadWriteWriteLock : NSObject <RxLocking> {
    Rx::SharedPtr<Rx::ReadWriteLock> _rwl;
}
- (instancetype)initWithImp:(Rx::SharedPtr<Rx::ReadWriteLock>)imp;
@end

@implementation __RxReadWriteReadLock

- (instancetype)initWithImp:(Rx::SharedPtr<Rx::ReadWriteLock>)imp {
    if (self = [super init]) {
        _rwl = imp;
    }
    return self;
}

- (void)lock {
    _rwl->lockRead();
}

- (void)unlock {
    _rwl->unlockRead();
}

- (BOOL)tryLock {
    return _rwl->tryLockRead();
}

- (void)withCriticalScope:(NS_NOESCAPE void(^)(void))block {
    if (!block) {
        return;
    }
    [self lock];
    block();
    [self unlock];
}

@end

@implementation __RxReadWriteWriteLock

- (instancetype)initWithImp:(Rx::SharedPtr<Rx::ReadWriteLock>)imp {
    if (self = [super init]) {
        _rwl = imp;
    }
    return self;
}

- (void)lock {
    _rwl->lockWrite();
}

- (void)unlock {
    _rwl->unlockWrite();
}

- (BOOL)tryLock {
    return _rwl->tryLockWrite();
}

- (void)withCriticalScope:(NS_NOESCAPE void(^)(void))block {
    if (!block) {
        return;
    }
    [self lock];
    block();
    [self unlock];
}

@end

@interface RxReadWriteLock () {
@private
    Rx::SharedPtr<Rx::ReadWriteLock> _rwl;
    id<RxLocking> _readLock;
    id<RxLocking> _writeLock;
}

@end

@implementation RxReadWriteLock

+ (instancetype)new {
    return [[self alloc] init];
}

- (instancetype)init {
    return [self initWithName:nil];
}

- (instancetype)initWithName:(NSString *)name {
    if (self = [super init]) {
        _rwl = Rx::MakeShareable<Rx::ReadWriteLock>();
        _name = [name copy];
        _readLock = [[__RxReadWriteReadLock alloc] initWithImp:_rwl];
        _writeLock = [[__RxReadWriteWriteLock alloc] initWithImp:_rwl];
    }
    return self;
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"<%@ %p: %@>", self.class, self, self.name];
}

- (BOOL)isWriting {
    return _rwl->isWriting();
}

- (BOOL)isReading {
    return _rwl->isReading();
}

@end
