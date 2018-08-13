//
//  ViewController.m
//  搭桥过河
//
//  Created by 李雪峰 on 15/9/14.
//  Copyright (c) 2015年 hfuu. All rights reserved.
//
#define MainWidth [UIScreen mainScreen].bounds.size.width
#define MainHeight [UIScreen mainScreen].bounds.size.height
#import "ViewController.h"

@interface ViewController ()<UIAlertViewDelegate,UITextFieldDelegate>
{
    UITextField *_speedField;
    UILabel *_speedLabel;
    UITextField *_bridgeSpeedField;
    UILabel *_bridgeSpeedLabel;
    UIScrollView *_scroll;
    UIImageView *_thirdLandImageView;
    UIImageView *_secondLandImageView;
    UIImageView *_personImageView;
    UIImageView *_bridgeImageView;//竖立的桥
    UIImageView *_flatBridgeImageView;//平放的桥
    
    NSTimer *_personTimer;//小人行走动画计时器
    NSTimer *_bridgeTimer;
    NSTimer *_landTimer;//平地推进
    NSTimer *_goAheadTimer;//小人前进动画
    
    CGFloat width;
    CGFloat hight;
    int score ;//得分
    int bridgeHight;//桥高
    int scrollContentOffsetx;
    int landx;
    int personPage;//控制小人图片切换
    int personGo;//控制人物前进距离
    int landWidth;
    int bridgeSpeed;//桥长增加速度
    int speed;//小人行走速度
    
    BOOL isbacking;

}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    isbacking = YES;
    
    //重载scroll视图时需重置以下变量
    score = 0;
    landx = 0;
    personGo = 0;
    personPage = 1;
    landWidth = 0;
    scrollContentOffsetx = 0;
    speed = 4;
    bridgeSpeed = 4;
    //设置桥初始长度
    bridgeHight = 20;

    width = [UIScreen mainScreen].bounds.size.width;
    hight = [UIScreen mainScreen].bounds.size.height;
    
    //配置scrollView
    _scroll = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 0, width, hight)];
    [_scroll setContentSize:CGSizeMake(MAXFLOAT, hight)];
    _scroll.scrollEnabled = NO;
    UIButton *scrollbtn = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, MAXFLOAT, hight)];
    [scrollbtn addTarget:self action:@selector(longPressAction) forControlEvents:UIControlEventTouchDown];
    [scrollbtn addTarget:self action:@selector(cancelRaise) forControlEvents:UIControlEventTouchUpInside];
    [_scroll addSubview:scrollbtn];
    [self.view addSubview:_scroll];
    
    UIView *headView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, MainWidth, 150)];
    [self.view addSubview:headView];
    
    //更改小人的行走速度
    _speedField = [[UITextField alloc]initWithFrame:CGRectMake(MainWidth - 50, 35, 40, 30)];
    _speedField.placeholder = @"4";
    _speedField.layer.borderWidth = 0.5;
    _speedField.keyboardType = UIKeyboardTypeNumberPad;
    _speedLabel = [[UILabel alloc]initWithFrame:CGRectMake(MainWidth - 125, 30, 80, 40)];
    _speedLabel.text = @"行走速度:";
    _speedField.delegate = self;
    [headView addSubview:_speedLabel];
    [headView addSubview:_speedField];
    
    UITapGestureRecognizer *headTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(headViewTouch)];
    headTap.numberOfTapsRequired = 1;
    headView.userInteractionEnabled = YES;
    [headView addGestureRecognizer:headTap];
    
    
    //更改桥长增长速度
    _bridgeSpeedField = [[UITextField alloc]initWithFrame:CGRectMake(85, 35, 40, 30)];
    _bridgeSpeedField.layer.borderWidth = 0.5;
    _bridgeSpeedField.placeholder = @"4";
    _bridgeSpeedField.keyboardType = UIKeyboardTypeNumberPad;
    _bridgeSpeedLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, 30, 80, 40)];
    _bridgeSpeedLabel.text = @"搭桥速度:";
    _bridgeSpeedField.delegate = self;
    [headView addSubview:_bridgeSpeedLabel];
    [headView addSubview:_bridgeSpeedField];
    
    UIButton *directBtn = [[UIButton alloc]initWithFrame:CGRectMake(MainWidth - 80, 80, 70, 40)];
//    [directBtn setBackgroundColor:[UIColor greenColor]];
    [directBtn setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    [directBtn setTitle:@"正向行走" forState:UIControlStateSelected];
    [directBtn setTitle:@"反向行走" forState:UIControlStateNormal];
    [directBtn addTarget:self action:@selector(changeDirection:) forControlEvents:UIControlEventTouchUpInside];
    directBtn.layer.borderWidth = 1;
    directBtn.layer.borderColor = [UIColor greenColor].CGColor;
    directBtn.layer.cornerRadius = 3;
    directBtn.layer.masksToBounds = YES;
    directBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [headView addSubview:directBtn];
    
    //配置初始平地imageview
    UIImageView *landImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 368, 30, MainHeight - 368)];
    [landImageView setImage:[UIImage imageNamed:@"land"]];
    [_scroll addSubview:landImageView];
    
    
    //配置人物imageView
    _personImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 308, 30, 60)];
    [_personImageView setImage:[UIImage imageNamed:@"5"]];
    [_scroll addSubview:_personImageView];
    
    
    //配置桥imageView
    _bridgeImageView = [[UIImageView alloc]initWithFrame:CGRectMake(30, 348, 10, 20)];
    [_bridgeImageView setImage:[UIImage imageNamed:@"bridgestand"]];
    [_scroll addSubview:_bridgeImageView];
    _bridgeImageView.hidden = NO;
    
    _flatBridgeImageView = [[UIImageView alloc]initWithFrame:CGRectMake(30, 368, 10, 10)];
    [_flatBridgeImageView setImage:[UIImage imageNamed:@"bridge"]];
    [_scroll addSubview:_flatBridgeImageView];
    _flatBridgeImageView.hidden = YES;

    [self creatNewLand];
    
}

//改变行走方向
- (void)changeDirection:(UIButton *)btn{
    if (btn.selected) {
        btn.selected = NO;
        isbacking = YES;
        [_personImageView setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%d", personPage]]];
    }else{
        btn.selected = YES;
        isbacking = NO;
        [_personImageView setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%d反向", personPage]]];
    }
}

- (void)headViewTouch{
    [_bridgeSpeedField resignFirstResponder];
    [_speedField resignFirstResponder];
}

//文本框协议回调方法
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    if(textField == _speedField){
        [_speedField resignFirstResponder];
        [_bridgeSpeedField becomeFirstResponder];
        if ([_speedField.text intValue] != 0) {
            speed = [_speedField.text intValue];
        }
        
    }else if(textField == _bridgeSpeedField){
        [_bridgeSpeedField resignFirstResponder];
        [_speedField becomeFirstResponder];
        if ([_bridgeSpeedField.text intValue] != 0) {
            bridgeSpeed = [_bridgeSpeedField.text intValue];
        }
        
    }
        return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    if(textField == _speedField){
        if ([_speedField.text intValue] != 0) {
            speed = [_speedField.text intValue];
        }
        
    }else if(textField == _bridgeSpeedField){

        if ([_bridgeSpeedField.text intValue] != 0) {
            bridgeSpeed = [_bridgeSpeedField.text intValue];
        }
        
    }
}

//创建新平地
-(void)creatNewLand{
    _personTimer = nil;
    _goAheadTimer = nil;
    //起始位置平地占有屏幕的宽度
    int x = (50 > (landx + landWidth - scrollContentOffsetx))?50:landx + landWidth - scrollContentOffsetx;
    landx = scrollContentOffsetx + x + arc4random()%(320 - x -50);
    
    //设置平地宽度至少30
    landWidth = arc4random()%(270 + scrollContentOffsetx - landx) + 30;
    
    //创建新的_secondLandImageView
    _secondLandImageView = [[UIImageView alloc]initWithFrame:CGRectMake(landx, 368, landWidth, MainHeight - 368)];
    [_secondLandImageView setImage:[UIImage imageNamed:@"land"]];
    [_scroll addSubview:_secondLandImageView];
}

//长按事件添加
-(void)longPressAction{
    if (_bridgeTimer == nil) {
        //设置桥长度_bridgeTimer
        _bridgeTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(raiseBridgeLenth) userInfo:nil repeats:YES];
    }
}

//增加bridge长度
-(void)raiseBridgeLenth{
    bridgeHight = bridgeHight + bridgeSpeed;
    [_bridgeImageView setFrame:CGRectMake(scrollContentOffsetx + 30, 368-bridgeHight, 10, bridgeHight)];
    [_flatBridgeImageView setFrame:CGRectMake(scrollContentOffsetx + 30, 368, bridgeHight, 10)];
}

//停止按压
-(void)cancelRaise{
    [_bridgeTimer invalidate];
    _bridgeTimer = nil;
    _bridgeImageView.hidden = YES;
    _flatBridgeImageView.hidden = NO;

    if (_personTimer == nil) {
        //如果后续不释放该Timer对象，每当本方法被调用则不断生成新的对象，造成紊乱
        _personTimer = [NSTimer scheduledTimerWithTimeInterval:0.8/speed target:self selector:@selector(walkAnimation) userInfo:nil repeats:YES];
    }
    if (_goAheadTimer == nil) {
        _goAheadTimer = [NSTimer scheduledTimerWithTimeInterval:0.4/speed target:self selector:@selector(personGoAhead) userInfo:nil repeats:YES];
    }
}

//小人自身行走动画
-(void)walkAnimation{
    personPage ++;
    if(personPage == 6){
        personPage = 1;
    }
    if (isbacking) {
        [_personImageView setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%d", personPage]]];
    }else{
        [_personImageView setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%d反向", personPage]]];
    }
    
}

//小人前进动画
-(void)personGoAhead{
    personGo ++;
    [_personImageView setFrame:CGRectMake(scrollContentOffsetx + personGo*5, 308, 30, 60)];
    
    //让小人走完桥长
    while (personGo*5 > bridgeHight) {

        //判断小人是否安全着陆,安全着陆条件：以小人右方为准
        if(bridgeHight > landx - scrollContentOffsetx -30 && bridgeHight < landx - scrollContentOffsetx + landWidth - 30){
            score ++;
            //确定scrollview的偏移量
            scrollContentOffsetx = personGo*5 + scrollContentOffsetx;
            while (personGo*5 > bridgeHight) {
                [_goAheadTimer invalidate];
                [_personTimer invalidate];
                break;
            }
            [_personImageView setFrame:CGRectMake(scrollContentOffsetx, 308, 30, 60)];
            [_scroll setContentOffset:CGPointMake(scrollContentOffsetx, 0)];
            [_bridgeImageView setFrame:CGRectMake(scrollContentOffsetx + 30, 348, 10, 20)];
            _bridgeImageView.hidden = NO;
            _flatBridgeImageView.hidden = YES;
            
            //未重载页面，故需初始化桥的长度即小人已走的步数
            bridgeHight = 20;
            personGo = 0;
            [self creatNewLand];
            break;
        }else{
            [_personTimer invalidate];
            [_goAheadTimer invalidate];
            [[[UIAlertView alloc]initWithTitle:@"游戏结束" message:[NSString stringWithFormat:@"您的得分为%d",score] delegate:self cancelButtonTitle:@"退出" otherButtonTitles:@"重新开始", nil]show];
            break;
        }
    }
}

//提示框的协议回调方法
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex == 0){
        exit(0);
    }else{
        //重载scroll视图
        [_scroll removeFromSuperview];
        
        //循环遍历移除子视图，因为在viewDidLoad方法中会重新生成两个textfield和Label，产生错误
//        for(int i = 0;i<4;i++){
//            [[self.view.subviews objectAtIndex:i] removeFromSuperview];
//        }//此方法不可行，原因未知
        [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self viewDidLoad];
    }
}


@end
