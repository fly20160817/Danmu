//
//  FLYDanmuView.h
//  弹幕
//
//  Created by fly on 2020/12/15.
//

#import <UIKit/UIKit.h>
#import "FLYDanmuModelProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FLYDanmuViewProtocol <NSObject>

//协议里面一般都是些方法的，这里为什么写属性呢，因为属性就相当于是get方法和set方法，这里写了readonly，所以相当于只有get方法
@property (nonatomic, readonly) NSTimeInterval currentTime;//当前的时间

//给外界一个model，让外界返回一个View
- (UIView *)danmuViewWithModel:(id<FLYDanmuModelProtocol>)model;

/** 点击了弹幕 */
- (void)danmuViewDidClick:(UIView *)danmuView point:(CGPoint)point;

@end

@interface FLYDanmuView : UIView

//数组里放的是id类型，并且遵循FLYDanmuModelProtocol协议
@property (nonatomic, strong) NSMutableArray<id <FLYDanmuModelProtocol>> * models;

@property (nonatomic, weak) id<FLYDanmuViewProtocol> delegate;


/** 暂停 */
- (void)pause;
/** 恢复 */
- (void)resume;

@end

NS_ASSUME_NONNULL_END
