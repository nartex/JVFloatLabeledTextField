//
//  JVFloatLabeledTextField.m
//  JVFloatLabeledTextField
//
//  The MIT License (MIT)
//
//  Copyright (c) 2013-2015 Jared Verdi
//  Original Concept by Matt D. Smith
//  http://dribbble.com/shots/1254439--GIF-Mobile-Form-Interaction?list=users
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "JVFloatLabeledTextField.h"
#import "NSString+TextDirectionality.h"

static CGFloat const kFloatingLabelShowAnimationDuration = 0.3f;
static CGFloat const kFloatingLabelHideAnimationDuration = 0.3f;

@interface JVFloatLabeledTextField ()

@property (strong, nonatomic) CALayer *bottomLayer;
@property (strong, nonatomic) CALayer *topLayer;
@property (strong, nonatomic) CALayer *leftLayer;
@property (strong, nonatomic) CALayer *rightLayer;

@end

@implementation JVFloatLabeledTextField
{
    BOOL _isFloatingLabelFontDefault;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _floatingLabel = [UILabel new];
    _floatingLabel.alpha = 0.0f;
    [self addSubview:_floatingLabel];
    
    // some basic default fonts/colors
    _floatingLabelFont = [self defaultFloatingLabelFont];
    _floatingLabel.font = _floatingLabelFont;
    _floatingLabelTextColor = [UIColor grayColor];
    _floatingLabel.textColor = _floatingLabelTextColor;
    _animateEvenIfNotFirstResponder = NO;
    _floatingLabelShowAnimationDuration = kFloatingLabelShowAnimationDuration;
    _floatingLabelHideAnimationDuration = kFloatingLabelHideAnimationDuration;
    [self setFloatingLabelText:self.placeholder];
    
    _adjustsClearButtonRect = YES;
    _isFloatingLabelFontDefault = YES;
    
    self.borderColor = [UIColor colorWithWhite:0.898 alpha:1.000];
    self.borderDirection = BorderDirectionBottom;
    
    
    self.layer.masksToBounds = YES;
}

#pragma mark -

- (UIFont *)defaultFloatingLabelFont
{
    UIFont *textFieldFont = nil;
    
    if (!textFieldFont && self.attributedPlaceholder && self.attributedPlaceholder.length > 0) {
        textFieldFont = [self.attributedPlaceholder attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL];
    }
    if (!textFieldFont && self.attributedText && self.attributedText.length > 0) {
        textFieldFont = [self.attributedText attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL];
    }
    if (!textFieldFont) {
        textFieldFont = self.font;
    }
    
    return [UIFont fontWithName:textFieldFont.fontName size:roundf(textFieldFont.pointSize * 0.7f)];
}

- (void)updateDefaultFloatingLabelFont
{
    UIFont *derivedFont = [self defaultFloatingLabelFont];
    
    if (_isFloatingLabelFontDefault) {
        self.floatingLabelFont = derivedFont;
    }
    else {
        // dont apply to the label, just store for future use where floatingLabelFont may be reset to nil
        _floatingLabelFont = derivedFont;
    }
}

- (UIColor *)labelActiveColor
{
    if (_floatingLabelActiveTextColor) {
        return _floatingLabelActiveTextColor;
    }
    else if ([self respondsToSelector:@selector(tintColor)]) {
        return [self performSelector:@selector(tintColor)];
    }
    return [UIColor blueColor];
}

- (void)setFloatingLabelFont:(UIFont *)floatingLabelFont
{
    if (floatingLabelFont != nil) {
        _floatingLabelFont = floatingLabelFont;
    }
    _floatingLabel.font = _floatingLabelFont ? _floatingLabelFont : [self defaultFloatingLabelFont];
    _isFloatingLabelFontDefault = floatingLabelFont == nil;
    [self setFloatingLabelText:self.placeholder];
    [self invalidateIntrinsicContentSize];
}

- (void)showFloatingLabel:(BOOL)animated
{
    void (^showBlock)() = ^{
        _floatingLabel.alpha = 1.0f;
        _floatingLabel.frame = CGRectMake(_floatingLabel.frame.origin.x,
                                          _floatingLabelYPadding,
                                          _floatingLabel.frame.size.width,
                                          _floatingLabel.frame.size.height);
    };
    
    if (animated || 0 != _animateEvenIfNotFirstResponder) {
        [UIView animateWithDuration:_floatingLabelShowAnimationDuration
                              delay:0.0f
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut
                         animations:showBlock
                         completion:nil];
    }
    else {
        showBlock();
    }
}

- (void)hideFloatingLabel:(BOOL)animated
{
    void (^hideBlock)() = ^{
        _floatingLabel.alpha = 0.0f;
        _floatingLabel.frame = CGRectMake(_floatingLabel.frame.origin.x,
                                          _floatingLabel.font.lineHeight + _placeholderYPadding,
                                          _floatingLabel.frame.size.width,
                                          _floatingLabel.frame.size.height);
        
    };
    
    if (animated || 0 != _animateEvenIfNotFirstResponder) {
        [UIView animateWithDuration:_floatingLabelHideAnimationDuration
                              delay:0.0f
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseIn
                         animations:hideBlock
                         completion:nil];
    }
    else {
        hideBlock();
    }
}

- (void)setLabelOriginForTextAlignment
{
    CGRect textRect = [self textRectForBounds:self.bounds];
    
    CGFloat originX = textRect.origin.x;
    
    if (self.textAlignment == NSTextAlignmentCenter) {
        originX = textRect.origin.x + (textRect.size.width/2) - (_floatingLabel.frame.size.width/2);
    }
    else if (self.textAlignment == NSTextAlignmentRight) {
        originX = textRect.origin.x + textRect.size.width - _floatingLabel.frame.size.width;
    }
    else if (self.textAlignment == NSTextAlignmentNatural) {
        JVTextDirection baseDirection = [_floatingLabel.text getBaseDirection];
        if (baseDirection == JVTextDirectionRightToLeft) {
            originX = textRect.origin.x + textRect.size.width - _floatingLabel.frame.size.width;
        }
    }
    
    _floatingLabel.frame = CGRectMake(originX + _floatingLabelXPadding, _floatingLabel.frame.origin.y,
                                      _floatingLabel.frame.size.width, _floatingLabel.frame.size.height);
}

- (void)setFloatingLabelText:(NSString *)text {
    if (_floatingText) {
        _floatingLabel.text = _floatingText;
    } else {
        _floatingLabel.text = text;
    }
    
    [self setNeedsLayout];
}

#pragma mark - UITextField

- (void)setFont:(UIFont *)font
{
    [super setFont:font];
    [self updateDefaultFloatingLabelFont];
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
    [super setAttributedText:attributedText];
    [self updateDefaultFloatingLabelFont];
}

- (CGSize)intrinsicContentSize
{
    CGSize textFieldIntrinsicContentSize = [super intrinsicContentSize];
    [_floatingLabel sizeToFit];
    return CGSizeMake(textFieldIntrinsicContentSize.width,
                      textFieldIntrinsicContentSize.height + _floatingLabelYPadding + _floatingLabel.bounds.size.height);
}

- (void)setPlaceholder:(NSString *)placeholder
{
    [super setPlaceholder:placeholder];
    if (!_floatingText) {
        [self setFloatingLabelText:placeholder];
    }
}

- (void)setAttributedPlaceholder:(NSAttributedString *)attributedPlaceholder {
    [super setAttributedPlaceholder:attributedPlaceholder];
    if (!_floatingText) {
        [self setFloatingLabelText:attributedPlaceholder.string];
    }
    [self updateDefaultFloatingLabelFont];
}

- (void)setPlaceholder:(NSString *)placeholder floatingTitle:(NSString *)floatingTitle
{
    [super setPlaceholder:placeholder];
    [self setFloatingLabelText:floatingTitle];
}

- (CGRect)textRectForBounds:(CGRect)bounds
{
    CGRect rect = [super textRectForBounds:bounds];
    if ([self.text length] || self.keepBaseline) {
        rect = [self insetRectForBounds:rect];
    }
    CGRect integral = CGRectIntegral(rect);
    return CGRectMake(integral.origin.x + 8, integral.origin.y + 4, integral.size.width - 16, integral.size.height - 8);
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
    CGRect rect = [super editingRectForBounds:bounds];
    if ([self.text length] || self.keepBaseline) {
        rect = [self insetRectForBounds:rect];
    }
    CGRect integral = CGRectIntegral(rect);
    return CGRectMake(integral.origin.x + 8, integral.origin.y + 4, integral.size.width - 16, integral.size.height - 8);
}

- (CGRect)insetRectForBounds:(CGRect)rect {
    CGFloat topInset = ceilf(_floatingLabel.bounds.size.height + _placeholderYPadding);
    topInset = MIN(topInset, [self maxTopInset]);
    return CGRectMake(rect.origin.x, rect.origin.y + topInset / 2.0f, rect.size.width, rect.size.height);
}

- (CGRect)clearButtonRectForBounds:(CGRect)bounds
{
    CGRect rect = [super clearButtonRectForBounds:bounds];
    if (0 != self.adjustsClearButtonRect) {
        if ([self.text length] || self.keepBaseline) {
            CGFloat topInset = ceilf(_floatingLabel.font.lineHeight + _placeholderYPadding);
            topInset = MIN(topInset, [self maxTopInset]);
            rect = CGRectMake(rect.origin.x, rect.origin.y + topInset / 2.0f, rect.size.width, rect.size.height);
        }
    }
    return CGRectIntegral(rect);
}

- (CGFloat)maxTopInset
{
    return MAX(0, floorf(self.bounds.size.height - self.font.lineHeight - 4.0f));
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment
{
    [super setTextAlignment:textAlignment];
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self setLabelOriginForTextAlignment];
    
    CGSize floatingLabelSize = [_floatingLabel sizeThatFits:_floatingLabel.superview.bounds.size];
    
    _floatingLabel.frame = CGRectMake(_floatingLabel.frame.origin.x,
                                      _floatingLabel.frame.origin.y,
                                      floatingLabelSize.width,
                                      floatingLabelSize.height);
    
    BOOL firstResponder = self.isFirstResponder;
    _floatingLabel.textColor = (firstResponder && self.text && self.text.length > 0 ?
                                self.labelActiveColor : self.floatingLabelTextColor);
    if (!self.text || 0 == [self.text length]) {
        [self hideFloatingLabel:firstResponder];
    }
    else {
        [self showFloatingLabel:firstResponder];
    }
    [self setEditingModeTo:self.editing];
}

- (void)setBottomLineColor:(UIColor *)bottomLineColor {
    [self setEditingModeTo:self.editing];
}

- (void)setEditingModeTo:(BOOL)editing {
    if (self.borderDirection & BorderDirectionBottom) {
        if (!_bottomLayer) {
            _bottomLayer = [CALayer layer];
        }
        CGFloat borderWidth = editing ? 2 : 1;
        _bottomLayer.borderColor = editing ? self.tintColor.CGColor : self.borderColor.CGColor;
        _bottomLayer.frame = CGRectMake(0, self.frame.size.height - borderWidth, self.frame.size.width, borderWidth);
        _bottomLayer.borderWidth = borderWidth;
        [_bottomLayer removeFromSuperlayer];
        [self.layer addSublayer:_bottomLayer];
        
    } else {
        [_bottomLayer removeFromSuperlayer];
    }
    
}

- (void)setBorderDirection:(BorderDirection)borderDirection {
    _borderDirection = borderDirection;
    [self setEditingModeTo:self.editing];
    if (!_leftLayer) {
        _leftLayer = [self addBorderLayerWithFrame:CGRectMake(0, 0, 1, self.frame.size.height)];
    }
    
    if (!_rightLayer) {
        _rightLayer = [self addBorderLayerWithFrame:CGRectMake(self.frame.size.width - 1, 0, 1, self.frame.size.height)];
    }
    
    if (!_topLayer) {
        _topLayer = [self addBorderLayerWithFrame:CGRectMake(0, 0, self.frame.size.width, 1)];
    }
    
    _topLayer.hidden = ! (borderDirection & BorderDirectionTop);
    _leftLayer.hidden = ! (borderDirection & BorderDirectionLeft);
    _rightLayer.hidden = ! (borderDirection & BorderDirectionRight);
}

- (void)setBorderColor:(UIColor *)borderColor {
    _borderColor = borderColor;
    _topLayer.borderColor = borderColor.CGColor;
    _leftLayer.borderColor = borderColor.CGColor;
    _rightLayer.borderColor = borderColor.CGColor;
}

- (CALayer *)addBorderLayerWithFrame:(CGRect)frame {
    CALayer *layer = [CALayer layer];
    layer.borderColor = self.borderColor.CGColor;
    layer.frame = frame;
    layer.borderWidth = 1;
    
    [self.layer addSublayer:layer];
    
    return layer;
}

- (BOOL)becomeFirstResponder {
    BOOL ret = [super becomeFirstResponder];
    [self setEditingModeTo:ret];
    return ret;
}

- (BOOL)resignFirstResponder {
    BOOL ret = [super resignFirstResponder];
    [self setEditingModeTo:!ret];
    return ret;
}


@end
