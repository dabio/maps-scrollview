//
//  ViewController.m
//  ScrollViewMaps
//
//  Created by Danilo Braband on 22.03.13.
//  Copyright (c) 2013 dabio. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "ViewController.h"

// the height of the label
#define LABEL_HEIGHT 60
// the visible map area height
#define MAP_HEIGHT 150
// This number defines the absolute velocity limit. Higher
// velocity rates indicate a fast scrolling.
#define VELOCITY_LIMIT 1.0f
// The size must at least be moved before the view gets
// to another view.
#define MIN_OFFSET 30

// See http://stackoverflow.com/questions/2543670/
typedef enum ScrollDirection {
    ScrollDirectionNone,
    ScrollDirectionRight,
    ScrollDirectionLeft,
    ScrollDirectionUp,
    ScrollDirectionDown,
    ScrollDirectionCrazy,
} ScrollDirection;

@interface ViewController () <UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *hoverView;

@property (strong, nonatomic) UIView *touchMapView;

@property (nonatomic) CGFloat lastVerticalVelocity;
@property (nonatomic) ScrollDirection scrollDirection;
@property (nonatomic) NSInteger lastVerticalContentOffset;
@property (nonatomic) NSInteger previousPosition;

@property (nonatomic) NSInteger top;
@property (nonatomic) NSInteger middle;
@property (nonatomic) NSInteger bottom;
@end

@implementation ViewController

- (NSInteger)top
{
    if (!_top) {
        _top = self.scrollView.frame.size.height - LABEL_HEIGHT;
    }
    return _top;
}

- (NSInteger)middle
{
    if (!_middle) {
        _middle = self.scrollView.frame.size.height - LABEL_HEIGHT - MAP_HEIGHT;
    }
    return _middle;
}

- (NSInteger)bottom
{
    if (!_bottom) {
        _bottom = 0;
    }
    return _bottom;
}

- (UIView *)touchMapView
{
    if (!_touchMapView) {
        _touchMapView = [[UIView alloc] init];
        UITapGestureRecognizer *gestureRecognizer =
            [[UITapGestureRecognizer alloc] initWithTarget:self
            action:@selector(tapOnTouchMapView:)];
        //self.touchMapView.backgroundColor = [UIColor orangeColor];
        [self.touchMapView addGestureRecognizer:gestureRecognizer];
    }
    return _touchMapView;
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // Set the size of the scrollview twice the size of the view minus
    // the visible label area (LABEL_HEIGHT).
    self.scrollView.contentSize = CGSizeMake(
        self.view.frame.size.width,
        self.view.frame.size.height * 2 - LABEL_HEIGHT
    );

    // Set the hover views frame to the bottom of the content size of
    // the scrollview.
    self.hoverView.frame = CGRectMake(
        self.view.frame.origin.x,
        self.view.frame.size.height - LABEL_HEIGHT,
        self.view.frame.size.width,
        self.view.frame.size.height
    );
    [self.scrollView addSubview:self.hoverView];

    [self.scrollView addSubview:self.touchMapView];
}

- (void)viewDidLayoutSubviews
{
    // Set the frame for the temporary map touch view. This view is only visible
    // when the scroll is at the middle position. This view is neccessary to
    // allow the scrolling and tapping on the map.
    self.touchMapView.frame = CGRectMake(0, 0, self.view.frame.size.width,
        self.view.frame.size.height - LABEL_HEIGHT);

    // Scroll to the required position in the scroll view.
    CGRect scrollRect = CGRectMake(
        self.scrollView.frame.origin.x,
        self.scrollView.frame.size.height - LABEL_HEIGHT - MAP_HEIGHT,
        self.scrollView.frame.size.width,
        self.scrollView.frame.size.height
    );
    [self.scrollView scrollRectToVisible:scrollRect animated:NO];

    self.previousPosition = self.middle;
}

#pragma mark - Scroll View Delegation

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Don't do anything if the given scroll view is not the
    // main scroll view.
    if (scrollView != self.scrollView) return;

    // Set the current scroll direction.
    self.scrollDirection = ScrollDirectionNone;
    if (self.lastVerticalContentOffset > scrollView.contentOffset.y) {
        self.scrollDirection = ScrollDirectionDown;
    } else if (self.lastVerticalContentOffset < scrollView.contentOffset.y) {
        self.scrollDirection = ScrollDirectionUp;
    }

    self.lastVerticalContentOffset = scrollView.contentOffset.y;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset
{
    // Reserve this behaviour only for the main scroll view.
    if (scrollView != self.scrollView) return;

    // Set the velocity so we can calculate to which position
    // the scroll view should animate.
    self.lastVerticalVelocity = velocity.y;
    
    // The stops the decelerating in scrollViewDidEndDragging:willDecelerate
    *targetContentOffset = scrollView.contentOffset;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate
{
    // Reserve this behaviour only for the main scroll view.
    if (scrollView != self.scrollView) return;

    NSInteger position = scrollView.contentOffset.y;
    CGRect scrollRect = scrollView.frame;

    // default: previous position
    scrollRect.origin.y = self.previousPosition;

    if (position < self.previousPosition - MIN_OFFSET
        || position > self.previousPosition + MIN_OFFSET)
    {
        scrollRect.origin.y = [self getNextPosition:position
                               fromPreviousPosition:self.previousPosition
                                     withFastScroll:(self.lastVerticalVelocity > VELOCITY_LIMIT)
                                 andScrollDirection:self.scrollDirection];
    }

    self.previousPosition = scrollRect.origin.y;
    [scrollView scrollRectToVisible:scrollRect animated:YES];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    // Reserve this behaviour only for the main scroll view.
    if (scrollView != self.scrollView) return;
    
    // Allow user input on map only when fully exposed.
    self.mapView.scrollEnabled = self.mapView.zoomEnabled =
        (scrollView.contentOffset.y == self.bottom);

    // Hide touchMapView when map is fully exposed.
    self.touchMapView.hidden = (scrollView.contentOffset.y == self.bottom);
}

#pragma mark - Gesture Recognizers

- (IBAction)tapOnLabelContainer:(UITapGestureRecognizer *)sender
{
    // Gesture has ended.
    if (sender.state != UIGestureRecognizerStateEnded) return;

    NSInteger position = self.scrollView.contentOffset.y;
    CGRect scrollRect = self.scrollView.frame;

    if (position == self.top) scrollRect.origin.y = self.bottom;
    if (position == self.middle) scrollRect.origin.y = self.bottom;
    if (position == self.bottom) scrollRect.origin.y = self.middle;

    [self.scrollView scrollRectToVisible:scrollRect animated:YES];
}

- (void)tapOnTouchMapView:(UITapGestureRecognizer *)sender
{
    // Gesture has ended.
    if (sender.state != UIGestureRecognizerStateEnded) return;
    
    if (self.scrollView.contentOffset.y == self.middle) {
        CGRect scrollRect = self.scrollView.frame;
        scrollRect.origin.y = self.bottom;
        
        [self.scrollView scrollRectToVisible:scrollRect animated:YES];
    }
}

#pragma mark - Helpers

- (NSInteger)getNextPosition:(NSInteger)position
        fromPreviousPosition:(NSInteger)previousPosition
              withFastScroll:(BOOL)fastScroll
          andScrollDirection:(ScrollDirection)scrollDirection
{
    // Catch case: user goes back to starting position.
    if (position > previousPosition && scrollDirection == ScrollDirectionDown) {
        return fastScroll ? self.bottom : previousPosition;
    }
    if (position < previousPosition && scrollDirection == ScrollDirectionUp) {
        return fastScroll ? self.top : previousPosition;
    }

    if (fastScroll) {
        return (position > previousPosition) ? self.top : self.bottom;
    }
    
    // to top
    if (position > previousPosition) {
        return (position > self.middle) ? self.top : self.middle;
    }
    
    // to bottom
    return (position < self.middle) ? self.bottom : self.middle;
}

@end
