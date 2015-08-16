//
//  JWHourglassView.m
//  RunCoach5K
//
//  Created by YQ-011 on 7/18/13.
//  Copyright (c) 2013 YQ-011. All rights reserved.
//


#import "JWHourglassView.h"
#import "QYAppDelegate.h"


int lineWith[48] = {45,51,54,57,60,63,63,66,69,69,69,72,72,72,72,72,72,72,72,72,72,69,69,69,66,63,63,60,57,57,54,51,48,45,42,39,36,33,30,27,24,21,18,12,9,6,6,3};

int lineCountNumber[48] = {31, 35, 37, 39, 41, 43, 43, 45, 47, 47, 47, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 47, 47, 47, 45, 43, 43, 41, 39, 39, 37, 35, 33, 31, 29, 27, 25, 23, 21, 19, 17, 15, 13, 9, 7, 5, 5, 3};



#define kGritWith 2//这个数值跟上面的两个数组相匹配

#define kdefaultYellowColor [UIColor colorWithRed:255/255.0 green:179/255.0 blue:0/255.0 alpha:1.f]

@interface HourView : UIView

@property (nonatomic) int goalLine;//最终所在行，从底部数
@property (nonatomic) int theseLine;//当前所在行
@property (nonatomic) CGPoint goalPoint;//静止的位置
@property (nonatomic) BOOL isToGoal;//已经静止上砂子

@end

@implementation HourView

@synthesize goalLine = _goalLine;
@synthesize goalPoint = _goalPoint;
@synthesize theseLine = _theseLine;
@synthesize isToGoal = _isToGoal;

@end


@interface JWHourglassView (){
    NSDate *lastTime;
    int totalSandCount;//剩余的总沙粒个数
}

@property (nonatomic, strong) NSMutableArray *array1;//上半部分颗粒
@property (nonatomic, strong) NSMutableArray *array12;//下半部分颗粒
@property (nonatomic, strong) NSMutableArray *moveViewArray;//正在下落的沙子
@property (nonatomic, strong) NSMutableArray *moveNextArray;//正在滚动的沙子
@property (nonatomic, strong) NSTimer *tempTimer;//暂停后，让正在运动的沙粒运动完成

@end

@implementation JWHourglassView

+(id)shareHourglassUse:(BOOL)use{
    static JWHourglassView *hourglass;
    static BOOL hasUse = NO;
    if (!use) {
        if (!hourglass || hasUse == YES) {
            hourglass = [[JWHourglassView alloc] init];
            hasUse = NO;
        }
    }else{
        hasUse = YES;
        if (!hourglass) {
            hourglass = [[JWHourglassView alloc] init];
        }
    }
    
    return hourglass;
}

- (void)dealloc
{
#ifdef RUN_DEBUG
    NSLog(@"%s",__FUNCTION__);
#endif
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:CGRectMake(0, 0, 154, 304)];
    if (self) {
        // Initialization code
        [self loadView];
    }
    return self;
}

//初始化准备
-(void)loadView{
    UIView *view = [[UIView alloc] initWithFrame:self.bounds];
    [self addSubview:view];
    self.bgView = view;
    
    CGPoint cent = CGPointMake(self.bgView.frame.size.width / 2 , self.bgView.frame.size.height / 2);
    int k = 0;//行数
    _array1 = [[NSMutableArray alloc] initWithCapacity:48];
    _array12 = [[NSMutableArray alloc] initWithCapacity:48];
    
    
    //初始化沙粒
    //去掉一部分 
    totalSandCount = 0;
    for (int j = 143; j > 0; j -= 3) {
        NSMutableArray * array = [[NSMutableArray alloc] init];
        int i = (132 - k * 6 >= 0 ? 132 - k * 6 : 0);
        if (k > 14) {
            i = 0;
        }
        for (; i <= lineWith[k] && k > 8; i+= 3) {
            UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2, 2)];
            view.center = CGPointMake(cent.x + i, cent.y - j);
            view.backgroundColor = kdefaultYellowColor;
            [self.bgView addSubview:view];
            [array addObject:view];
            if (i != 0) {
                UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2, 2)];
                view.center = CGPointMake(cent.x -i, cent.y - j);
                view.backgroundColor = kdefaultYellowColor;
                [self.bgView addSubview:view];
                [array addObject:view];
                
            }
            
        }
        [_array1 addObject:array];
        totalSandCount += array.count;
        NSMutableArray *array2 = [[NSMutableArray alloc] init];
        [self.array12 addObject:array2];
        k ++;
    }
    
    UIImageView *imgeView = [[UIImageView alloc] initWithFrame:self.bounds];
    [imgeView setImage:[UIImage imageNamed:@"running_timer_bg"]];
    imgeView.contentMode = UIViewContentModeCenter;
    [self addSubview:imgeView];
    self.topImageView = imgeView;
}

//初始化一个正在下落的沙粒
-(UIView *)moveView{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2, 6)];
    UIView *view1 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2, 2)];
    view1.backgroundColor = kdefaultYellowColor;
    view1.alpha = 0.3f;
    [view addSubview:view1];
    
    UIView *view2 = [[UIView alloc] initWithFrame:CGRectMake(0, 2, 2, 2)];
    view2.backgroundColor = kdefaultYellowColor;
    [view addSubview:view2];
    view2.alpha = 0.5f;
    
    UIView *view3 = [[UIView alloc] initWithFrame:CGRectMake(0, 4, 2, 2)];
    view3.backgroundColor = kdefaultYellowColor;
    [view addSubview:view3];
    
    return view;
}

-(void)refreshViewWithRemaining:(NSTimeInterval)remaining{
    if (self.tempTimer) {
        [self.tempTimer invalidate];
        self.tempTimer = nil;
    }
    if (totalSandCount > 0) {
        float jiange = remaining / totalSandCount;
        if (!lastTime) {
            lastTime = [NSDate date];
        }
        NSTimeInterval timeminu = [lastTime timeIntervalSinceDate:[NSDate date]];
        if (timeminu > 0) {
            lastTime = [NSDate date];
            return;
        }
        if (timeminu + jiange <= 0) {
            lastTime = [NSDate date];
            UIView *view = [self viewminus];
            if (view) {
//                if ([JWAppDelegate applicationIsInForeground]) {
                if (1) {
                    //如果在前台
                    [self addCostomAnimation:view];
                }else{
                    [self addViewNoAnimation:view];//当在后台，不添加下落动画
                }
                totalSandCount--;//剩余沙粒个数减一
            }
        }
    }
    
    if (self.moveViewArray.count != 0) {
        UIView *view = [self refreshMoveView];
        if (view) {
            [self addMinusView:nil];
        }
    }
    //刷新已经落到底部的沙粒；
    [self layoutMoveNextView];
}

-(void)suspend{
    //当暂停后
    if (!self.tempTimer) {
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:.2f
                                                          target:self
                                                        selector:@selector(tempRunLoop:)
                                                        userInfo:nil
                                                         repeats:YES];
        self.tempTimer = timer;

    }
}

-(void)tempRunLoop:(NSTimer *)timer{
    if (self.moveViewArray.count != 0 || self.moveNextArray.count != 0) {
        if (self.moveViewArray.count != 0) {
            UIView *view = [self refreshMoveView];
            if (view) {
                [self addMinusView:nil];
            }
        }
        //刷新已经落到底部的沙粒；
        [self layoutMoveNextView];
    }else{
        [timer invalidate];
        self.tempTimer = nil;
    }
}

//上半部分消失一个View
-(UIView *)viewminus{
    UIView *tempView;
    for (int i = 0 ; i < _array1.count; i ++) {
        NSMutableArray *array = [_array1 objectAtIndex:i];
        if (array.count > 0) {
            if (i + 1 < _array1.count) {
                NSMutableArray *array2 = [_array1 objectAtIndex:i +1];
                if (lineCountNumber[i] - array.count >= lineCountNumber[i +1] - array2.count +5 && array2.count != 0) {
                    tempView = [self nextLine:i + 1];
                    break;
                }else{
                    tempView = [array objectAtIndex:0];
                    [array removeObject:tempView];
                    [tempView removeFromSuperview];
                    break;
                }
            }else {
                tempView = [array objectAtIndex:0];
                [array removeObject:tempView];
                [tempView removeFromSuperview];
                break;
            }
        }
    }
    return tempView;
}
//消失view的循环查找
-(UIView *)nextLine:(NSInteger)line{
    UIView *tempView;
    if (line >= _array1.count) {
        return nil;
    }
    NSMutableArray *array = [_array1 objectAtIndex:line];
    if (array.count > 0) {
        if (line + 1 < _array1.count) {
            NSMutableArray *array2 = [_array1 objectAtIndex:line +1];
            if (lineCountNumber[line] - array.count >= lineCountNumber[line + 1] - array2.count +5 && array2.count != 0) {
                return tempView = [self nextLine:line + 1];
            }
            else {
                tempView = [array objectAtIndex:0];
                [array removeObject:tempView];
                [tempView removeFromSuperview];
                return tempView;
            }
        }else {
            tempView = [array objectAtIndex:0];
            [array removeObject:tempView];
            [tempView removeFromSuperview];
            return tempView;
        }
    }
    return nil;
}


-(void)addCostomAnimation:(UIView *)addView{
    CGPoint cent_ = self.bgView.center;
    UIView *view = [self moveView];
    view.center = CGPointMake(cent_.x, cent_.y);
    [self.bgView addSubview:view];
    if (!self.moveViewArray) {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        self.moveViewArray = array;
    }
    [self.moveViewArray addObject:view];
}

-(UIView *)refreshMoveView{
    for (UIView *view in self.moveViewArray){
        view.frame = (CGRect){{view.frame.origin.x, view.frame.origin.y + 6},view.frame.size};
    }
        
    if (self.moveViewArray.count > 0){
        UIView *view = [self.moveViewArray objectAtIndex:0];
        if(view.frame.origin.y + 3 >= [self bottomFrameY]){
            [self.moveViewArray removeObject:view];
            [view removeFromSuperview];
            return view;
        }
        
    }
    return nil;
    
}

-(float)bottomFrameY{
    //当前的下面沙子的最高部分
    CGPoint cent = self.bgView.center;
    int i  =  0;
    for (; i < _array12.count; i ++ ) {
        NSMutableArray *array = [_array12 objectAtIndex:i];
        if ( array.count == 0) {
            break;
        }
    }
    float j = 143 - 3 *i + cent.y;
    return j;
}

//落到底部
-(UIView *)addMinusView:(UIView  *)addView {
    for (int i = 0; i < _array12.count; i ++ ) {
        NSMutableArray *array = [_array12 objectAtIndex:i];
        if ( array.count == 0) {
            [self lineAddView:i];
            break;
        }
    }
    return nil;
}

-(void)lineAddView:(NSInteger )line{
    CGPoint cent = CGPointMake(self.bgView.frame.size.width / 2 , self.bgView.frame.size.height / 2);
    NSMutableArray *array = [_array12 objectAtIndex:line];
    int count_ = array.count;
    float j = 143 - 3 *line;
    float i = 0;
    if (count_ % 2 != 0) {
        i = count_ /2 *3;
    }else{
        i = -count_ /2 *3;
    }
    HourView *view = [[HourView alloc] initWithFrame:CGRectMake(0, 0, 2, 2)];
    view.theseLine = line;
    view.center = CGPointMake(cent.x + i, cent.y + j);
    view.backgroundColor = kdefaultYellowColor;
    [self.bgView addSubview:view];
    [self subAddView:view];
//#ifdef RUN_DEBUG
//    NSLog(@"%s%f   %f",__FUNCTION__, view.center.x,  view.goalPoint.x);
//#endif
    if (!self.moveNextArray) {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        self.moveNextArray = array;
    }
    if (CGPointEqualToPoint(view.center, view.goalPoint)) {
        view.isToGoal = YES;
    }else{
        view.isToGoal = NO;
        [self.moveNextArray addObject:view];//加入滚动队列
    }
    
}
//确定最终掉落位置
-(void)subAddView:(HourView *)addView{
    for (int i = 0; i < _array12.count; i ++ ) {
        NSMutableArray *array = [_array12 objectAtIndex:i];
        if ( array.count < lineCountNumber[i]) {
            if (i + 1 == _array12.count) {
                [self lineSubView:addView Line:i];
                return;
            }else{
                NSMutableArray *array2 = [_array12 objectAtIndex:i + 1];
                if ( array.count< array2.count + 5) {
                    [self lineSubView:addView Line:i];
                    return;
                }
            }
        }
    }
}

-(void)lineSubView:(HourView *)view Line:(NSInteger)line{
    CGPoint cent = CGPointMake(self.bgView.frame.size.width / 2 , self.bgView.frame.size.height / 2);
    NSMutableArray *array = [_array12 objectAtIndex:line];
    int count_ = array.count;
    float j = 143 - 3 *line;
    float i = 0;
    if (count_ % 2 != 0) {
        i = (count_ + 1) /2 *3;
    }else{
        i = -count_ /2 *3;
    }
    
    CGPoint point1 = CGPointMake(cent.x + i, cent.y + j);
    view.goalPoint = point1;
    view.goalLine = line;    
    [array addObject:view];
}
//刷新让沙子滚落
-(void)layoutMoveNextView{
    for (int i = 0; i < self.moveNextArray.count; i++) {
        HourView *view = [self.moveNextArray objectAtIndex:i];
        if (view.goalLine < view.theseLine) {
            int tlint = view.theseLine - 1;
            NSArray *array = [self.array12 objectAtIndex:tlint];
            if (array.count != 0) {
                if (view.goalPoint.x > view.center.x) {
                    HourView *other;
                    if (array.count % 2 != 0) {
                        if (array.count == 1) {
                            other = [array objectAtIndex:0];
                        }else{
                            other = [array objectAtIndex:array.count - 2];
                            for (int i = 1; array.count >= 2 + i * 2; i ++) {
                                if (other.isToGoal) {
                                    break;
                                }else{
                                    other = [array objectAtIndex:(array.count - 2 - i* 2)];
                                }
                            }
                        }
                    }else{
                        other = [array objectAtIndex:array.count - 1];
                        for (int i = 1; array.count >= 1 + i * 2; i ++) {
                            if (other.isToGoal) {
                                break;
                            }else{
                                other = [array objectAtIndex:(array.count - 1 - i* 2)];
                            }
                        }
                        if (!other.isToGoal) {
                            view.isToGoal = YES;
                            view.center = view.goalPoint;
                            [self.moveNextArray removeObject:view];
                            return;
                        }
                    }
                    if (view.center.x >= other.center.x - 3) {
                        view.center = CGPointMake(other.center.x + 3, other.center.y);
                        view.theseLine = tlint;
                    }else{
                        view.center = CGPointMake(view.center.x + 3, view.center.y);
                    }
                    
                }else if (view.goalPoint.x < view.center.x){
                    HourView *other;
                    if (array.count % 2 != 0) {
                        other = [array objectAtIndex:array.count - 1];
                        for (int i = 1; array.count >= 1 + i * 2; i ++) {
                            if (other.isToGoal) {
                                break;
                            }else{
                                other = [array objectAtIndex:(array.count - 1 - i* 2)];
                            }
                        }
                    }else{
                        if (array.count == 1) {
                            other = [array objectAtIndex:0];
                        }else{
                            other = [array objectAtIndex:array.count - 2];
                            for (int i = 1; array.count >= 2 + i * 2; i ++) {
                                if (other.isToGoal) {
                                    break;
                                }else{
                                    other = [array objectAtIndex:(array.count - 2 - i* 2)];
                                }
                            }
                        }
                    }
                    
                    if (!other.isToGoal) {
                        view.isToGoal = YES;
                        view.center = view.goalPoint;
                        [self.moveNextArray removeObject:view];
                        return;
                    }
                    
                    if (view.center.x <= other.center.x + 3) {
                        view.center = CGPointMake(other.center.x -3, other.center.y);
                        view.theseLine = tlint;
                    }else{
                        view.center = CGPointMake(view.center.x - 3, view.center.y);
                    }
                }else {
                    view.isToGoal = YES;
                    view.center = view.goalPoint;
                    [self.moveNextArray removeObject:view];
                }
            }else{
                view.isToGoal = YES;
                view.center = view.goalPoint;
                [self.moveNextArray removeObject:view];
            }
        }else{
            view.isToGoal = YES;
            view.center = view.goalPoint;
            [self.moveNextArray removeObject:view];
        }
    }
}

#pragma mark - no animation

-(void)addViewNoAnimation:(UIView *)view{
    HourView *hView = [[HourView alloc] initWithFrame:CGRectMake(0, 0, 2, 2)];
    hView.backgroundColor = kdefaultYellowColor;
    [self.bgView addSubview:hView];
    [self subAddView:hView];
    hView.isToGoal = YES;
    hView.center = hView.goalPoint;
}



CGFloat distanceBetweenPoints (CGPoint first, CGPoint second) {
    CGFloat deltaX = second.x - first.x;
    CGFloat deltaY = second.y - first.y;
    return sqrt(deltaX*deltaX + deltaY*deltaY );
};


@end
