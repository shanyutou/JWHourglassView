//
//  JWHourglassView.h
//  RunCoach5K
//
//  Created by YQ-011 on 7/18/13.
//  Copyright (c) 2013 YQ-011. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JWHourglassView : UIView

@property (weak, nonatomic) UIView *bgView;
@property (weak, nonatomic) UIImageView *topImageView;

-(void)refreshViewWithRemaining:(NSTimeInterval)remaining;

-(void)suspend;

//该视图加载需要较长时间，所以要提前加载
+(id)shareHourglassUse:(BOOL)use;

@end
