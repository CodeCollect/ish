//
//  ArrowBarButton.m
//  iSH
//
//  Created by Theodore Dubois on 9/23/18.
//

#import "ArrowBarButton.h"


@interface ArrowBarButton () <CALayerDelegate> {
    CALayer *arrowLayers[5];
}

@property CGPoint startPoint;
@property (nonatomic) ArrowDirection direction;
@property NSTimer *timer;

@end

@implementation ArrowBarButton

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupLayers];
    }
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self setupLayers];
    }
    return self;
}

static CGPoint anchors[] = {
    {},
    {.5, .95}, // ArrowUp
    {.5, .05}, // ArrowDown
    {1.05, .5}, // ArrowLeft
    {-.05, .5}, // ArrowRight
};

- (void)setupLayers {
    self.layer.delegate = self;
    [self addTextLayer:@"↑" direction:ArrowUp];
    [self addTextLayer:@"↓" direction:ArrowDown];
    [self addTextLayer:@"←" direction:ArrowLeft];
    [self addTextLayer:@"→" direction:ArrowRight];
    [self layoutSublayersOfLayer:self.layer];
    
    self.layer.cornerRadius = 5;
    self.layer.shadowOffset = CGSizeMake(0, 1);
    self.layer.shadowOpacity = 0.4;
    self.layer.shadowRadius = 0;
}

- (void)addTextLayer:(NSString *)text direction:(ArrowDirection)direction {
    CATextLayer *layer = [CATextLayer new];
    layer.contentsScale = UIScreen.mainScreen.scale;
    layer.string = text;
    layer.fontSize = 15;
    UIFont *font = [UIFont systemFontOfSize:layer.fontSize];
    layer.font = (__bridge CFTypeRef _Nullable) font;
    CGSize textSize = [[NSAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName: font}].size;
    layer.bounds = CGRectMake(0, 0, textSize.width, textSize.height);
    layer.foregroundColor = UIColor.blackColor.CGColor;
    
    layer.alignmentMode = kCAAlignmentCenter;
    layer.anchorPoint = anchors[direction];
    [self.layer addSublayer:layer];
    self->arrowLayers[direction] = layer;
}

- (void)layoutSublayersOfLayer:(CALayer *)superlayer {
    NSParameterAssert(superlayer == self.layer);
    for (CALayer *layer in superlayer.sublayers) {
        layer.position = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    }
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    [super beginTrackingWithTouch:touch withEvent:event];
    self.startPoint = [touch locationInView:self];
    self.selected = YES;
    return YES;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    [super continueTrackingWithTouch:touch withEvent:event];
    CGPoint currentPoint = [touch locationInView:self];
    CGPoint diff = CGPointMake(currentPoint.x - self.startPoint.x, currentPoint.y - self.startPoint.y);
    if (hypot(diff.x, diff.y) < 20) {
        self.direction = ArrowNone;
    } else if (fabs(diff.x) > fabs(diff.y)) {
        // more to the side
        if (diff.x > 0)
            self.direction = ArrowRight;
        else
            self.direction = ArrowLeft;
    } else {
        // more up and down
        if (diff.y > 0)
            self.direction = ArrowDown;
        else
            self.direction = ArrowUp;
    }
    return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    [super endTrackingWithTouch:touch withEvent:event];
    self.selected = NO;
    self.direction = ArrowNone;
}
- (void)cancelTrackingWithEvent:(UIEvent *)event {
    [super cancelTrackingWithEvent:event];
    self.selected = NO;
    self.direction = ArrowNone;
}

- (void)chooseBackground {
    if (self.selected || self.highlighted) {
        self.backgroundColor = self.highlightedColor;
    } else {
        self.backgroundColor = self.defaultColor;
    }
}

- (void)animateLayerUpdates {
    [UIView animateWithDuration:0.25 animations:^{
        for (int d = ArrowUp; d <= ArrowRight; d++) {
            CATextLayer *layer = (CATextLayer *) self->arrowLayers[d];
            if (self.direction == ArrowNone || self.direction != d) {
                layer.opacity = self.selected ? 0.25 : 1;
            } else {
                layer.opacity = 1;
            }
        }
    }];
}

- (void)setDirection:(ArrowDirection)direction {
    ArrowDirection oldDirection = _direction;
    _direction = direction;
    if (direction != oldDirection) {
        [self animateLayerUpdates];
        [self.timer invalidate];
        if (direction != ArrowNone) {
            [self sendActionsForControlEvents:UIControlEventValueChanged];
            self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:NO block:^(NSTimer *timer) {
                [self sendActionsForControlEvents:UIControlEventValueChanged];
                self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer *timer) {
                    [self sendActionsForControlEvents:UIControlEventValueChanged];
                }];
            }];
        }
    }
}

- (UIColor *)textColor {
    if (self.keyAppearance == UIKeyboardAppearanceLight)
        return UIColor.blackColor;
    else
        return UIColor.whiteColor;
}

// copy pasted code :dab:
- (UIColor *)defaultColor {
    if (self.keyAppearance == UIKeyboardAppearanceLight)
        return UIColor.whiteColor;
    else
        return [UIColor colorWithRed:1 green:1 blue:1 alpha:77/255.];
}
- (UIColor *)highlightedColor {
    if (self.keyAppearance == UIKeyboardAppearanceLight)
        return [UIColor colorWithRed:172/255. green:180/255. blue:190/255. alpha:1];
    else
        return [UIColor colorWithRed:147/255. green:147/255. blue:147/255. alpha:66/255.];
}

- (void)setColors {
    if (self.selected) {
        self.backgroundColor = self.highlightedColor;
    } else {
        self.backgroundColor = self.defaultColor;
    }
    for (int d = ArrowUp; d <= ArrowRight; d++) {
        CATextLayer *layer = (CATextLayer *) arrowLayers[d];
        if (self.keyAppearance == UIKeyboardAppearanceLight)
            layer.foregroundColor = UIColor.blackColor.CGColor;
        else
            layer.foregroundColor = UIColor.whiteColor.CGColor;
    }
    [self animateLayerUpdates];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    [self setColors];
}

- (void)setKeyAppearance:(UIKeyboardAppearance)keyAppearance {
    _keyAppearance = keyAppearance;
    [self setColors];
}

@end
