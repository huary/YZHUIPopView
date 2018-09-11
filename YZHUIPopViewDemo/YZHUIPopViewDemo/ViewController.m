//
//  ViewController.m
//  YZHUIPopViewDemo
//
//  Created by yuan on 2018/8/27.
//  Copyright © 2018年 yuan. All rights reserved.
//

#import "ViewController.h"
#import "YZHUIPopView.h"

@interface ViewController ()<YZHUIPopViewDelegate>

/* <#注释#> */
@property (nonatomic, strong) UIButton *button;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self _setupChildView];
}

-(void)_setupChildView
{
    CGFloat w = 200;
    CGFloat h = 80;
    CGFloat x = (SCREEN_WIDTH - w)/2;
    CGFloat y = 100;
    self.button = [UIButton buttonWithType:UIButtonTypeCustom];
    self.button.frame = CGRectMake(x, y, w, h);
    self.button.backgroundColor = PURPLE_COLOR;
    [self.button addTarget:self action:@selector(_action:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.button];
//    self.view.backgroundColor = RED_COLOR;
}

-(void)_action:(UIButton*)sender
{
    CGSize size = CGSizeMake(200, 600);
    YZHUIPopView *popView = [[YZHUIPopView alloc] initWithPopContentSize:size fromOverView:sender showInView:nil];
//    popView.contentType = YZHUIPopViewContentTypeTableView;
    popView.backgroundColor = WHITE_COLOR;
    popView.effectView.alpha = 1.0;
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
