//
//  DGLabel.m
//  DailyGammon
//
//  Created by Peter Schneider on 07.01.23.
//  Copyright © 2023 Peter Schneider. All rights reserved.
//

#import "DGLabel.h"

@implementation DGLabel

- (id)initWithFrame:(CGRect)frame
{

    self = [super initWithFrame:frame];
    if (self)
    {
        [self customizeLabel];
    }
    return self;
}

- (id)initWithCoder:(NSCoder*)aDecoder
{

    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self customizeLabel];
    }
    return self;
}

- (void)customizeLabel
{
    self.numberOfLines = 1;
    self.adjustsFontSizeToFitWidth = YES;
    self.minimumScaleFactor = 0.1;
    
    self.minimumContentSizeCategory = UIContentSizeCategorySmall;
    self.maximumContentSizeCategory = UIContentSizeCategorySmall;

}

- (void)drawTextInRect:(CGRect)DGLabelRect
{
    float topInset = 0, leftInset = 5, bottomInset = 0, rightInset = 5;
    
    UIEdgeInsets DGLabelInsets = {topInset,leftInset,bottomInset,rightInset};
    [super drawTextInRect:UIEdgeInsetsInsetRect(DGLabelRect, DGLabelInsets)];
}
@end
