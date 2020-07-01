//
//  ZCStreamCenter.m
//  ZCKit
//
//  Created by admin on 2019/11/3.
//  Copyright © 2018 Squat in house. All rights reserved.
//

#import "ZCStreamCenter.h"
#import <objc/runtime.h>


@class ZCStreamCoat;
static void *ZCSymbolAimOContext = @"ZCSymbolAimOContext";
NSString * const ZCStreamValueInvalid = @"ZCStreamValueInvalid";


@interface ZCStreamUnit : NSObject

@property (nonatomic, weak) id aimObject;

@property (nonatomic, copy) NSString *aimKp;

@property (nonatomic, assign) BOOL isObserveAimObject;

@end

@implementation ZCStreamUnit

- (instancetype)initWithBindObject:(id)bindObject keyPath:(NSString *)keyPath {
    if (self = [super init]) {
        _aimKp = keyPath.copy;
        _aimObject = bindObject;
        _isObserveAimObject = NO;
    }
    return self;
}

@end


@interface ZCStreamCenter ()

@property (nonatomic, assign) BOOL isSetStart;

@property (nonatomic, strong) NSMutableArray <ZCStreamCoat *>*coats;

- (void)resetStreamValue:(id)newValue oldValue:(id)oldValue ignoreSymbol:(BOOL)ignoreSymbol;

@end


@interface ZCStreamCoat ()

@property (nonatomic, assign) int lockSymbol;

@property (nonatomic, strong) ZCStreamUnit *unit;

@property (nonatomic, weak) ZCStreamCenter *center;

@property (nonatomic, copy) NSString *unitKp;

@end

@implementation ZCStreamCoat

- (void)dealloc {
    [self resetAimObjectObserve:NO];
}

- (instancetype)initWithBeObserver:(id)beObserver observeKp:(NSString *)observeKp {
    if (self = [super init]) {
        _lockSymbol = 0;
        _unitKp = [@"aimObject." stringByAppendingString:observeKp];
        _unit = [[ZCStreamUnit alloc] initWithBindObject:beObserver keyPath:observeKp];
        [self resetAimObjectObserve:YES];
    }
    return self;
}

- (void)resetAimObjectObserve:(BOOL)isToObserve {
    if (isToObserve) {
        if (!_unit.isObserveAimObject && _unit.aimKp.length) {
            _unit.isObserveAimObject = YES;
            [_unit addObserver:self forKeyPath:_unitKp options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:ZCSymbolAimOContext];
        }
    } else {
        if (_unit.isObserveAimObject && _unit.aimKp.length) {
            _unit.isObserveAimObject = NO;
            [_unit removeObserver:self forKeyPath:_unitKp context:ZCSymbolAimOContext];
        }
    }
}

- (void)manualObservebeObserverValueChanged:(id)streamValue {
    [self syncStreamValue:streamValue ignoreSymbol:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:_unitKp] && context == ZCSymbolAimOContext) {
        if (_lockSymbol == 0) {
            if (_center) {
                _lockSymbol = 1;
                id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
                if ([oldValue isKindOfClass:NSNull.class]) oldValue = nil;
                id newValue = [change objectForKey:NSKeyValueChangeNewKey];
                if ([newValue isKindOfClass:NSNull.class]) newValue = nil;
                if (_streamValueFromObserveValue) {newValue = _streamValueFromObserveValue(newValue);}
                if (!_center.isSetStart && newValue != ZCStreamValueInvalid && _center.streamValueDidChanged) {
                    if (_streamValueFromObserveValue) {oldValue = _streamValueFromObserveValue(oldValue);}
                }
                [_center resetStreamValue:newValue oldValue:oldValue ignoreSymbol:NO];
                _lockSymbol = 0;
            }
        } else if (_lockSymbol == 2) {
            _lockSymbol = 0;
        } else {
            _lockSymbol = 0;
            NSAssert(0, @"ZCKit: stream set value is fail");
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)syncStreamValue:(id)newValue ignoreSymbol:(BOOL)ignoreSymbol {
    if (ignoreSymbol) {
        if (_unit.aimObject && _unit.aimKp.length) {
            if ([newValue isKindOfClass:NSNull.class]) newValue = nil;
            if (_KVCValueFromStreamValue) {newValue = _KVCValueFromStreamValue(newValue);}
            [_unit.aimObject setValue:newValue forKey:_unit.aimKp];
        }
    } else {
        if (_lockSymbol == 0) {
            if (_unit.aimObject && _unit.aimKp.length) {
                _lockSymbol = 2;
                if ([newValue isKindOfClass:NSNull.class]) newValue = nil;
                if (_KVCValueFromStreamValue) {newValue = _KVCValueFromStreamValue(newValue);}
                [_unit.aimObject setValue:newValue forKey:_unit.aimKp];
                _lockSymbol = 0;
            }
        } else if (_lockSymbol == 1) {
            _lockSymbol = 0;
        } else {
            _lockSymbol = 0;
            NSAssert(0, @"ZCKit: stream set value is fail");
        }
    }
}

- (id)extractStreamValue {
    if (_unit.aimObject && _unit.aimKp.length) {
        id value = [_unit.aimObject valueForKey:_unit.aimKp];
        if ([value isKindOfClass:NSNull.class]) value = nil;
        if (_streamValueFromKVCValue) {value = _streamValueFromKVCValue(value);}
        return value;
    }
    return ZCStreamValueInvalid;
}

@end


@implementation ZCStreamCenter

- (instancetype)init {
    if (self = [super init]) {
        _isSetStart = NO;
        _coats = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Core
- (void)addStreamCoat:(ZCStreamCoat *)newCoat {
    if (newCoat || ![_coats containsObject:newCoat]) {
        for (ZCStreamCoat *coat in _coats) {
            id newValue = coat.extractStreamValue;
            if (newValue != ZCStreamValueInvalid) {
                [newCoat syncStreamValue:newValue ignoreSymbol:YES]; break;
            }
        }
        newCoat.center = self;
        [_coats addObject:newCoat];
        [newCoat resetAimObjectObserve:YES];
    }
}

- (void)removeStraemCoat:(ZCStreamCoat *)oldCoat {
    if (oldCoat || [_coats containsObject:oldCoat]) {
        oldCoat.center = nil;
        [_coats removeObject:oldCoat];
        [oldCoat resetAimObjectObserve:NO];
    }
}

- (void)resetStreamValue:(id)newValue oldValue:(id)oldValue ignoreSymbol:(BOOL)ignoreSymbol {
    if (!_isSetStart && newValue != ZCStreamValueInvalid) {
        _isSetStart = YES;
        for (ZCStreamCoat *coat in _coats) {
            [coat syncStreamValue:newValue ignoreSymbol:ignoreSymbol];
        }
        if (_streamValueDidChanged) {
            BOOL isChanged = NO;
            if (oldValue && newValue) {
                if ([oldValue isKindOfClass:NSNull.class] && [newValue isKindOfClass:NSNull.class]) {
                    isChanged = NO;
                } else if ([oldValue isKindOfClass:NSString.class] && [newValue isKindOfClass:NSString.class]) {
                    isChanged = ![oldValue isEqualToString:newValue];
                } else if ([oldValue isKindOfClass:NSNumber.class] && [newValue isKindOfClass:NSNumber.class]) {
                    isChanged = ![oldValue isEqualToNumber:newValue];
                } else {
                    isChanged = oldValue != newValue;
                }
            } else if (!oldValue && !newValue) {
                isChanged = NO;
            } else {
                isChanged = YES;
            }
            if (isChanged) {
                _streamValueDidChanged(oldValue, newValue);
            }
        }
        _isSetStart = NO;
    }
}

#pragma mark - Get & Set
- (void)setStreamValue:(id)streamValue {
    id oldValue = nil;
    if (_streamValueDidChanged) oldValue = [self streamValue];
    [self resetStreamValue:streamValue oldValue:oldValue ignoreSymbol:YES];
}

- (id)streamValue {
    id value = ZCStreamValueInvalid;
    for (ZCStreamCoat *coat in _coats) {
        id newValue = coat.extractStreamValue;
        if (newValue != ZCStreamValueInvalid) {
            value = newValue; break;
        }
    }
    return value;
}

@end
