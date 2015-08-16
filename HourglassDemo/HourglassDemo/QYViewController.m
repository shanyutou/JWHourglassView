//
//  QYViewController.m
//  HourglassDemo
//
//  Created by jiwei on 15/1/28.
//  Copyright (c) 2015年 weiji.info. All rights reserved.
//

#import "QYViewController.h"
#import "JWHourglassView.h"

@interface QYViewController ()

@property (nonatomic, strong) JWHourglassView *hourglass;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) NSTimeInterval totalTime;
@property (nonatomic, strong) NSDate *beginDate;

@end

@implementation QYViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    JWHourglassView *hourglass = [JWHourglassView shareHourglassUse:YES];
    hourglass.center = self.view.center;
    self.hourglass = hourglass;
    [self.view addSubview:hourglass];
    
    self.beginDate = [NSDate date];
    self.totalTime = 30.f * 60.f;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(timerFire:) userInfo:nil repeats:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)timerFire:(NSTimer *)timer{
    //告诉沙漏剩余时间
    NSTimeInterval runtime = [[NSDate date] timeIntervalSinceDate:self.beginDate];
    
    NSTimeInterval lastTime = self.totalTime - runtime;
    
    [self.hourglass refreshViewWithRemaining:lastTime];
    
    
    
}

@end
