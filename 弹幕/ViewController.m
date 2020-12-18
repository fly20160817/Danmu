//
//  ViewController.m
//  弹幕
//
//  Created by fly on 2020/12/15.
//

#import "ViewController.h"
#import "FLYDanmuView.h"
#import "FLYDanmuModel.h"

@interface ViewController () < FLYDanmuViewProtocol >

@property (nonatomic, strong) FLYDanmuView * danmuView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    [self.view addSubview:self.danmuView];
    
}



#pragma mark - event handler

//发送弹幕
- (IBAction)Biu:(UIButton *)sender
{
    FLYDanmuModel * model1 = [[FLYDanmuModel alloc] init];
    model1.beginTime = 0;
    model1.liveTime = 5;
    model1.content = @"哈哈哈哈哈哈哈哈哈";
    
    FLYDanmuModel * model2 = [[FLYDanmuModel alloc] init];
    model2.beginTime = 0.2;
    model2.liveTime = 8;
    model2.content = @"呵呵呵";
    
    FLYDanmuModel * model3 = [[FLYDanmuModel alloc] init];
    model3.beginTime = 0.2;
    model3.liveTime = 3;
    model3.content = @"flyflyfly";
    
    [self.danmuView.models addObject:model1];
    [self.danmuView.models addObject:model2];
    [self.danmuView.models addObject:model3];
}

//暂停
- (IBAction)Pause:(UIButton *)sender
{
    [self.danmuView pause];
}

//恢复
- (IBAction)Resume:(UIButton *)sender
{
    [self.danmuView resume];
}



#pragma mark - FLYDanmuViewProtocol

-(NSTimeInterval)currentTime
{
    //初始时间可以参照播放器的时间
    static double time = 0;
    time += 0.1;
    
    return time;
}

-(UIView *)danmuViewWithModel:(FLYDanmuModel *)model
{
    UILabel * label = [[UILabel alloc] init];
    label.text = model.content;
    [label sizeToFit];
    
    return label;
}

-(void)danmuViewDidClick:(UIView *)danmuView point:(CGPoint)point
{
    NSLog(@"点击了弹幕：%@，%@", danmuView, NSStringFromCGPoint(point));
}



#pragma mark - setters and getters

-(FLYDanmuView *)danmuView
{
    if ( !_danmuView )
    {
        _danmuView = [[FLYDanmuView alloc] initWithFrame:CGRectMake(50, 50, self.view.frame.size.width - 100, 300)];
        _danmuView.delegate = self;
        _danmuView.backgroundColor = [UIColor orangeColor];
    }
    return _danmuView;
}

@end
