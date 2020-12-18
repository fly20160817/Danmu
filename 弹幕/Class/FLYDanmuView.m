//
//  FLYDanmuView.m
//  弹幕
//
//  Created by fly on 2020/12/15.
//

#import "FLYDanmuView.h"
#import "CALayer+Animate.h"

#define kClockSecond 0.1  //时钟间隔时间
#define kDandaoCount 5    //弹道的数量

@interface FLYDanmuView ()

@property (nonatomic, weak) NSTimer * clock;//起到时钟的作用

//记录各个弹道的绝对等待时间
@property (nonatomic, strong) NSMutableArray * laneWaitTimes;

//各个弹道里，前面的弹幕还需多长时间跑完
@property (nonatomic, strong) NSMutableArray * laneLeftTimes;

//储存屏幕上的弹幕view
@property (nonatomic, strong) NSMutableArray * danmuViews;

@end

@implementation FLYDanmuView

#pragma mark - life cycle

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.masksToBounds = YES;
        
        UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(click:)];
        [self addGestureRecognizer:tap];
    }
    return self;
}

//被添加到父视图上后，打开时钟
-(void)didMoveToSuperview
{
    [super didMoveToSuperview];
    
    [self startTimer];
}

-(void)dealloc
{
    [self stopTimer];
}



#pragma mark - public methods

/** 暂停 */
- (void)pause
{
    //暂停计时器
    [self pauseTimer];
    
    //用数组中所有view的layer，去执行pauseAnimate暂停方法
    [[self.danmuViews valueForKeyPath:@"layer"] makeObjectsPerformSelector:@selector(pauseAnimate)];
}

/** 恢复 */
- (void)resume
{
    //开始计时器
    [self startTimer];
    
    //用数组中所有view的layer，去执行resumeAnimate暂停方法
    [[self.danmuViews valueForKeyPath:@"layer"] makeObjectsPerformSelector:@selector(resumeAnimate)];
}



#pragma mark - event handler

- (void)click:(UITapGestureRecognizer *)tap
{
    //获取当前点击的点
    CGPoint point = [tap locationInView:tap.view];
    
    //遍历屏幕上所有弹幕view，找出点击的点在哪个弹幕上
    for ( UIView * danmuView in self.danmuViews )
    {
        //获取弹幕view的frame
        //动画开始的时候，view的frame位置其实已经在终点了，动画是layer的展示层在变化
        CGRect frame = danmuView.layer.presentationLayer.frame;
        
        //判断point，是否在frame中
        BOOL isContain = CGRectContainsPoint(frame, point);
        
        if ( isContain )
        {
            if ( [self.delegate respondsToSelector:@selector(danmuViewDidClick:point:)] )
            {
                [self.delegate danmuViewDidClick:danmuView point:point];
            }
            break;
        }
    }
    
}

//检查和发射弹幕
- (void)checkAndBiu
{
    //实时更新弹道记录的时间信息
    for ( int i = 0; i < kDandaoCount; i++ )
    {
        //更新各个弹道的等待时间
        double waitValue = [self.laneWaitTimes[i] doubleValue] - kClockSecond;
        
        if ( waitValue <= 0.0 )
        {
            waitValue = 0.0;
        }
        self.laneWaitTimes[i] = @(waitValue);
        
        
        
        //更新各个弹道, 前面的弹幕还需多长时间跑完
        double leftValue = [self.laneLeftTimes[i] doubleValue] - kClockSecond;
        
        if ( leftValue <= 0.0 )
        {
            leftValue = 0.0;
        }
        self.laneLeftTimes[i] = @(leftValue);
    }
    
    
    //对models数组进行排序
    [self.models sortUsingComparator:^NSComparisonResult(id<FLYDanmuModelProtocol>  _Nonnull obj1, id<FLYDanmuModelProtocol>  _Nonnull obj2) {
        
        if ( obj1.beginTime < obj2.beginTime )
        {
            //返回升序 （小的放前面，大的放后面）
            return NSOrderedAscending;
        }
        
        return NSOrderedDescending;
        
    }];
    
    
    //记录已经发射的弹幕model，循环结束后从总数组中删除这些数据
    NSMutableArray * deleteModels = [NSMutableArray array];
    
    //检测模型数组里面所有的模型，是否可以发射，如果可以发射，就直接发射
    for ( id<FLYDanmuModelProtocol> model in self.models )
    {
        //1. 检测弹幕开始时间是否到达
        NSTimeInterval beginTime = model.beginTime;
        NSTimeInterval currentTime = self.delegate.currentTime;
        
        //因为模型数组已经排过序了，所以当前的这个如果时间没到，后面的也都没到，直接跳出循环
        if ( beginTime > currentTime )
        {
            break;
        }
        
        
        /** 发送时间已经到了 */
        
        
        
        //2. 检测碰撞 (后面的弹幕是否会追上前面的弹幕，要避免重叠)
        
        //检测碰撞和发射
        BOOL result = [self checkCollisionAndLaunch:model];
        
        //如果发射成功，保存这个model
        if ( result )
        {
            [deleteModels addObject:model];
        }
    }
    
    //移除已经发射的弹幕model
    [self.models removeObjectsInArray:deleteModels];
}



#pragma mark - private methods

//检测碰撞和发射，返回是否发射
- (BOOL)checkCollisionAndLaunch:(id<FLYDanmuModelProtocol>)model
{

    //遍历所有弹道，在每个弹道里面进行检测 (检测弹幕开始的时候是否碰撞 和 检测弹幕结束的时候是否碰撞，如果这两个时候都不会碰撞，那中间的时候也不会碰撞)
    for ( int i = 0; i < kDandaoCount; i++ )
    {
        //1. 获取该弹道的绝对等待时间
        NSTimeInterval waitTime = [self.laneWaitTimes[i] doubleValue];
        
        //如果这个弹道有等待时间，则进入下一次循环，检测其他弹道
        if ( waitTime > 0.0 )
        {
            continue;
        }
        
        
        //2. 判断是否会产生碰撞
        
        UIView * danmuView = [self.delegate danmuViewWithModel:model];
        
        //前面弹幕跑完所需的剩余时间
        NSTimeInterval leftTime = [self.laneLeftTimes[i] doubleValue];
        //下一个弹幕的速度  速度 = (弹幕视图的宽度 + 弹道的宽度) / 时间
        double speed = (danmuView.frame.size.width + self.frame.size.width) / model.liveTime;
        //前面弹幕的剩余时间内，下一个弹幕可以走的距离 (前面弹幕的剩余时间 * 下一个弹幕的速度)
        double distance = leftTime * speed;
        
        //如果这个值大于弹道长度，说明下一个弹幕必会撞到前面的弹幕，则进入下一次循环，检测其他弹道
        if( distance > self.frame.size.width )
        {
            continue;
        }
        
        
        //保存这个弹幕view
        [self.danmuViews addObject:danmuView];
        
        //重置数据
        //记录这条弹幕完全出来需要多长时间 (在没出来完之前，这个弹道不会在继续出弹幕)
        self.laneWaitTimes[i] = @(danmuView.frame.size.width / speed);
        self.laneLeftTimes[i] = @(model.liveTime);
        
        //3. 发射弹幕
        
        //3.1 先把弹幕视图，加到弹幕背景里面
        
        //弹道的高度 （每个弹道平分高度）
        CGFloat dandaoHeight = self.frame.size.height / kDandaoCount;
        
        CGRect frame = danmuView.frame;
        frame.origin = CGPointMake(self.frame.size.width, dandaoHeight * i);
        danmuView.frame = frame;
        [self addSubview:danmuView];
        
        //弹幕滚动 (改变x轴的位置)
        //delay:延迟 options:UIViewAnimationOptionCurveLinear 直线匀速运动
        [UIView animateWithDuration:model.liveTime delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            
            CGRect frame = danmuView.frame;
            frame.origin.x = -danmuView.frame.size.width;
            danmuView.frame = frame;
            
        } completion:^(BOOL finished) {
            
            //弹幕结束之后，移除弹幕view
            [danmuView removeFromSuperview];
            
            //从数组中移除
            [self.danmuViews removeObject:danmuView];
            
        }];
        
        
        //发射完之后跳出整个循序
        return YES;
    }
    
    
    
    return NO;
}



#pragma mark - Timer

//打开计时器
- (void)startTimer
{
    //启动定时器 触发时间  ([NSDate distantPast]随机获取一个遥远的过去时间)
    self.clock.fireDate = [NSDate distantPast];
}

//暂停计时器
- (void)pauseTimer
{
    //停止定时器 触发时间  ([NSDate distantFuture]随机获取一个遥远的未来时间)
   //如果给我一个期限，我希望是4001-01-01 00:00:00 +0000
    self.clock.fireDate = [NSDate distantFuture];
}

//关闭计时器
- (void)stopTimer
{
    //将timer从当前的RunLoop中remove掉
    [self.clock invalidate];
    self.clock = nil;
}



#pragma mark - setters and getters

-(NSMutableArray *)models
{
    if ( _models == nil )
    {
        _models = [NSMutableArray array];
    }
    return _models;
}

-(NSMutableArray *)laneWaitTimes
{
    if ( !_laneWaitTimes )
    {
        _laneWaitTimes = [NSMutableArray arrayWithCapacity:kDandaoCount];
        
        //每个弹道的初始时间都设置为0
        for ( int i = 0; i < kDandaoCount; i++ )
        {
            _laneWaitTimes[i] = @0.0;
        }
    }
    return _laneWaitTimes;
}


-(NSMutableArray *)laneLeftTimes
{
    if ( !_laneLeftTimes )
    {
        _laneLeftTimes = [NSMutableArray arrayWithCapacity:kDandaoCount];
        
        for ( int i = 0; i < kDandaoCount; i++ )
        {
            _laneLeftTimes[i] = @0.0;
        }
    }
    return _laneLeftTimes;
}

-(NSMutableArray *)danmuViews
{
    if ( _danmuViews == nil )
    {
        _danmuViews = [NSMutableArray array];
    }
    return _danmuViews;
}

-(NSTimer *)clock
{
    if (_clock == nil)
    {
        _clock = [NSTimer scheduledTimerWithTimeInterval:kClockSecond target:self selector:@selector(checkAndBiu) userInfo:nil repeats:YES];
        _clock.fireDate = [NSDate distantFuture];
    }
    return _clock;
}

@end
