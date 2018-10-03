//
//  ViewController.m
//  YZHUIPopViewDemo
//
//  Created by yuan on 2018/8/27.
//  Copyright © 2018年 yuan. All rights reserved.
//

#import "ViewController.h"
#import "YZHUIPopView.h"
#import "PopViewController.h"

@interface ViewController ()<YZHUIPopViewDelegate>

/* <#注释#> */
@property (nonatomic, strong) UIButton *button;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self _setupChildView];
}

-(UIButton*)_createButtonWithTitle:(NSString*)title frame:(CGRect)frame tag:(NSInteger)tag
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.tag = tag;
    button.frame = frame;
    button.backgroundColor = PURPLE_COLOR;
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:@selector(_action:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

-(void)_setupChildView
{
//    CGFloat w = 200;
//    CGFloat h = 80;
//    CGFloat x = (SCREEN_WIDTH - w)/2;//SCREEN_WIDTH - 100;//(SCREEN_WIDTH - w)/2;
//    CGFloat y = 100;//600;
//    self.button = [UIButton buttonWithType:UIButtonTypeCustom];
//    self.button.frame = CGRectMake(x, y, w, h);
//    self.button.backgroundColor = PURPLE_COLOR;
//    [self.button addTarget:self action:@selector(_action:) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:self.button];
//
//    self.view.backgroundColor = ORANGE_COLOR;
    
    CGFloat w = 300;
    CGFloat h = 60;
    CGFloat x = (SCREEN_WIDTH - w)/2;
    CGFloat y = 100;
    UIButton *btn = [self _createButtonWithTitle:@"TableViewType" frame:CGRectMake(x, y, w, h) tag:YZHUIPopViewContentTypeTableView];
    [self.view addSubview:btn];


    y = 200;
    btn = [self _createButtonWithTitle:@"CollectionViewType" frame:CGRectMake(x, y, w, h) tag:YZHUIPopViewContentTypeCollectionView];
    [self.view addSubview:btn];
    
    y = 300;
    btn = [self _createButtonWithTitle:@"CustomViewType" frame:CGRectMake(x, y, w, h) tag:YZHUIPopViewContentTypeCustom];
    [self.view addSubview:btn];
}

-(void)_action:(UIButton*)sender
{
    PopViewController *popVC = [[PopViewController alloc] init];
    popVC.type = sender.tag;
    [self presentViewController:popVC animated:YES completion:nil];
    return;
    
    CGSize size = CGSizeMake(200, 600);
    YZHUIPopView *popView = [[YZHUIPopView alloc] initWithPopContentSize:size fromOverView:sender showInView:nil];
//    popView.contentType = YZHUIPopViewContentTypeTableView;
    popView.backgroundColor = CLEAR_COLOR;
    popView.innerBackgroundColor = PURPLE_COLOR;
    popView.arrowDirection = YZHUIPopViewArrowDirectionUp;//YZHUIPopViewArrowDirectionDown;
//    popView.effectView.alpha = 1.0;
    
    popView.borderWidth = 5;
    popView.borderColor = RED_COLOR;
    
//    popView.arrowCtx.arrowArcRadius = 0;
    
//    popView.arrowCtx.baseSize = CGSizeMake(30, 15);
//    popView.arrowCtx.arrowRadian = M_PI_2;
//    popView.arrowCtx.arrowArcRadius = 0;
    
    popView.arrowCtx = [[YZHPopArrowContext alloc] initWithBaseHeight:16 baseShift:0 arrowRadian:DEGREES_TO_RADIANS(90) arrowArcRadius:0];
    
    popView.delegate = self;
    [popView popViewShow:YES];
}

#pragma mark YZHUIPopViewDelegate
-(NSInteger)numberOfCellsInPopView:(YZHUIPopView *)popView
{
    return 5;
}

-(UIView *)popView:(YZHUIPopView *)popView cell:(UIView *)cell cellSubView:(UIView *)cellSubView forCellAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *tableViewCell = cell;
    tableViewCell.textLabel.text = NEW_STRING_WITH_FORMAT(@"%ld",indexPath.row + 1);
    return nil;
}

-(void)popView:(YZHUIPopView *)popView didSelectedCell:(UIView *)cell cellSubView:(UIView *)cellSubView forCellAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"index.row=%ld",indexPath.row);

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
