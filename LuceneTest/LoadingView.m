//
//  LoadingView.m
//  MarinaDeLaRiva
//
//  Created by xiss burg on 1/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LoadingView.h"

@implementation LoadingView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
        
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [self addSubview:activityIndicator];
        activityIndicator.center = CGPointMake(frame.size.width/2, frame.size.height/2);
        activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin;
        [activityIndicator startAnimating];
    }
    return self;
}

- (void)showOnView:(UIView *)view animated:(BOOL)animated
{
    self.frame = CGRectMake(0, 0, view.bounds.size.width, view.bounds.size.height);
    self.alpha = 0;
    [view addSubview:self];
    
    void (^animations)(void) = ^{ 
        self.alpha = 1;
    };
    
    if (animated) {
        [UIView animateWithDuration:0.3 animations:animations];
    }
    else {
        animations();
    }
}

- (void)hideAnimated:(BOOL)animated
{
    void (^animations)(void) = ^{ 
        self.alpha = 0;
    };
    
    void (^completion)(BOOL) = ^(BOOL finished) {
        [self removeFromSuperview];
    };
    
    if (animated) {
        [UIView animateWithDuration:0.3 animations:animations completion:completion];
    }
    else {
        animations();
        completion(YES);
    }
}

@end
