//
//  FLYDanmuModel.h
//  弹幕
//
//  Created by fly on 2020/12/17.
//

#import <Foundation/Foundation.h>
#import "FLYDanmuModelProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface FLYDanmuModel : NSObject < FLYDanmuModelProtocol >

/** FLYDanmuModelProtocol协议里必须实现的两个方法(因为每个模型里的属性各不相同，为了方便以后使用，模型只需要遵循这个协议，并实现这两个方法就可以了) */

@property (nonatomic, assign) NSTimeInterval beginTime;//弹幕开始时间
@property (nonatomic, assign) NSTimeInterval liveTime;//弹幕跑完所需时间



@property (nonatomic, strong) NSString * content;

@end

NS_ASSUME_NONNULL_END
