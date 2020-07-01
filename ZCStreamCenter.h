//
//  ZCStreamCenter.h
//  ZCKit
//
//  Created by admin on 2019/11/3.
//  Copyright © 2018 Squat in house. All rights reserved.
//
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

///!!! 自动根据SEL或者Delegate生成中间对象来绑定源对象赋值与监听

extern NSString * const ZCStreamValueInvalid;

@interface ZCStreamCoat : NSObject  /**< 基本多向绑定单元 */

@property (nullable, nonatomic, copy) id _Nullable(^streamValueFromObserveValue)(id _Nullable observeValue);  /**< 观察者观察的对象值转成流值 */

@property (nullable, nonatomic, copy) id _Nullable(^KVCValueFromStreamValue)(id _Nullable streamValue);  /**< 流值转换成对象KVC赋值值 */

@property (nullable, nonatomic, copy) id _Nullable(^streamValueFromKVCValue)(id _Nullable KVCValue);  /**< 对象KVC赋值值转成流值 */

- (instancetype)initWithBeObserver:(id)beObserver observeKp:(NSString *)observeKp;  /**< 初始化方法，对于有些如UITextField等观察者抓取Text变化不准确 */

- (void)manualObservebeObserverValueChanged:(nullable id)streamValue;  /**< 手动调取被观察对象的Value发生变化，传入的为streamValue */

@end


@interface ZCStreamCenter : NSObject  /**< 多项绑定数据交换中心，确保所有单元最终的的streamValue数据类型相同，注所有NSNull将会转成nil */

@property (nullable, nonatomic, copy) void(^streamValueDidChanged)(id _Nullable oldStreamValue, id _Nullable newStreamValue);  /**< 对象流值已经发生改变 */

@property (nullable, nonatomic) id streamValue;  /**< 存储的交换值，可能为ZCStreamValueInvalid */

- (void)addStreamCoat:(ZCStreamCoat *)newCoat;  /**< 添加流对象，如果前值是Invalid，则以当前流对象的KVC转化值做streamValue，不会即时刷新streamValue值改变 */

- (void)removeStraemCoat:(ZCStreamCoat *)oldCoat;  /**< 移除流对象，不会即时刷新streamValue值改变 */

@end

NS_ASSUME_NONNULL_END
