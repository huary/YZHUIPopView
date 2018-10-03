//
//  PopViewController.m
//  YZHUIPopViewDemo
//
//  Created by yuan on 2018/9/26.
//  Copyright © 2018年 yuan. All rights reserved.
//

#import "PopViewController.h"

@interface PopViewController () <YZHUIPopViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource>

/*  */
@property (nonatomic, strong) UICollectionViewFlowLayout *flowLayout;

/* <#注释#> */
@property (nonatomic, strong) UICollectionView *collectionView;

@end

@implementation PopViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self _setupChildView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)_setupChildView
{
    self.view.backgroundColor = WHITE_COLOR;
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.backgroundColor = PURPLE_COLOR;
    closeBtn.frame =  CGRectMake(0, 20, 60, 40);
    [closeBtn setTitle:@"关闭" forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(_closeAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeBtn];
    
//    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(100, 100, 200, 600) collectionViewLayout:self.flowLayout];
//    self.collectionView.delegate = self;
//    self.collectionView.dataSource = self;
//    self.collectionView.backgroundColor = RED_COLOR;
//    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:NSSTRING_FROM_CLASS(UICollectionViewCell)];
//    [self.view addSubview:self.collectionView];
}

-(void)_closeAction:(UIButton*)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(YZHUIPopView*)_showPopViewWithPopOverView:(UIView*)sender
{
    CGSize size = CGSizeMake(200, 600);
//    if (self.type == YZHUIPopViewContentTypeCollectionView) {
//        if (self.flowLayout.scrollDirection) {
//            <#statements#>
//        }
//    }
    YZHUIPopView *popView = [[YZHUIPopView alloc] initWithPopContentSize:size fromOverView:sender showInView:nil];
    popView.contentType = self.type;
    if (self.type == YZHUIPopViewContentTypeCollectionView) {
        popView.collectionViewLayout = self.flowLayout;
    }
    else if (self.type == YZHUIPopViewContentTypeCustom) {
        popView.customContentViewBlock = ^UIView *(CGSize size) {
            UIView *contentView = [UIView new];
            contentView.frame = CGRectMake(0, 0, 200, 200);
            contentView.backgroundColor = BLUE_COLOR;
            return contentView;
        };
    }
    popView.backgroundColor = CLEAR_COLOR;
    popView.innerBackgroundColor = PURPLE_COLOR;
    popView.borderWidth = 3;
    popView.borderColor = RED_COLOR;
    popView.arrowCtx = [[YZHPopArrowContext alloc] initWithBaseHeight:16 baseShift:4 arrowRadian:DEGREES_TO_RADIANS(82) arrowArcRadius:2];
    popView.delegate = self;
//    popView.arrowDirection = YZHUIPopViewArrowDirectionUp;
    [popView popViewShow:YES];
    return popView;
}

-(UICollectionViewFlowLayout*)flowLayout
{
    if (_flowLayout == nil) {
        CGFloat w = 40;
        CGFloat h = 40;
        _flowLayout = [[UICollectionViewFlowLayout alloc] init];
        _flowLayout.itemSize = CGSizeMake(w, h);
        _flowLayout.minimumLineSpacing = 0;
        _flowLayout.minimumInteritemSpacing = 0;
//        _flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    }
    return _flowLayout;
}

#pragma mark YZHUIPopViewDelegate
-(NSInteger)numberOfCellsInPopView:(YZHUIPopView *)popView
{
    if (self.type == YZHUIPopViewContentTypeTableView) {
        return 100;
    }
    else if (self.type == YZHUIPopViewContentTypeCollectionView) {
        return 10;
    }
    return 0;
}

-(UIView *)popView:(YZHUIPopView *)popView cell:(UIView *)cell cellSubView:(UIView *)cellSubView forCellAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.type == YZHUIPopViewContentTypeTableView) {
        UITableViewCell *tableViewCell = cell;
        tableViewCell.textLabel.text = NEW_STRING_WITH_FORMAT(@"%ld",indexPath.row + 1);
        return nil;
    }
    else if (self.type == YZHUIPopViewContentTypeCollectionView) {
        if (cellSubView == nil) {
            cellSubView = [UILabel new];
        }
        UILabel *textLabel = (UILabel*)cellSubView;
        textLabel.text =  NEW_STRING_WITH_FORMAT(@"%ld",indexPath.row + 1);
        textLabel.textAlignment = NSTextAlignmentCenter;
        textLabel.backgroundColor = RAND_COLOR;
        return textLabel;
    }
    return nil;
}

-(void)popView:(YZHUIPopView *)popView didSelectedCell:(UIView *)cell cellSubView:(UIView *)cellSubView forCellAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"index.row=%ld",indexPath.row);
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UIView *popOverView = [self.view viewWithTag:100];
    [popOverView removeFromSuperview];
    UITouch *touch = [[touches allObjects] firstObject];
    
    CGPoint point = [touch locationInView:self.view];
    
    
    [self _setupPopOverViewForPoint:point];
}

-(void)_setupPopOverViewForPoint:(CGPoint)point
{
    UIView *popOverView = [[UIView alloc] init];
    popOverView.tag = 100;
    popOverView.backgroundColor = RED_COLOR;
    
    CGFloat w = arc4random()% ((NSInteger)self.view.bounds.size.width/2);
    w = MAX(w, 30);
    CGFloat h = arc4random()% ((NSInteger)self.view.bounds.size.height/5);
    h = MAX(h, 10);
    popOverView.frame = CGRectMake(point.x - w/2, point.y - h/2, w, h);
    
//    popOverView.frame = CGRectMake(363.33332824707031, 69.833328247070312, 30, 139);
//    popOverView.frame = CGRectMake(65.333328247070312, 153.83332824707031, 62, 85);
//    popOverView.frame = CGRectMake(-53.5, 220.33332824707031,131,104);
//    popOverView.frame = CGRectMake(135.66665649414062, 694.83332824707031,148,57);
//    {{328.5, 646}, {75, 144}}
//    popOverView.frame = CGRectMake(380, 646,200,144);;//CGRectMake(328.5, 646,75,144);
    NSLog(@"popOverView.frame=%@",NSStringFromCGRect(popOverView.frame));
    [self.view addSubview:popOverView];
    [self _showPopViewWithPopOverView:popOverView];
    
//    [self popViewShow:btn];
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 10;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSSTRING_FROM_CLASS(UICollectionViewCell) forIndexPath:indexPath];
    cell.backgroundColor = RAND_COLOR;
    
    UILabel *label = [UILabel new];
    label.frame = cell.bounds;
    label.text = NEW_STRING_WITH_FORMAT(@"%ld",indexPath.item);
    label.textAlignment = NSTextAlignmentCenter;
    [cell addSubview:label];
    
    return cell;
}


@end
