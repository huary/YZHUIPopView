//
//  YZHUIPopView.m
//  YZHUIPopViewDemo
//
//  Created by yuan on 2018/8/27.
//  Copyright © 2018年 yuan. All rights reserved.
//

#import "YZHUIPopView.h"
#import "YZHUIPopTableViewCell.h"
#import "YZHUIPopCollectionViewCell.h"

static CGFloat popActionFullScore_s     = 100.0;
static NSTimeInterval animationTimeInterval_s = 0.2;

#define IS_ARROW_DIRECTION_HORIZONTAL(ARROW_DIR)    (ARROW_DIR == YZHUIPopViewArrowDirectionUp || ARROW_DIR == YZHUIPopViewArrowDirectionDown)
#define IS_ARROW_DIRECTION_VERTICAL(ARROW_DIR)      (ARROW_DIR == YZHUIPopViewArrowDirectionLeft || ARROW_DIR == YZHUIPopViewArrowDirectionRight)

typedef NS_ENUM(NSInteger, NSPopActionType)
{
    NSPopActionTypeNone             = 0,
    NSPopActionTypeAdjustArrow      = (1 << 0),
    NSPopActionTypeAdjustWidth      = (1 << 1),
    NSPopActionTypeAdjustHeight     = (1 << 2),
    NSPopActionTypeInnerInsets      = (1 << 3),
    NSPopActionTypeArrowNotIn       = (1 << 4),
    NSPopActionTypeArrowNotPointCenter  = (1 << 5),
};

/**************************************************************************
 *YZHArrowContext
 **************************************************************************/
@implementation YZHPopArrowContext

//这个运用了初中的三角形相似原理来求出baseAngleArcRadius时的baseShift（x）
+(CGFloat)_getBaseArcBaseShiftWithBaseSize:(CGSize)baseSize baseArcRadius:(CGFloat)baseArcRadius
{
    if (baseArcRadius == 0) {
        return 0;
    }
    CGFloat baseWidth = baseSize.width;
    CGFloat baseHeight = baseSize.height;
    
    CGFloat w = baseWidth/2;
    CGFloat h = baseHeight;
    CGFloat r = baseArcRadius;
    
    CGFloat a = h / r - 1;
    CGFloat x = 0;
    
    /*
     *公式如下，利用三角形相似原理
     * x/r = sqrt(h^2 + (w-x)^2)/h - (w-x)/h;
     * 最后一元二次方程如下：
     * x^2(a^2-1) + 2w(a+1)x - h^2 = 0;(a != 1)
     * x = (-w(a+1) + sqrt(w^2(a+1)^2 + (a^2-1)h^2))/(a^2-1)
     * x = (-w(a+1) - sqrt(w^2(a+1)^2 + (a^2-1)h^2))/(a^2-1)
     */
    
    if (a == 1) {
        x = h * h / (4 * w);
    }
    else {
        CGFloat delta = w * w * (a+1) * (a + 1) + (a * a - 1) * h * h;
        if (delta < 0 ) {
            return 0;
        }
        CGFloat sqrtDelta = sqrt(delta);
        CGFloat B = - w * (a + 1);
        CGFloat A = a * a - 1;
        
        CGFloat x1 = (B + sqrtDelta)/A;
        if (x1 > 0 && x1 < w) {
            x = x1;
        }
        
        CGFloat x2 = (B - sqrtDelta)/A;
        if (x2 > 0 && x2 < w) {
            x = x2;
        }
        
        NSLog(@"x1=%f,x2=%f",x1,x2);
    }
    NSLog(@"x=%f",x);
    
    return x;
}

+(CGFloat)getBaseShiftWithBaseSize:(CGSize)baseSize topAngleRadian:(CGFloat)topAngleRadian
{
    CGFloat baseWidth = baseSize.width;
    CGFloat baseHeight = baseSize.height;
    
    CGFloat w = baseWidth/2;
    CGFloat h = baseHeight;
    CGFloat topAngleMaxRadian = 2 * atan(w/h);
    
    if (topAngleRadian <= 0 || topAngleRadian > topAngleMaxRadian) {
        return -1;
    }
    
    CGFloat alphaAngleRadian = topAngleRadian/2;
    
    CGFloat baseShift = w - h * tan(alphaAngleRadian);
    return baseShift;
}

+(CGFloat)getTopAngleRadianWithBaseSize:(CGSize)baseSize baseShift:(CGFloat)baseShift
{
    CGFloat baseWidth = baseSize.width;
    CGFloat baseHeight = baseSize.height;
    if (baseShift > baseWidth/2) {
        return 0;
    }
    CGFloat alphaAngleRadian = M_PI_2;
    if (baseHeight > 0) {
        alphaAngleRadian = atan((baseWidth/2 - baseShift)/baseHeight);
    }
    CGFloat topAngleRadian = 2 * alphaAngleRadian;
    return topAngleRadian;
}


+(CGFloat)getBaseAngleArcRadiusWithBaseSize:(CGSize)baseSize baseShift:(CGFloat)baseShift
{
    CGFloat topAngleRadian = [self getTopAngleRadianWithBaseSize:baseSize baseShift:baseShift];
    CGFloat baseAngleRadian = (M_PI_2 - topAngleRadian/2)/2;
    CGFloat baseAngleArcRadius = baseShift / tan(baseAngleRadian/2);
    return baseAngleArcRadius;
}

+(UIBezierPath*)_createIsoscelesTrianglePathWithBaseSize:(CGSize)baseSize topArcRadius:(CGFloat)topArcRadius baseShift:(CGFloat)baseShift topAngleDirection:(YZHUIPopViewArrowDirection)direction
{
    if (direction <= YZHUIPopViewArrowDirectionAny || direction > YZHUIPopViewArrowDirectionRight) {
        return nil;
    }
    
    CGFloat baseWidth = baseSize.width;
    CGFloat baseHeight = baseSize.height;
    
    CGFloat w = baseWidth/2;
    CGFloat h = baseHeight;
    
    CGFloat alphaAngle = atan((w-baseShift)/h);
    CGFloat baseArcAngle = M_PI_2 - alphaAngle;
    
    CGFloat baseAngelArcRadius = baseShift / tan(baseArcAngle/2);
    
    CGFloat sideLen = topArcRadius / tan(alphaAngle);
    CGFloat topShiftX = sideLen * sin(alphaAngle);
    CGFloat topShiftY = sideLen * cos(alphaAngle);
    
    CGFloat diffAngle = 0.0001;
    CGFloat topHalfArcAngle = M_PI_2 - alphaAngle + diffAngle;
    
    CGFloat topAngleArcRadiusShift = topArcRadius / sin(alphaAngle);
    
    CGFloat lastLinePointX = baseWidth - baseAngelArcRadius * sin(baseArcAngle);
//    CGFloat lastLinePointX = baseWidth - baseShift - baseShift * cos(baseArcAngle);
    CGFloat lastLinePointY = baseShift * sin(baseArcAngle);
    
    CGPoint arcCenter = CGPointMake(0, h - baseAngelArcRadius);
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    CGFloat x = 0;
    CGFloat y = 0;
    if (direction == YZHUIPopViewArrowDirectionUp) {
        [path addArcWithCenter:arcCenter radius:baseAngelArcRadius startAngle:M_PI_2 endAngle:M_PI_2 - baseArcAngle clockwise:NO];
        
        x = w - topShiftX;
        y = topShiftY;
        [path addLineToPoint:CGPointMake(x, y)];
        
        x = w;
        y = topAngleArcRadiusShift;
        [path addArcWithCenter:CGPointMake(x, y) radius:topArcRadius startAngle:3 * M_PI_2 - topHalfArcAngle endAngle:3 * M_PI_2 + topHalfArcAngle clockwise:YES];
        
        x = lastLinePointX;
        y = h - lastLinePointY;
        [path addLineToPoint:CGPointMake(x, y)];
        
        arcCenter = CGPointMake(baseWidth, h - baseAngelArcRadius);
        [path addArcWithCenter:arcCenter radius:baseAngelArcRadius startAngle:M_PI_2 + baseArcAngle endAngle:M_PI_2 clockwise:NO];
    }
    else if (direction == YZHUIPopViewArrowDirectionLeft) {
        arcCenter = CGPointMake(h - baseAngelArcRadius, 0);
        [path addArcWithCenter:arcCenter radius:baseAngelArcRadius startAngle:0 endAngle:baseArcAngle clockwise:YES];
        
        x = topShiftY;
        y = w - topShiftX;
        [path addLineToPoint:CGPointMake(x, y)];
        
        x = topAngleArcRadiusShift;
        y = w;
        [path addArcWithCenter:CGPointMake(x, y) radius:topArcRadius startAngle:M_PI + topHalfArcAngle endAngle:M_PI - topHalfArcAngle clockwise:NO];
        
        x = h - lastLinePointY;
        y = lastLinePointX;
        [path addLineToPoint:CGPointMake(x, y)];
        
        arcCenter = CGPointMake(h - baseAngelArcRadius,baseWidth);
        [path addArcWithCenter:arcCenter radius:baseAngelArcRadius startAngle:2 * M_PI - baseArcAngle endAngle:2 * M_PI clockwise:YES];
    }
    else if (direction == YZHUIPopViewArrowDirectionDown) {
        arcCenter = CGPointMake(0, baseAngelArcRadius);
        [path addArcWithCenter:arcCenter radius:baseAngelArcRadius startAngle:3 * M_PI_2 endAngle:3 * M_PI_2 + baseArcAngle clockwise:YES];
        
        x = w - topShiftX;
        y = h - topShiftY;
        [path addLineToPoint:CGPointMake(x, y)];
        
        x = w;
        y = h - topAngleArcRadiusShift;
        [path addArcWithCenter:CGPointMake(x, y) radius:topArcRadius startAngle:M_PI_2 + topHalfArcAngle endAngle:M_PI_2 - topHalfArcAngle clockwise:NO];
        
        x = lastLinePointX;
        y = lastLinePointY;
        [path addLineToPoint:CGPointMake(x, y)];
        
        arcCenter = CGPointMake(baseWidth, baseAngelArcRadius);
        [path addArcWithCenter:arcCenter radius:baseAngelArcRadius startAngle:3 * M_PI_2 - baseArcAngle endAngle:3 * M_PI_2 clockwise:YES];
    }
    else if (direction == YZHUIPopViewArrowDirectionRight) {
        arcCenter = CGPointMake(baseAngelArcRadius, 0);
        [path addArcWithCenter:arcCenter radius:baseAngelArcRadius startAngle:M_PI endAngle:M_PI- baseArcAngle clockwise:NO];
        
        x = h - topShiftY;
        y = w - topShiftX;
        [path addLineToPoint:CGPointMake(x, y)];
        
        x = h - topAngleArcRadiusShift;
        y = w;
        [path addArcWithCenter:CGPointMake(x, y) radius:topArcRadius startAngle:-topHalfArcAngle endAngle:topHalfArcAngle clockwise:YES];
        
        x = lastLinePointY;
        y = lastLinePointX;
        [path addLineToPoint:CGPointMake(x, y)];
        
        arcCenter = CGPointMake(baseAngelArcRadius, baseWidth);
        [path addArcWithCenter:arcCenter radius:baseAngelArcRadius startAngle:M_PI + baseArcAngle endAngle:M_PI clockwise:NO];
    }
    return path;
}

+(UIBezierPath*)createIsoscelesTrianglePathWithBaseSize:(CGSize)baseSize topArcRadius:(CGFloat)topArcRadius baseArcRadius:(CGFloat)baseArcRadius topAngleDirection:(YZHUIPopViewArrowDirection)direction
{
    
    if (direction <= YZHUIPopViewArrowDirectionAny || direction > YZHUIPopViewArrowDirectionRight) {
        return nil;
    }
    
    CGFloat baseShift = [YZHPopArrowContext _getBaseArcBaseShiftWithBaseSize:baseSize baseArcRadius:baseArcRadius];
    
    return [YZHPopArrowContext _createIsoscelesTrianglePathWithBaseSize:baseSize topArcRadius:topArcRadius baseShift:baseShift topAngleDirection:direction];
}

+(UIBezierPath*)createIsoscelesTrianglePathWithBaseSize:(CGSize)baseSize topArcRadius:(CGFloat)topArcRadius topAngleRadian:(CGFloat)topAngleRadian topAngleDirection:(YZHUIPopViewArrowDirection)direction
{
    if (direction <= YZHUIPopViewArrowDirectionAny || direction > YZHUIPopViewArrowDirectionRight) {
        return nil;
    }
    CGFloat baseShift = [YZHPopArrowContext getBaseShiftWithBaseSize:baseSize topAngleRadian:topAngleRadian];
    if (baseShift < 0) {
        return nil;
    }
    
    return [YZHPopArrowContext _createIsoscelesTrianglePathWithBaseSize:baseSize topArcRadius:topArcRadius baseShift:baseShift topAngleDirection:direction];
}

+(UIBezierPath*)createIsoscelesTrianglePathBaseHeight:(CGFloat)baseHeight baseShift:(CGFloat)baseShift topArcRadius:(CGFloat)topArcRadius topAngleRadian:(CGFloat)topAngleRadian topAngleDirection:(YZHUIPopViewArrowDirection)direction
{
    if (direction <= YZHUIPopViewArrowDirectionAny || direction > YZHUIPopViewArrowDirectionRight || baseShift < 0) {
        return nil;
    }
    
    CGFloat alphaAngleRadian = topAngleRadian/2;
    
    CGFloat w = baseHeight * tan(alphaAngleRadian);
    CGFloat baseWidth = 2 * (w + baseShift);
    
    CGSize baseSize = CGSizeMake(baseWidth, baseHeight);
    
    return [YZHPopArrowContext _createIsoscelesTrianglePathWithBaseSize:baseSize topArcRadius:topArcRadius baseShift:baseShift topAngleDirection:direction];
}

/*
 *在base的矩形中画一个顶角为arrowRadian的等腰三角形，
 *arrowArcRadius为顶角的圆弧，
 *底边带有圆弧效果根据baseSize和arrowRadian来计算
 */
-(instancetype)initWithBaseSize:(CGSize)baseSize arrowRadian:(CGFloat)arrowRadian arrowArcRadius:(CGFloat)arrowArcRadius
{
    self = [super init];
    if (self) {
        self.baseSize = baseSize;
        self.arrowRadian = arrowRadian;
        self.arrowArcRadius = arrowArcRadius;
    }
    return self;
}

/*
 *在base的矩形中画一个等腰三角形，
 *arrowArcRadius为顶角的圆弧，
 *底边带有圆弧的半径为baseAngelArcRadius，
 *顶角的大小根据根据三角形相似的公式来计算
 */
-(instancetype)initWithBaseSize:(CGSize)baseSize baseArcRadius:(CGFloat)baseArcRadius arrowArcRadius:(CGFloat)arrowArcRadius
{

    CGFloat baseShift = [YZHPopArrowContext _getBaseArcBaseShiftWithBaseSize:baseSize baseArcRadius:baseArcRadius];
    
    CGFloat arrowRadian = [YZHPopArrowContext getTopAngleRadianWithBaseSize:baseSize baseShift:baseShift];
    
    return [self initWithBaseSize:baseSize arrowRadian:arrowRadian arrowArcRadius:arrowArcRadius];
}

/*
 *在base的矩形中画一个等腰三角形，
 *arrowArcRadius为顶角的圆弧，
 *baseShift为底边上左右各偏移baseShift,
 *顶角的大小为alphaAngle = 2 * atan((baseSize.width/2 - baseShift)/baseSize.height)
 *底角大小为baseArcAngle = M_PI_2 - alphaAngle/2;
 *baseAngelArcRadius为baseShift / tan(baseArcAngle/2);
 */
-(instancetype)initWithBaseSize:(CGSize)baseSize baseShift:(CGFloat)baseShift arrowArcRadius:(CGFloat)arrowArcRadius
{
    CGFloat arrowRadian = [YZHPopArrowContext getTopAngleRadianWithBaseSize:baseSize baseShift:baseShift];
    return [self initWithBaseSize:baseSize arrowRadian:arrowRadian arrowArcRadius:arrowArcRadius];
}

/*
 *在base的矩形中画一个等腰三角形，
 *arrowArcRadius为顶角的圆弧，
 *baseShift为底边上左右各偏移baseShift,
 *顶角的大小为alphaAngle = arrowRadian
 *底边的大小为baseWidth = 2 * (baseHeight * tan(alphaAngle/2) + baseShift);
 */
-(instancetype)initWithBaseHeight:(CGFloat)baseHeight baseShift:(CGFloat)baseShift arrowRadian:(CGFloat)arrowRadian arrowArcRadius:(CGFloat)arrowArcRadius
{
    if (baseHeight == 0 || arrowRadian >= M_PI || baseShift < 0) {
        return nil;
    }

    CGFloat alphaAngleRadian = arrowRadian/2;
    
    CGFloat w = baseHeight * tan(alphaAngleRadian);
    CGFloat baseWidth = 2 * (w + baseShift);
    
    CGSize baseSize = CGSizeMake(baseWidth, baseHeight);
    
    return [self initWithBaseSize:baseSize arrowRadian:arrowRadian arrowArcRadius:arrowArcRadius];
}

-(UIBezierPath*)bezierPathForArrowDirection:(YZHUIPopViewArrowDirection)arrowDirection
{
    return [YZHPopArrowContext createIsoscelesTrianglePathWithBaseSize:self.baseSize topArcRadius:self.arrowArcRadius topAngleRadian:self.arrowRadian topAngleDirection:arrowDirection];
}

-(CGFloat)baseAngleArcRadius
{
    CGFloat baseShift = [YZHPopArrowContext getBaseShiftWithBaseSize:self.baseSize topAngleRadian:self.arrowRadian];
    return [YZHPopArrowContext getBaseAngleArcRadiusWithBaseSize:self.baseSize baseShift:baseShift];
}
@end


/**************************************************************************
 *YZHPopActionContext
 **************************************************************************/
@interface YZHPopActionContext : NSObject
//分数，按分数先排布
@property (nonatomic, assign) CGFloat score;

//操作类型
@property (nonatomic, assign) NSPopActionType actionType;

//箭头方向
@property (nonatomic, assign) YZHUIPopViewArrowDirection arrowDirection;

//分数一样时，按大小
@property (nonatomic, assign) CGSize popContentSize;

//分数一样时，大小也一样时，按三角形要移动的多少来排（也就是美观）
@property (nonatomic, assign) CGFloat triangleViewOffsetRatio;

//当时的arrow的frame
@property (nonatomic, assign) CGRect arrowFrame;

//当时的arrow的frame
@property (nonatomic, assign) CGRect popViewFrame;

/* <#注释#> */
@property (nonatomic, strong) YZHPopArrowContext *arrowCtx;

/* <#name#> */
@property (nonatomic, assign) CGFloat contentCornerRadius;
@end

@implementation YZHPopActionContext
-(NSString*)description
{
    return [NSString stringWithFormat:@"_score=%f,_actionType=%ld,arrowDirection=%ld,popContentSize=%@,triangleViewOffsetRatio=%f,arrowFrame=%@,popViewFrame=%@",self.score,self.actionType,self.arrowDirection,NSStringFromCGSize(self.popContentSize),self.triangleViewOffsetRatio,NSStringFromCGRect(self.arrowFrame),NSStringFromCGRect(self.popViewFrame)];
}
@end



/**************************************************************************
 *YZHUIPopView
 **************************************************************************/
@interface YZHUIPopView ()<UITableViewDelegate,UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, weak) UIView *showInView;

@property (nonatomic, strong) UIView *innerContentView;

//对应的路径
//@property (nonatomic, strong) UIBezierPath *bezierPath;

//每个操作对应要扣除的分数
@property (nonatomic, copy) NSDictionary<NSNumber*, NSNumber*> *actionTypeInfos;

@end

@implementation YZHUIPopView

@synthesize cover = _cover;
@synthesize effectView = _effectView;

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _setupDefaultValue];
        [self _setupChildView];
    }
    return self;
}

//使用此方法时，后面进行show的时候只能是[popview popViewFromOverView:(UIView*)overView showInView:(UIView*)showInView animated:(BOOL)animated];
-(instancetype)initWithPopContentSize:(CGSize)popContentSize
{
    self = [super init];
    if (self) {
        self.popContentSize = popContentSize;
    }
    return self;
}

//后面进行show的时候三者均可以，但是popOverRect必须是相当于showInView的rect
-(instancetype)initWithPopContentSize:(CGSize)popContentSize fromRect:(CGRect)popOverRect
{
    self = [super init];
    if (self) {
        self.popOverRect = popOverRect;
        self.popContentSize = popContentSize;
    }
    return self;
}

//后面进行show的时候三者均可以
-(instancetype)initWithPopContentSize:(CGSize)popContentSize fromOverView:(UIView*)overView showInView:(UIView*)showInView
{
    CGRect overRect = [overView.superview convertRect:overView.frame toView:showInView];
    self = [self initWithPopContentSize:popContentSize fromRect:overRect];
    if (self) {
        self.showInView = showInView;
    }
    return self;
}

-(UIButton*)cover
{
    if (_cover == nil) {
        _cover = [UIButton buttonWithType:UIButtonTypeCustom];
        _cover.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _cover.backgroundColor = BLACK_COLOR;
        _cover.alpha = 0.1;
        [_cover addTarget:self action:@selector(_coverClickAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cover;
}

-(UIView*)effectView
{
    if (_effectView == nil) {
        if (SYSTEMVERSION_NUMBER > 8.0) {
            UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
            UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            _effectView = effectView;
        }
        else
        {
            UIToolbar *toolBar = [[UIToolbar alloc] init];
            toolBar.barStyle = UIBarStyleBlack;
            _effectView = toolBar;
        }
    }
    return _effectView;
}

-(void)_setupDefaultValue
{
    self.arrowDirection = YZHUIPopViewArrowDirectionAny;
    self.contentCornerRadius = 5.0;
    
    self.arrowCtx = [[YZHPopArrowContext alloc] initWithBaseSize:CGSizeMake(36, 15) arrowRadian:DEGREES_TO_RADIANS(82) arrowArcRadius:3];
    
    self.popViewEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    
    self.arrowDirectionPriorityOrder = @[@(YZHUIPopViewArrowDirectionUp),@(YZHUIPopViewArrowDirectionLeft),@(YZHUIPopViewArrowDirectionDown),@(YZHUIPopViewArrowDirectionRight)];
    
    NSMutableDictionary *infos = [NSMutableDictionary dictionary];
    [infos setObject:@(0.0) forKey:@(NSPopActionTypeNone)];
    [infos setObject:@(10.0) forKey:@(NSPopActionTypeAdjustArrow)];
    [infos setObject:@(10.0) forKey:@(NSPopActionTypeAdjustWidth)];
    [infos setObject:@(10.0) forKey:@(NSPopActionTypeAdjustHeight)];
    [infos setObject:@(10.0) forKey:@(NSPopActionTypeInnerInsets)];
    [infos setObject:@(40.0) forKey:@(NSPopActionTypeArrowNotIn)];
    [infos setObject:@(10.0) forKey:@(NSPopActionTypeArrowNotPointCenter)];
    self.actionTypeInfos = infos;
    
    self.innerBackgroundColor = CLEAR_COLOR;
}

-(void)_setupChildView
{
    [self addSubview:self.effectView];
    self.backgroundColor = WHITE_COLOR;
    
    CAShapeLayer *borderLayer = [CAShapeLayer new];
    [self.layer addSublayer:borderLayer];
    _borderLayer = borderLayer;
    
    UIView *innerContentView = [UIView new];
    innerContentView.backgroundColor = self.innerBackgroundColor;
    [self addSubview:innerContentView];
    self.innerContentView = innerContentView;
}

-(void)_coverClickAction:(UIButton*)sender
{
    [self dismiss];
}

-(CGFloat)_getActionTypeScoreForType:(NSPopActionType)actionType
{
    return [[self.actionTypeInfos objectForKey:@(actionType)] floatValue];
}


-(YZHPopActionContext*)_getPopActionContextForArrowDirection:(YZHUIPopViewArrowDirection)arrowDirection popContentSize:(CGSize)popContentSize popOverRect:(CGRect)popOverRect showInViewSize:(CGSize)showInViewSize
{
    CGFloat score = popActionFullScore_s;
    CGFloat triangleViewOffsetRatio = 0;
    NSPopActionType actionType = NSPopActionTypeNone;
    CGRect arrowFrame = {0,0, self.arrowCtx.baseSize};
    
    CGFloat x = 0;
    CGFloat y = 0;
    CGFloat w = 0;
    CGFloat h = 0;
    
    YZHPopActionContext *ctx = [[YZHPopActionContext alloc] init];
    
    if (arrowDirection == YZHUIPopViewArrowDirectionUp || arrowDirection == YZHUIPopViewArrowDirectionDown) {
        CGFloat triangleViewMinCenterX = self.popViewEdgeInsets.left + self.contentCornerRadius + self.arrowCtx.baseSize.width/2;
        CGFloat triangleViewMaxCenterX = showInViewSize.width - (self.popViewEdgeInsets.right + self.contentCornerRadius + self.arrowCtx.baseSize.width/2);
        
        CGFloat triangleViewMidMinCenterX = self.popViewEdgeInsets.left + popContentSize.width/2;
        CGFloat triangleViewMidMaxCenterX = showInViewSize.width - self.popViewEdgeInsets.right - popContentSize.width/2;
        
        CGFloat triangleViewX = (popContentSize.width - self.arrowCtx.baseSize.width)/2;
        
        CGFloat popOverViewMinX = popOverRect.origin.x;
        CGFloat popOverViewMaxX = CGRectGetMaxX(popOverRect);
        CGFloat popOverViewCenterX = CGRectGetMidX(popOverRect);
        
        CGFloat offsetX = 0;
        arrowFrame.origin = CGPointMake(triangleViewX, 0);
        
        w = popContentSize.width;
        h = popContentSize.height + self.arrowCtx.baseSize.height;
        if (arrowDirection == YZHUIPopViewArrowDirectionUp) {
            y = CGRectGetMaxY(popOverRect);
        }
        else {
            y = CGRectGetMinY(popOverRect) - h;
        }
        
        if (popOverViewMaxX < triangleViewMinCenterX || popOverViewMinX > triangleViewMaxCenterX) {
            score -= [self _getActionTypeScoreForType:NSPopActionTypeArrowNotIn];
            actionType |= NSPopActionTypeArrowNotIn;
            
            if (popOverViewMaxX < triangleViewMinCenterX) {
                arrowFrame.origin = CGPointMake(self.contentCornerRadius, 0);
                offsetX = triangleViewX - arrowFrame.origin.x;

                x = self.popViewEdgeInsets.left;
            }
            else {
                arrowFrame.origin = CGPointMake(popContentSize.width - self.contentCornerRadius - self.arrowCtx.baseSize.width, 0);
                offsetX = arrowFrame.origin.x - triangleViewX;
                
                x = showInViewSize.width - self.popViewEdgeInsets.right - popContentSize.width;
            }
        }
        else {
            if (popOverViewCenterX < triangleViewMidMinCenterX || popOverViewCenterX > triangleViewMidMaxCenterX) {
                score -= [self _getActionTypeScoreForType:NSPopActionTypeAdjustArrow];
                actionType |= NSPopActionTypeAdjustArrow;
                
                BOOL isLeftShift = NO;
                if (popOverViewCenterX < triangleViewMidMinCenterX) {
                    offsetX = triangleViewMidMinCenterX - popOverViewCenterX;
                    arrowFrame.origin = CGPointMake(triangleViewX - offsetX, 0);
                    isLeftShift = YES;
                    
                    x = self.popViewEdgeInsets.left;
                }
                else {
                    offsetX = popOverViewCenterX - triangleViewMidMaxCenterX;
                    arrowFrame.origin = CGPointMake(triangleViewX + offsetX, 0);
                    
                    x = showInViewSize.width - self.popViewEdgeInsets.right - popContentSize.width;
                }
                
                CGFloat maxOffsetX = popContentSize.width/2 - self.contentCornerRadius;
                if (offsetX > maxOffsetX) {
                    offsetX = maxOffsetX;
                    score -= [self _getActionTypeScoreForType:NSPopActionTypeArrowNotPointCenter];
                    actionType |= NSPopActionTypeArrowNotPointCenter;
                    if (isLeftShift) {
                        arrowFrame.origin = CGPointMake(triangleViewX - offsetX, 0);
                    }
                    else {
                        arrowFrame.origin = CGPointMake(triangleViewX + offsetX, 0);
                    }
                }
            }
            else {
                x = popOverViewCenterX - popContentSize.width/2;
            }
        }
        triangleViewOffsetRatio = offsetX / popContentSize.width;
    }
    else {
        CGFloat triangleViewMinCenterY = self.popViewEdgeInsets.top + self.contentCornerRadius + self.arrowCtx.baseSize.width/2;
        CGFloat triangleViewMaxCenterY = showInViewSize.height - (self.popViewEdgeInsets.bottom + self.contentCornerRadius + self.arrowCtx.baseSize.width/2);
        
        CGFloat triangleViewMidMinCenterY = self.popViewEdgeInsets.top + popContentSize.height/2;
        CGFloat triangleViewMidMaxCenterY = showInViewSize.height - self.popViewEdgeInsets.bottom - popContentSize.height/2;
        
        CGFloat triangleViewY = (popContentSize.height - self.arrowCtx.baseSize.width)/2;
        
        CGFloat popOverViewMinY = popOverRect.origin.y;
        CGFloat popOverViewMaxY = CGRectGetMaxY(popOverRect);
        CGFloat popOverViewCenterY = CGRectGetMidY(popOverRect);
        
        CGFloat offsetY = 0;
        arrowFrame.origin = CGPointMake(0, triangleViewY);
        
        w = popContentSize.width + self.arrowCtx.baseSize.height;
        h = popContentSize.height;
        if (arrowDirection == YZHUIPopViewArrowDirectionLeft) {
            x = CGRectGetMaxX(popOverRect);
        }
        else {
            x = CGRectGetMinX(popOverRect) - w;
        }
        
        if (popOverViewMaxY < triangleViewMinCenterY || popOverViewMinY > triangleViewMaxCenterY) {
            score -= [self _getActionTypeScoreForType:NSPopActionTypeArrowNotIn];
            actionType |= NSPopActionTypeArrowNotIn;
            
            if (popOverViewMaxY < triangleViewMinCenterY) {
                arrowFrame.origin = CGPointMake(0, self.contentCornerRadius);
                offsetY = triangleViewY - arrowFrame.origin.y;
                
                y = self.popViewEdgeInsets.top;
            }
            else {
                arrowFrame.origin = CGPointMake(0, popContentSize.height - self.contentCornerRadius - self.arrowCtx.baseSize.width);
                offsetY = arrowFrame.origin.x - triangleViewY;
                
                y = showInViewSize.height - self.popViewEdgeInsets.bottom - h;
            }
        }
        else {
            if (popOverViewCenterY < triangleViewMidMinCenterY || popOverViewCenterY > triangleViewMidMaxCenterY) {
                score -= [self _getActionTypeScoreForType:NSPopActionTypeAdjustArrow];
                actionType |= NSPopActionTypeAdjustArrow;
                
                BOOL isTopShift = NO;
                if (popOverViewCenterY < triangleViewMidMinCenterY) {
                    offsetY = triangleViewMidMinCenterY - popOverViewCenterY;
                    arrowFrame.origin = CGPointMake(0, triangleViewY - offsetY);
                    isTopShift = YES;
                    
                    y = self.popViewEdgeInsets.top;
                }
                else {
                    offsetY = popOverViewCenterY - triangleViewMidMaxCenterY;
                    arrowFrame.origin = CGPointMake(0, triangleViewY + offsetY);
                    
                    y = showInViewSize.height - self.popViewEdgeInsets.bottom - popContentSize.height;
                }
                CGFloat maxOffsetY = popContentSize.height/2 - self.contentCornerRadius;
                if (offsetY > maxOffsetY) {
                    offsetY = maxOffsetY;
                    score -= [self _getActionTypeScoreForType:NSPopActionTypeArrowNotPointCenter];
                    actionType |= NSPopActionTypeArrowNotPointCenter;
                    if (isTopShift) {
                        arrowFrame.origin = CGPointMake(0, triangleViewY - offsetY);
                    }
                    else {
                        arrowFrame.origin = CGPointMake(0, triangleViewY + offsetY);
                    }
                }
            }
            else {
                y = popOverViewCenterY - popContentSize.height/2;
            }
        }
        triangleViewOffsetRatio = offsetY / popContentSize.height;
    }
    
    ctx.score = score;
    ctx.actionType = actionType;
    ctx.arrowDirection = arrowDirection;
    ctx.popContentSize = popContentSize;
    ctx.triangleViewOffsetRatio = triangleViewOffsetRatio;
    ctx.arrowFrame = arrowFrame;
    ctx.popViewFrame = CGRectMake(x, y, w, h);
    return ctx;
}

-(YZHPopActionContext*)_getPopViewBestArrowDirection:(YZHUIPopViewArrowDirection)arrowDirection popContentSize:(CGSize)popContentSize
{
    CGSize showInViewSize = self.showInView.bounds.size;
    if (arrowDirection != YZHUIPopViewArrowDirectionAny) {
        popContentSize = [self _getContentSizeForArrowDirection:arrowDirection popOverRect:self.popOverRect popContentSize:popContentSize showInViewSize:showInViewSize];
        return [self _getPopActionContextForArrowDirection:arrowDirection popContentSize:popContentSize popOverRect:self.popOverRect showInViewSize:showInViewSize];
    }
    
    YZHPopActionContext *ctxMax = nil;
    for (NSNumber *arrowDirectionValue in self.arrowDirectionPriorityOrder) {
        YZHUIPopViewArrowDirection arrowDirection = [arrowDirectionValue integerValue];
        
        CGSize popContentSizeTmp = [self _getContentSizeForArrowDirection:arrowDirection popOverRect:self.popOverRect popContentSize:popContentSize showInViewSize:showInViewSize];

        NSLog(@"popContentSizeTmp=%@,contentSize=%@",NSStringFromCGSize(popContentSizeTmp),NSStringFromCGSize(popContentSize));
        YZHPopActionContext *ctx = [self _getPopActionContextForArrowDirection:arrowDirection popContentSize:popContentSizeTmp popOverRect:self.popOverRect showInViewSize:showInViewSize];
        if (ctxMax == nil) {
            ctxMax = ctx;
        }
        else {
            if (ctx.score > ctxMax.score) {
                ctxMax = ctx;
            }
            else if (ctx.score == ctxMax.score) {
                CGFloat ctxArea = ctx.popContentSize.width * ctx.popContentSize.height;
                CGFloat ctxMaxArea = ctxMax.popContentSize.width * ctxMax.popContentSize.height;
                if (ctxArea > ctxMaxArea) {
                    ctxMax = ctx;
                }
                else {
                    if (ctx.triangleViewOffsetRatio < ctxMax.triangleViewOffsetRatio) {
                        ctxMax = ctx;
                    }
                }
            }
        }
        NSLog(@"ctxMax.arrowDirection=%ld",ctxMax.arrowDirection);
    }
    return ctxMax;
}

-(CGSize)_getContentSizeForArrowDirection:(YZHUIPopViewArrowDirection)arrowDirection popOverRect:(CGRect)popOverRect popContentSize:(CGSize)popContentSize showInViewSize:(CGSize)showInViewSize
{
    if (arrowDirection == YZHUIPopViewArrowDirectionAny) {
        return CGSizeZero;
    }
    
//    CGFloat x = popOverRect.origin.x;
    CGFloat y = popOverRect.origin.y;
//    CGFloat maxX = CGRectGetMaxX(popOverRect);
    CGFloat maxY = CGRectGetMaxY(popOverRect);
    
    CGFloat topSpace = y - self.popViewEdgeInsets.top;
//    CGFloat leftSpace = showInViewSize.width - x - self.popViewEdgeInsets.left;
    CGFloat bottomSpace = showInViewSize.height - maxY - self.popViewEdgeInsets.bottom;
//    CGFloat rightSpace = showInViewSize.width - maxX - self.popViewEdgeInsets.right;
    
    CGFloat width = popContentSize.width;
    CGFloat height = popContentSize.height;
    
    CGFloat tableViewHeight = 0;
    if (self.contentType == YZHUIPopViewContentTypeTableView && self.tableView.delegate == self) {
        NSInteger rows = [self tableView:self.tableView numberOfRowsInSection:0];
        for (NSInteger i = 0; i < rows; ++i) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
            CGFloat height = [self.tableView.delegate tableView:self.tableView heightForRowAtIndexPath:indexPath];
            tableViewHeight += height;
        }
        if (tableViewHeight > 0) {
            tableViewHeight += 2 * self.borderWidth;
        }
    }
    
    if (arrowDirection == YZHUIPopViewArrowDirectionUp || arrowDirection == YZHUIPopViewArrowDirectionDown) {
        width = MIN(width, showInViewSize.width - self.popViewEdgeInsets.left - self.popViewEdgeInsets.right);

        if (arrowDirection == YZHUIPopViewArrowDirectionUp) {
            bottomSpace = bottomSpace - self.arrowCtx.baseSize.height;
            height = MIN(height, bottomSpace);
        }
        else {
            topSpace = topSpace - self.arrowCtx.baseSize.height;
            height = MIN(height, topSpace);
        }
        
        if (self.contentType == YZHUIPopViewContentTypeTableView) {
            if (tableViewHeight > 0) {
                height = MIN(height, tableViewHeight);
            }
        }
        else if (self.contentType == YZHUIPopViewContentTypeCollectionView) {
            [self.collectionView.collectionViewLayout prepareLayout];
            CGFloat cW = self.collectionView.collectionViewLayout.collectionViewContentSize.width + 2 * self.borderWidth;
            CGFloat cH = self.collectionView.collectionViewLayout.collectionViewContentSize.height + 2 * self.borderWidth;
            width = MIN(width, cW);
            height = MIN(height, cH);
        }
    }
    else if (arrowDirection == YZHUIPopViewArrowDirectionLeft || arrowDirection == YZHUIPopViewArrowDirectionRight) {
        height = MIN(height, showInViewSize.height - self.popViewEdgeInsets.top - self.popViewEdgeInsets.bottom);
        
        if (self.contentType == YZHUIPopViewContentTypeTableView) {
            if (tableViewHeight > 0) {
                height = MIN(height, tableViewHeight);
            }
        }
        else if (self.contentType == YZHUIPopViewContentTypeCollectionView) {
            [self.collectionView.collectionViewLayout prepareLayout];
            CGFloat cW = self.collectionView.collectionViewLayout.collectionViewContentSize.width + 2 * self.borderWidth;
            CGFloat cH = self.collectionView.collectionViewLayout.collectionViewContentSize.height + 2 * self.borderWidth;
            
            width = MIN(width, cW);
            height = MIN(height, cH);
        }
    }
    return CGSizeMake(width, height);
}

-(void)_setupCover
{
    CGRect frame = self.showInView.bounds;
    self.cover.frame = frame;
    [self.showInView insertSubview:self.cover belowSubview:self];
}

-(void)_setupInnerContentView:(CGSize)popContentSize
{
    [self.innerContentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    if (self.contentType == YZHUIPopViewContentTypeTableView) {
        UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        tableView.bounces = NO;
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.backgroundColor = CLEAR_COLOR;
        tableView.showsVerticalScrollIndicator = NO;
        tableView.showsHorizontalScrollIndicator = NO;
        tableView.tableFooterView = [UIView new];
        _tableView = tableView;
        [self.innerContentView addSubview:tableView];
        [self.tableView registerClass:[YZHUIPopTableViewCell class] forCellReuseIdentifier:NSSTRING_FROM_CLASS(YZHUIPopTableViewCell)];
    }
    else if (self.contentType == YZHUIPopViewContentTypeCollectionView) {
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.collectionViewLayout];
        collectionView.bounces = NO;
        collectionView.delegate = self;
        collectionView.dataSource = self;
        collectionView.backgroundColor = CLEAR_COLOR;
        collectionView.showsVerticalScrollIndicator = NO;
        collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView = collectionView;
        [self.innerContentView addSubview:collectionView];
        [self.collectionView registerClass:[YZHUIPopCollectionViewCell class] forCellWithReuseIdentifier:NSSTRING_FROM_CLASS(YZHUIPopCollectionViewCell)];
    }
    else if (self.contentType == YZHUIPopViewContentTypeCustom) {
        if (self.customContentViewBlock) {
            CGRect innerContentFrame = CGRectInset(CGRectMake(0, 0, popContentSize.width, popContentSize.height), self.borderWidth, self.borderWidth);
            _customContentView = self.customContentViewBlock(innerContentFrame.size);
            _customContentView.frame = innerContentFrame;
            _customContentView.backgroundColor = CLEAR_COLOR;
            [self.innerContentView addSubview:_customContentView];
        }
    }
}

-(void)_setuplayoutValue:(CGSize)popContentSize
{
    [self _setupCover];
    [self _setupInnerContentView:popContentSize];
}

-(CGRect)_getInnerArrowFrameWithArrowCtx:(YZHPopActionContext*)ctx borderWidth:(CGFloat)borderWidth
{
    CGFloat alphaAngleRadian = ctx.arrowCtx.arrowRadian/2;
    
    CGFloat topShift = self.borderWidth/sin(alphaAngleRadian);
    
    CGFloat baseArcRadius = [ctx.arrowCtx baseAngleArcRadius];
    
    CGFloat arrowBaseWidth = ctx.arrowCtx.baseSize.width;
    CGFloat arrowBaseHeight = ctx.arrowCtx.baseSize.height + borderWidth - topShift;

    CGRect innerArrowFrame = {ctx.arrowFrame.origin,arrowBaseWidth,arrowBaseHeight};
    if (baseArcRadius > borderWidth) {
        if (IS_ARROW_DIRECTION_HORIZONTAL(ctx.arrowDirection)) {
            innerArrowFrame.origin.x -= borderWidth;
            innerArrowFrame.origin.y = 0;
        }
        else {
            innerArrowFrame.origin.x = 0;
            innerArrowFrame.origin.y -= borderWidth;
        }
    }
    else {
        CGFloat decBaseWidth = borderWidth * tan((M_PI_2 - alphaAngleRadian)/2);
        arrowBaseWidth = ctx.arrowFrame.size.width - 2  * decBaseWidth;
        innerArrowFrame.size = CGSizeMake(arrowBaseWidth, arrowBaseHeight);
        if (IS_ARROW_DIRECTION_HORIZONTAL(ctx.arrowDirection)) {
            innerArrowFrame.origin = CGPointMake(innerArrowFrame.origin.x + decBaseWidth - borderWidth, 0);
        }
        else {
            innerArrowFrame.origin = CGPointMake(0, innerArrowFrame.origin.y + decBaseWidth - borderWidth);
        }
    }
    return innerArrowFrame;
}

-(YZHPopActionContext*)_getInnerCtxWithCtx:(YZHPopActionContext*)ctx borderWidth:(CGFloat)borderWidth
{
    YZHPopActionContext *innerCtx = [[YZHPopActionContext alloc] init];
    
    CGFloat alphaAngleRadian = ctx.arrowCtx.arrowRadian/2;
    
    //三角形减少的高度
    CGFloat diffArrowBaseHeight = borderWidth/sin(alphaAngleRadian);
    
    CGFloat diffWidth = 2 * borderWidth;
    CGFloat diffHeight = borderWidth + diffArrowBaseHeight;
    
    CGSize ctxPopViewSize = ctx.popViewFrame.size;
    
    CGFloat innerCWidth = ctx.popContentSize.width - diffWidth;
    CGFloat innerCHeight = ctx.popContentSize.height - diffWidth;
    
    CGFloat arrowArcRadius = MAX(ctx.arrowCtx.arrowRadian - diffArrowBaseHeight, 0);
    
    innerCtx.arrowDirection = ctx.arrowDirection;
    innerCtx.popContentSize = CGSizeMake(innerCWidth, innerCHeight);
    
    CGRect popViewFrame = CGRectZero;
    if (ctx.arrowDirection == YZHUIPopViewArrowDirectionUp) {
        popViewFrame = CGRectMake(borderWidth, diffArrowBaseHeight, ctxPopViewSize.width - diffWidth, ctxPopViewSize.height - diffHeight);
    }
    else if (ctx.arrowDirection == YZHUIPopViewArrowDirectionLeft) {
        popViewFrame = CGRectMake(diffArrowBaseHeight, borderWidth, ctxPopViewSize.width - diffHeight, ctxPopViewSize.height - diffWidth);
    }
    else if (ctx.arrowDirection == YZHUIPopViewArrowDirectionDown) {
        popViewFrame = CGRectMake(borderWidth, borderWidth, ctxPopViewSize.width - diffWidth, ctxPopViewSize.height - diffHeight);
    }
    else if (ctx.arrowDirection == YZHUIPopViewArrowDirectionRight) {
        popViewFrame = CGRectMake(borderWidth, borderWidth, ctxPopViewSize.width - diffHeight, ctxPopViewSize.height - diffWidth);
    }
    innerCtx.popViewFrame = popViewFrame;
    innerCtx.arrowFrame = [self _getInnerArrowFrameWithArrowCtx:ctx borderWidth:borderWidth];
    
    innerCtx.arrowCtx = [[YZHPopArrowContext alloc] initWithBaseSize:innerCtx.arrowFrame.size arrowRadian:ctx.arrowCtx.arrowRadian arrowArcRadius:arrowArcRadius];
    
    innerCtx.contentCornerRadius = MAX(ctx.contentCornerRadius - borderWidth, 0);
    
    return innerCtx;
}

-(UIBezierPath *)_getBorderPath:(YZHPopActionContext*)ctx borderWidth:(CGFloat)borderWidth cornerRadius:(CGFloat)cornerRadius arrowTransform:(CGAffineTransform)arrowTransform
{
    UIBezierPath *borderPath = [UIBezierPath bezierPath];
    
    CGSize arrowBaseSize = ctx.arrowCtx.baseSize;
    
    CGFloat halfBorderWidth = borderWidth/2;
    
    UIBezierPath *arrowPath = [ctx.arrowCtx bezierPathForArrowDirection:ctx.arrowDirection];
    CGPathRef arrowCGPath = CGPathCreateCopyByStrokingPath(arrowPath.CGPath, NULL, borderWidth, kCGLineCapButt, kCGLineJoinMiter, 0);
    UIBezierPath *arrowBorderPath = [UIBezierPath bezierPathWithCGPath:arrowCGPath];
    [arrowBorderPath applyTransform:arrowTransform];
    CGPathRelease(arrowCGPath);
    
    CGFloat x = cornerRadius;
    CGFloat y = arrowBaseSize.height + halfBorderWidth;
    
    //画三角圆弧
    [borderPath appendPath:arrowBorderPath];
    if (ctx.arrowDirection == YZHUIPopViewArrowDirectionUp) {
        //画右上边横
        x = CGRectGetMaxX(ctx.arrowFrame);
        [borderPath moveToPoint:CGPointMake(x, y)];
        
        x = ctx.popContentSize.width - cornerRadius;
//        [borderPath addLineToPoint:CGPointMake(x, y)];
        
        //画右上圆弧
        y = arrowBaseSize.height + cornerRadius;
        [borderPath addArcWithCenter:CGPointMake(x, y) radius:cornerRadius - halfBorderWidth startAngle:-M_PI_2 endAngle:0 clockwise:YES];
        
        //画右边竖线
        y = ctx.popViewFrame.size.height - cornerRadius;
//        [borderPath addLineToPoint:CGPointMake(x, y)];
        
        //画右下弧度
        x = ctx.popContentSize.width - cornerRadius;
        [borderPath addArcWithCenter:CGPointMake(x, y) radius:cornerRadius - halfBorderWidth startAngle:0 endAngle:M_PI_2 clockwise:YES];
        
        //画下边横线，终点
        x = cornerRadius;
//        [borderPath addLineToPoint:CGPointMake(x, y)];
        
        //画左下弧度
        y = ctx.popViewFrame.size.height - cornerRadius;
        [borderPath addArcWithCenter:CGPointMake(x, y) radius:cornerRadius - halfBorderWidth startAngle:M_PI_2 endAngle:M_PI clockwise:YES];
        
        //画左边终点
        y = arrowBaseSize.height + cornerRadius;
//        [borderPath addLineToPoint:CGPointMake(x, y)];
        
        //画左上弧度
        x = cornerRadius;
        [borderPath addArcWithCenter:CGPointMake(x, y) radius:cornerRadius - halfBorderWidth startAngle:M_PI endAngle:-M_PI_2 clockwise:YES];

        //画左上边横，终点
        x = ctx.arrowFrame.origin.x;
        y = arrowBaseSize.height + halfBorderWidth;
        [borderPath addLineToPoint:CGPointMake(x, y)];
    }
    else if (ctx.arrowDirection == YZHUIPopViewArrowDirectionLeft) {
        x = arrowBaseSize.height + halfBorderWidth;
        y = ctx.arrowFrame.origin.y;
        [borderPath moveToPoint:CGPointMake(x, y)];
        
        y = cornerRadius;
        [borderPath addLineToPoint:CGPointMake(x, y)];
        
        x = arrowBaseSize.height + cornerRadius;
        [borderPath addArcWithCenter:CGPointMake(x, y) radius:cornerRadius - halfBorderWidth startAngle:M_PI endAngle:-M_PI_2 clockwise:YES];
        
        x = ctx.popViewFrame.size.width - cornerRadius;
//        [borderPath addLineToPoint:CGPointMake(x, y)];
        
        [borderPath addArcWithCenter:CGPointMake(x, y) radius:cornerRadius - halfBorderWidth startAngle:-M_PI_2 endAngle:0 clockwise:YES];
        
        y = ctx.popViewFrame.size.height - cornerRadius;
//        [borderPath addLineToPoint:CGPointMake(x, y)];
        
        [borderPath addArcWithCenter:CGPointMake(x, y) radius:cornerRadius - halfBorderWidth startAngle:0 endAngle:M_PI_2 clockwise:YES];
        
        x = arrowBaseSize.height + cornerRadius;
//        [borderPath addLineToPoint:CGPointMake(x, y)];
        
        [borderPath addArcWithCenter:CGPointMake(x, y) radius:cornerRadius - halfBorderWidth startAngle:M_PI_2 endAngle:M_PI clockwise:YES];
        
        x = arrowBaseSize.height + halfBorderWidth;
        y = ctx.arrowFrame.origin.y + ctx.arrowCtx.baseSize.width;
        [borderPath addLineToPoint:CGPointMake(x, y)];
    }
    else if (ctx.arrowDirection == YZHUIPopViewArrowDirectionDown) {
        x = ctx.arrowFrame.origin.x;
        y = ctx.popViewFrame.size.height - arrowBaseSize.height - halfBorderWidth;
        [borderPath moveToPoint:CGPointMake(x, y)];
        
        x = cornerRadius;
        [borderPath addLineToPoint:CGPointMake(x, y)];
        
        y = ctx.popContentSize.height - cornerRadius;
        [borderPath addArcWithCenter:CGPointMake(x, y) radius:cornerRadius - halfBorderWidth startAngle:M_PI_2 endAngle:M_PI clockwise:YES];
        
//        x = halfBorderWidth;
        y = cornerRadius;
//        [borderPath addLineToPoint:CGPointMake(x, y)];
        
        x = cornerRadius;
        [borderPath addArcWithCenter:CGPointMake(x, y) radius:cornerRadius - halfBorderWidth startAngle:M_PI endAngle:-M_PI_2 clockwise:YES];
        
        x = ctx.popContentSize.width - cornerRadius;
//        y = halfBorderWidth;
//        [borderPath addLineToPoint:CGPointMake(x, y)];
        
        y = cornerRadius;
        [borderPath addArcWithCenter:CGPointMake(x, y) radius:cornerRadius - halfBorderWidth startAngle:-M_PI_2 endAngle:0 clockwise:YES];
        
        y = ctx.popContentSize.height - cornerRadius;
//        [borderPath addLineToPoint:CGPointMake(x, y)];
        
        [borderPath addArcWithCenter:CGPointMake(x, y) radius:cornerRadius - halfBorderWidth startAngle:0 endAngle:M_PI_2 clockwise:YES];
        
        x = CGRectGetMaxX(ctx.arrowFrame);
        y = ctx.popContentSize.height - halfBorderWidth;
        [borderPath addLineToPoint:CGPointMake(x, y)];
    }
    else if (ctx.arrowDirection == YZHUIPopViewArrowDirectionRight) {
        x = ctx.popContentSize.width - halfBorderWidth;
        y = ctx.arrowFrame.origin.y + arrowBaseSize.width;
        [borderPath moveToPoint:CGPointMake(x, y)];
        
        y = ctx.popContentSize.height - cornerRadius;
        [borderPath addLineToPoint:CGPointMake(x, y)];
        
        x = ctx.popContentSize.width - cornerRadius;
        y = ctx.popContentSize.height - cornerRadius;
        [borderPath addArcWithCenter:CGPointMake(x, y) radius:cornerRadius - halfBorderWidth startAngle:0 endAngle:M_PI_2 clockwise:YES];
        
        x = cornerRadius;
//        y = ctx.popContentSize.height - halfBorderWidth;
//        [borderPath addLineToPoint:CGPointMake(x, y)];
        
        y = ctx.popContentSize.height - cornerRadius;
        [borderPath addArcWithCenter:CGPointMake(x, y) radius:cornerRadius - halfBorderWidth startAngle:M_PI_2 endAngle:M_PI clockwise:YES];
        
//        x = cornerRadius;
//        y = cornerRadius;
//        [borderPath addLineToPoint:CGPointMake(x, y)];
        
        y = cornerRadius;
        [borderPath addArcWithCenter:CGPointMake(x, y) radius:cornerRadius - halfBorderWidth startAngle:M_PI endAngle:-M_PI_2 clockwise:YES];
        
        x = ctx.popContentSize.width - cornerRadius;
        [borderPath addArcWithCenter:CGPointMake(x, y) radius:cornerRadius - halfBorderWidth startAngle:-M_PI_2 endAngle:0 clockwise:YES];
        
        x = ctx.popContentSize.width - halfBorderWidth;
        y = ctx.arrowFrame.origin.y;
        [borderPath addLineToPoint:CGPointMake(x, y)];
    }
    return borderPath;
}

-(void)_updatePopContentView:(YZHPopActionContext*)ctx isInner:(BOOL)isInner
{
    if (ctx == nil || ctx.arrowDirection == YZHUIPopViewArrowDirectionAny) {
        return;
    }
    
    CGFloat contentCornerRadius = ctx.contentCornerRadius;
    if (isInner) {
        self.innerContentView.frame = ctx.popViewFrame;
        self.effectView.frame = self.innerContentView.frame;
    }
    else {
        self.frame = ctx.popViewFrame;
        self.effectView.frame = self.bounds;
        self.innerContentView.frame = self.bounds;
        self.innerContentView.backgroundColor = self.innerBackgroundColor;
    }
    
    CGRect contentViewFrame = CGRectZero;
    
    CGSize arrowBaseSize = ctx.arrowCtx.baseSize;
    
    CGAffineTransform arrowT = CGAffineTransformIdentity;
    
    UIBezierPath *borderPath = nil;
    
    UIBezierPath *arrowPath = [ctx.arrowCtx bezierPathForArrowDirection:ctx.arrowDirection];
    
    if (ctx.arrowDirection == YZHUIPopViewArrowDirectionUp) {
        contentViewFrame = CGRectMake(0, arrowBaseSize.height, ctx.popContentSize.width, ctx.popContentSize.height);
        arrowT = CGAffineTransformMakeTranslation(ctx.arrowFrame.origin.x, 0);
        
        if (!isInner) {
            borderPath = [self _getBorderPath:ctx borderWidth:self.borderWidth cornerRadius:contentCornerRadius arrowTransform:arrowT];
        }
    }
    else if (ctx.arrowDirection == YZHUIPopViewArrowDirectionLeft) {
        contentViewFrame = CGRectMake(arrowBaseSize.height, 0, ctx.popContentSize.width, ctx.popContentSize.height);
        arrowT = CGAffineTransformMakeTranslation(0, ctx.arrowFrame.origin.y);
        
        if (!isInner) {
            borderPath = [self _getBorderPath:ctx borderWidth:self.borderWidth cornerRadius:contentCornerRadius arrowTransform:arrowT];
        }
    }
    else if (ctx.arrowDirection == YZHUIPopViewArrowDirectionDown) {
        contentViewFrame = CGRectMake(0, 0, ctx.popContentSize.width, ctx.popContentSize.height);
        arrowT = CGAffineTransformMakeTranslation(ctx.arrowFrame.origin.x, ctx.popContentSize.height);
        
        if (!isInner) {
            borderPath = [self _getBorderPath:ctx borderWidth:self.borderWidth cornerRadius:contentCornerRadius arrowTransform:arrowT];
        }
    }
    else if (ctx.arrowDirection == YZHUIPopViewArrowDirectionRight) {
        contentViewFrame = CGRectMake(0, 0, ctx.popContentSize.width, ctx.popContentSize.height);
        arrowT = CGAffineTransformMakeTranslation(ctx.popContentSize.width, ctx.arrowFrame.origin.y);
        
        if (!isInner) {
            borderPath = [self _getBorderPath:ctx borderWidth:self.borderWidth cornerRadius:contentCornerRadius arrowTransform:arrowT];
        }
    }
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:contentViewFrame cornerRadius:contentCornerRadius];
    [arrowPath applyTransform:arrowT];
    [path appendPath:arrowPath];
    
    CAShapeLayer *mask = [CAShapeLayer layer];
    mask.path = path.CGPath;
    
    if (isInner) {
        self.innerContentView.layer.mask = mask;
        
        CAShapeLayer *effectLayerMask = [CAShapeLayer layer];
        effectLayerMask.path = path.CGPath;
        self.effectView.layer.mask = effectLayerMask;
        
        self.tableView.frame = contentViewFrame;
        self.collectionView.frame = contentViewFrame;
        self.customContentView.frame = contentViewFrame;
    }
    else {
        self.layer.mask = mask;
        
        self.tableView.frame = contentViewFrame;
        self.collectionView.frame = contentViewFrame;
        self.customContentView.frame = contentViewFrame;
        
        if (self.borderWidth <= 0) {
            return;
        }
        
        self.borderLayer.frame = CGRectMake(0, 0,  ctx.popViewFrame.size.width, ctx.popViewFrame.size.height);
        self.borderLayer.path = borderPath.CGPath;
        self.borderLayer.lineWidth = self.borderWidth;
        self.borderLayer.strokeColor = self.borderColor.CGColor;
        self.borderLayer.fillColor = CLEAR_COLOR.CGColor;
        
        YZHPopActionContext *innerCtx = [self _getInnerCtxWithCtx:ctx borderWidth:self.borderWidth];
        [self _updatePopContentView:innerCtx isInner:YES];
    }
}

-(void)_layoutPopContentSubViews
{
    if (self.arrowDirection != YZHUIPopViewArrowDirectionAny) {
        self.arrowDirectionPriorityOrder = @[@(self.arrowDirection)];
        self.arrowDirection = YZHUIPopViewArrowDirectionAny;
    }
    
    [self _setuplayoutValue:self.popContentSize];
    
    YZHPopActionContext *ctx = [self _getPopViewBestArrowDirection:self.arrowDirection popContentSize:self.popContentSize];
    
    self.arrowDirection = ctx.arrowDirection;
    
    ctx.arrowCtx = self.arrowCtx;
    ctx.contentCornerRadius = self.contentCornerRadius;
    [self _updatePopContentView:ctx isInner:NO];
}

-(void)_addToShowInView:(UIView*)showInView
{
    if (showInView == nil) {
        showInView = self.showInView;
        if (showInView == nil) {
            showInView = [UIApplication sharedApplication].keyWindow;
        }
    }
    self.showInView = showInView;
    [showInView addSubview:self];
}

-(void)popViewShow:(BOOL)animated
{
    [self popViewShowInView:self.showInView animated:animated];
}

-(void)popViewShowInView:(UIView*)showInView animated:(BOOL)animated
{
    [self _addToShowInView:showInView];
    [self _layoutPopContentSubViews];
    
    if (animated) {
        self.alpha = 0.1;
        self.transform = CGAffineTransformMakeScale(0.1, 0.1);
        [UIView animateWithDuration:animationTimeInterval_s animations:^{
            self.alpha = 1.0;
            self.transform = CGAffineTransformIdentity;
        }];
    }
}

-(void)popViewFromOverView:(UIView*)overView showInView:(UIView*)showInView animated:(BOOL)animated
{
    if (overView) {
        self.popOverRect = [overView.superview convertRect:overView.frame toView:showInView];
    }
    [self popViewShowInView:showInView animated:animated];
}

-(void)dismiss
{
    [UIView animateWithDuration:animationTimeInterval_s animations:^{
        self.alpha = 0.1;
        self.transform = CGAffineTransformMakeScale(0.1, 0.1);
    } completion:^(BOOL finished) {
        [self.cover removeFromSuperview];
        _cover = nil;
        [self removeFromSuperview];
    }];
}


#pragma mark UITableViewDelegate,UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self.delegate respondsToSelector:@selector(numberOfCellsInPopView:)]) {
        return [self.delegate numberOfCellsInPopView:self];
    }
    return 0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(popView:heightForCellAtIndexPath:)]) {
        return [self.delegate popView:self heightForCellAtIndexPath:indexPath];
    }
    return 40;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    YZHUIPopTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSSTRING_FROM_CLASS(YZHUIPopTableViewCell) forIndexPath:indexPath];
    cell.backgroundColor = CLEAR_COLOR;
    if ([self.delegate respondsToSelector:@selector(popView:cell:cellSubView:forCellAtIndexPath:)]) {
        UIView *subContentView = [self.delegate popView:self cell:cell cellSubView:cell.subContentView forCellAtIndexPath:indexPath];
        [cell addSubContentView:subContentView];
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    YZHUIPopTableViewCell *cell = (YZHUIPopTableViewCell*)[tableView cellForRowAtIndexPath:indexPath];
    if ([self.delegate respondsToSelector:@selector(popView:didSelectedCell:cellSubView:forCellAtIndexPath:)]) {
        [self.delegate popView:self didSelectedCell:cell cellSubView:cell.subContentView forCellAtIndexPath:indexPath];
    }
    [self dismiss];
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self _setTableSeparatorLineWithCell:cell];
    YZHUIPopTableViewCell *popCell = (YZHUIPopTableViewCell*)cell;
    if ([self.delegate respondsToSelector:@selector(popView:willDisplayCell:cellSubView:forCellAtIndexPath:)]) {
        [self.delegate popView:self willDisplayCell:popCell cellSubView:popCell.subContentView forCellAtIndexPath:indexPath];
    }
}

-(void)_setTableSeparatorLineWithCell:(UITableViewCell*)cell
{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

#pragma mark UICollectionViewDelegate, UICollectionViewDataSource
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if ([self.delegate respondsToSelector:@selector(numberOfCellsInPopView:)]) {
        return [self.delegate numberOfCellsInPopView:self];
    }
    return 0;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    YZHUIPopCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSSTRING_FROM_CLASS(YZHUIPopCollectionViewCell) forIndexPath:indexPath];
    cell.backgroundColor = CLEAR_COLOR;
    if ([self.delegate respondsToSelector:@selector(popView:cell:cellSubView:forCellAtIndexPath:)]) {
        UIView *subContentView = [self.delegate popView:self cell:cell cellSubView:cell.subContentView forCellAtIndexPath:indexPath];
        [cell addSubContentView:subContentView];
    }
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    YZHUIPopCollectionViewCell *cell = (YZHUIPopCollectionViewCell*)[collectionView cellForItemAtIndexPath:indexPath];
    if ([self.delegate respondsToSelector:@selector(popView:didSelectedCell:cellSubView:forCellAtIndexPath:)]) {
        [self.delegate popView:self didSelectedCell:cell cellSubView:cell.subContentView forCellAtIndexPath:indexPath];
    }
    [self dismiss];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    YZHUIPopCollectionViewCell *popCell = (YZHUIPopCollectionViewCell*)cell;
    if ([self.delegate respondsToSelector:@selector(popView:willDisplayCell:cellSubView:forCellAtIndexPath:)]) {
        [self.delegate popView:self willDisplayCell:popCell cellSubView:popCell.subContentView forCellAtIndexPath:indexPath];
    }
}

@end
