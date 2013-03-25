//
//  ScrollView.m
//  ScrollViewMaps
//
//  Created by Danilo Braband on 25.03.13.
//  Copyright (c) 2013 dabio. All rights reserved.
//

#import "ScrollView.h"

@implementation ScrollView

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    // Scroll view should not receive events when user does not touch
    // a child uiview.
    for (UIView *view in self.subviews) {
        if (!view.hidden && view.isUserInteractionEnabled && [view pointInside:[self convertPoint:point toView:view] withEvent:event]) {
            return YES;
        }
    }
    return NO;
}

@end
