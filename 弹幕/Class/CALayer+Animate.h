//
//  CALayer+Animate.h
//  弹幕
//
//  Created by fly on 2020/12/17.
//

#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CALayer (Animate)

/** 暂停动画 */
- (void)pauseAnimate;

/** 恢复动画 */
- (void)resumeAnimate;

@end

NS_ASSUME_NONNULL_END
