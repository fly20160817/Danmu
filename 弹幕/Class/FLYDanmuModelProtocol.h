//
//  FLYDanmuModelProtocol.h
//  弹幕
//
//  Created by fly on 2020/12/17.
//

@protocol FLYDanmuModelProtocol <NSObject>

@required
//协议里面一般都是些方法的，这里为什么写属性呢，因为属性就相当于是get方法和set方法，这里写了readonly，所以相当于只有get方法
@property (nonatomic, readonly) NSTimeInterval beginTime;//弹幕开始时间
@property (nonatomic, readonly) NSTimeInterval liveTime;//弹幕跑完所需时间

@end
