//
//  ASGalleryController.m
//
//  Created by Andrey Syvrachev on 07.11.12. andreyalright@gmail.com
//  Copyright (c) 2012 Andrey Syvrachev. All rights reserved.
//
// This code is distributed under the terms and conditions of the MIT license.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "ASGalleryViewController.h"
#import "ASGalleryPage.h"

#define PADDING  20
#define SHOW_HIDE_ANIMATION_TIME 0.35

@interface ShiftContentView : UIView

@property (nonatomic,assign) UIInterfaceOrientation interfaceOrientation;
@property (nonatomic,assign) UIView* shiftView;

@end

@implementation ShiftContentView

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect rect = [UIScreen mainScreen].bounds;
    CGFloat height = UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? rect.size.height : rect.size.width;
    
    CGRect frame = self.shiftView.frame;
    frame.origin.y = self.frame.size.height - height;
    frame.size.height = height;
    self.shiftView.frame = frame;
}

@end

@interface ASGalleryViewController ()<UIScrollViewDelegate,UIGestureRecognizerDelegate,ASGalleryPageDelegate>{
    UIScrollView    *pagingScrollView;
    NSMutableSet    *recycledPages;
    
    NSUInteger      firstVisiblePageIndexBeforeRotation;
    CGFloat         percentScrolledIntoFirstVisiblePage;
    
    NSUInteger  indexForResetZoom;
    BOOL    processingRotationNow;
    BOOL    playBackStarted;
    BOOL    hideControls;
    NSTimer* hideBarsTimer;
    
    UITapGestureRecognizer* gestureSingleTap;
    UITapGestureRecognizer* gestureDoubleTap;
    
    BOOL    callDidChangedFirstly;
    BOOL    viewVisibleNow;
}
@end

@implementation ASGalleryViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        return UIInterfaceOrientationMaskAllButUpsideDown;
    
    return UIInterfaceOrientationMaskAll;
}

-(Class)galleryPageClass
{
    if (_galleryPageClass == nil)
        _galleryPageClass = [ASGalleryPage class];
    return _galleryPageClass;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    if ([self respondsToSelector:@selector(setAutomaticallyAdjustsScrollViewInsets:)])
    {
        [self setAutomaticallyAdjustsScrollViewInsets:NO];
        [self setExtendedLayoutIncludesOpaqueBars:YES];
    }
    
    gestureDoubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    gestureDoubleTap.delegate = self;
    gestureDoubleTap.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:gestureDoubleTap];
    
    
    gestureSingleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
    gestureSingleTap.delegate = self;
    [gestureSingleTap requireGestureRecognizerToFail:gestureDoubleTap];
    [self.view addGestureRecognizer:gestureSingleTap];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isKindOfClass:[UIControl class]] || [touch.view isKindOfClass:[UINavigationBar class]]) {
        // we touched a button, slider, or other UIControl
        return NO; // ignore the touch
    }
    return YES; // handle the touch
}

-(id<ASGalleryViewControllerDataSource>)dataSource
{
    if (_dataSource == nil)
        _dataSource = self;
    return _dataSource;
}

-(id<ASGalleryViewControllerDelegate>)delegate
{
    if (_delegate == nil)
        _delegate = self;
    return _delegate;
}

-(NSUInteger)numberOfAssetsInGalleryController:(ASGalleryViewController *)controller
{
    assert(!"must be overriden");
    return 0;
}

-(id<ASGalleryAsset>)galleryController:(ASGalleryViewController *)controller assetAtIndex:(NSUInteger)index
{
    assert(!"must be overriden");
    return nil;
}

- (CGRect)frameForPagingScrollView {
    CGRect frame = [[UIScreen mainScreen] bounds];
    
    if (!UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
        frame.size = CGSizeMake(frame.size.height,frame.size.width);
    frame.origin.x -= PADDING;
    frame.size.width += (2 * PADDING);
    return frame;
}

- (CGRect)frameForPageAtIndex:(NSUInteger)index {
    // We have to use our paging scroll view's bounds, not frame, to calculate the page placement. When the device is in
    // landscape orientation, the frame will still be in portrait because the pagingScrollView is the root view controller's
    // view, so its frame is in window coordinate space, which is never rotated. Its bounds, however, will be in landscape
    // because it has a rotation transform applied.
    [self.view layoutSubviews];
    CGRect bounds = pagingScrollView.bounds;
    CGRect pageFrame = bounds;
    pageFrame.size.width -= (2 * PADDING);
    pageFrame.origin.x = (bounds.size.width * index) + PADDING;
    return pageFrame;
}

- (CGSize)contentSizeForPagingScrollView {
    // We have to use the paging scroll view's bounds to calculate the contentSize, for the same reason outlined above.
    CGRect bounds = pagingScrollView.bounds;
    return CGSizeMake(bounds.size.width * [self.dataSource numberOfAssetsInGalleryController:self],
                      bounds.size.height);
}

- (void)loadView
{
    // Step 1: make the outer paging scroll view
    CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
    
    pagingScrollView = [[UIScrollView alloc] initWithFrame:pagingScrollViewFrame];
    pagingScrollView.pagingEnabled = YES;
    pagingScrollView.backgroundColor = [UIColor blackColor];
    pagingScrollView.showsVerticalScrollIndicator = NO;
    pagingScrollView.showsHorizontalScrollIndicator = NO;
    pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
    pagingScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    pagingScrollView.delegate = self;
    
    CGRect frameForParentView = [[UIScreen mainScreen] bounds];
    if (!UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
        frameForParentView.size = CGSizeMake(frameForParentView.size.height,frameForParentView.size.width);
    
    ShiftContentView* shiftContentView = [[ShiftContentView alloc] initWithFrame:frameForParentView];
    shiftContentView.shiftView = pagingScrollView;
    shiftContentView.interfaceOrientation = self.interfaceOrientation;
    self.view = shiftContentView;
    self.view.backgroundColor = [UIColor blackColor];
    [self.view addSubview:pagingScrollView];
    
    // Step 2: prepare to tile content
    recycledPages = [[NSMutableSet alloc] init];
    _visiblePages  = [[NSMutableSet alloc] init];
    
    _fullScreenImagesToPreload = 1;
    _previewImagesToPreload = 5;
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    [self.view removeGestureRecognizer:gestureDoubleTap];
    [self.view removeGestureRecognizer:gestureSingleTap];
    
    pagingScrollView = nil;
    recycledPages = nil;
    _visiblePages = nil;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    callDidChangedFirstly = YES;

    CGFloat pageWidth = pagingScrollView.frame.size.width;
    CGFloat newOffset = self.selectedIndex * pageWidth;
    pagingScrollView.contentOffset = CGPointMake(newOffset, 0);
    [self tilePagesWithMaxImageType:ASGalleryImageFullScreen reload:NO];
    
    [self resetTimeout];
    
    viewVisibleNow = YES;
}

-(void)viewWillDisappear:(BOOL)animated
{
    viewVisibleNow = NO;
    [super viewWillDisappear:animated];
    [hideBarsTimer invalidate];
    [self showBars];
}

- (ASGalleryPage *)dequeueRecycledPage
{
    ASGalleryPage *page = [recycledPages anyObject];
    if (page) {
        [recycledPages removeObject:page];
    }
    return page;
}

- (ASGalleryPage*)visiblePageForIndex:(NSUInteger)index
{
    ASGalleryPage* foundPage = nil;
    for (ASGalleryPage *page in _visiblePages) {
        if (page.tag == index) {
            foundPage = page;
            break;
        }
    }
    return foundPage;
}

-(ASGalleryPage*)createGalleryPage
{
    return [[self.galleryPageClass alloc] init];
}

-(void)preloadPageWithIndex:(NSInteger)index imageType:(ASGalleryImageType)imageType reload:(BOOL)reload
{
    assert(index >=0);
    ASGalleryPage *page = [self visiblePageForIndex:index];
    if (!page) {

        page = [self dequeueRecycledPage];
        if (page == nil) {
            page = [self createGalleryPage];
            page.delegate = self;
        }
        
        page.tag = index;
        page.frame = [self frameForPageAtIndex:index];

        [pagingScrollView addSubview:page];
        [_visiblePages addObject:page];

        reload = YES; // initally load page
    }
    
    if (reload) {
        [page prepareForReuse];
        page.asset = [self.dataSource galleryController:self assetAtIndex:index];
    }

    page.imageType = imageType;
}

-(void)reloadData
{
    pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
    [self tilePagesWithMaxImageType:ASGalleryImageFullScreen reload:YES];
}

// maxImageType - needed to prevent loading FullScreen images while scrolling, because this is cause jittering
- (void)tilePagesWithMaxImageType:(ASGalleryImageType)maxImageType reload:(BOOL)reload
{
    // Calculate which pages are visible
    if (processingRotationNow)
        return;
    
    NSUInteger numberOfAssets = [self.dataSource numberOfAssetsInGalleryController:self];

    CGRect visibleBounds = pagingScrollView.bounds;
    
    int firstVisiblePageIndex = floorf(CGRectGetMinX(visibleBounds) / CGRectGetWidth(visibleBounds));
    if (firstVisiblePageIndex < 0)
        firstVisiblePageIndex = 0;
    int lastVisiblePageIndex  = floorf((CGRectGetMaxX(visibleBounds)-1) / CGRectGetWidth(visibleBounds));
    if (lastVisiblePageIndex >= numberOfAssets)
        lastVisiblePageIndex = numberOfAssets - 1;
    
    if (firstVisiblePageIndex == lastVisiblePageIndex)
    {
        if (self.selectedIndex != firstVisiblePageIndex || callDidChangedFirstly){
            self.selectedIndex = firstVisiblePageIndex;
            callDidChangedFirstly = NO;
            if ([self.delegate respondsToSelector:@selector(selectedIndexDidChangedInGalleryController:)])
                [self.delegate selectedIndexDidChangedInGalleryController:self];
        }
    }
    
    int firstNeededPageIndex = firstVisiblePageIndex - (self.previewImagesToPreload+2); //  with +2 gisteresis to prevent REMOVE/ADD on tilePages noice!
    if (firstNeededPageIndex < 0)
        firstNeededPageIndex = 0;
    
    int lastNeededPageIndex  = lastVisiblePageIndex + (self.previewImagesToPreload+2); // with +2 gisteresis to prevent REMOVE/ADD on tilePages noice!
    if (lastNeededPageIndex >= numberOfAssets)
        lastNeededPageIndex = numberOfAssets - 1;
    
    // Recycle no-longer-visible pages
    for (ASGalleryPage *page in _visiblePages) {
        if (page.tag < firstNeededPageIndex || page.tag > lastNeededPageIndex) {
            [recycledPages addObject:page];
            [page removeFromSuperview];
        }
    }
    [_visiblePages minusSet:recycledPages];

    for (int index = firstVisiblePageIndex; index <= lastVisiblePageIndex; index++)
        [self preloadPageWithIndex:index imageType:maxImageType reload:reload];

    for (int step = 1; step <= self.previewImagesToPreload; step++) {
        
        ASGalleryImageType imageType = step > self.fullScreenImagesToPreload ? ASGalleryImagePreview: maxImageType;
        int loIndex = firstVisiblePageIndex - step;
        if (loIndex >= 0)
            [self preloadPageWithIndex:loIndex imageType:imageType reload:reload];
        
        int hiIndex = lastVisiblePageIndex + step;
        if (hiIndex < numberOfAssets)
            [self preloadPageWithIndex:hiIndex imageType:imageType reload:reload];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self tilePagesWithMaxImageType:ASGalleryImagePreview reload:NO];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    ShiftContentView* shiftContentView = (ShiftContentView*)self.view;
    shiftContentView.interfaceOrientation = toInterfaceOrientation;

    processingRotationNow = YES; // oto prevent incorrect scrolling in tilePages!
    
    // here, our pagingScrollView bounds have not yet been updated for the new interface orientation. So this is a good
    // place to calculate the content offset that we will need in the new orientation
    CGFloat offset = pagingScrollView.contentOffset.x;
    CGFloat pageWidth = pagingScrollView.bounds.size.width;
    
    if (offset >= 0) {
        firstVisiblePageIndexBeforeRotation = floorf(offset / pageWidth);
        percentScrolledIntoFirstVisiblePage = (offset - (firstVisiblePageIndexBeforeRotation * pageWidth)) / pageWidth;
    } else {
        firstVisiblePageIndexBeforeRotation = 0;
        percentScrolledIntoFirstVisiblePage = offset / pageWidth;
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // recalculate contentSize based on current orientation
    pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
    
    // adjust frames and configuration of each visible page
    // adjust contentOffset to preserve page location based on values collected prior to location
    CGFloat pageWidth = pagingScrollView.bounds.size.width;
    CGFloat newOffset = (firstVisiblePageIndexBeforeRotation * pageWidth) + (percentScrolledIntoFirstVisiblePage * pageWidth);
    
    pagingScrollView.contentOffset = CGPointMake(newOffset, 0);
    
    for (ASGalleryPage *page in _visiblePages) {
        //        ILog(@"page = %@",page);
        [page updateFrame:[self frameForPageAtIndex:page.tag]];
    }
    
    processingRotationNow = NO;
    
    [self tilePagesWithMaxImageType:ASGalleryImageFullScreen reload:NO];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    indexForResetZoom = self.selectedIndex;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView;      // called when scroll view grinds to a halt
{
    if (indexForResetZoom != self.selectedIndex)
    {
        ASGalleryPage* page = [self visiblePageForIndex:indexForResetZoom];
        [page resetToDefaults];
    }
    [self tilePagesWithMaxImageType:ASGalleryImageFullScreen reload:NO];
}

-(void)doubleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    ASGalleryPage* isv = [self visiblePageForIndex:self.selectedIndex];
    [isv doubleTap:gestureRecognizer];
}

-(ASImageScrollView*)currentImageView
{
    return [self visiblePageForIndex:self.selectedIndex].imageView;
}

-(void)playButtonPressed
{
    pagingScrollView.scrollEnabled = NO;
    playBackStarted = YES;
    [self hideBars];
}

-(void)playbackFinished
{
    pagingScrollView.scrollEnabled = YES;
    playBackStarted = NO;
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];

}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    ASGalleryPage* isv = [self visiblePageForIndex:self.selectedIndex];
    [isv pause];
    
    if (self.doNotHideBarsOnScrollBegin){
        [self resetTimeout];
    }else{
        [self hideBars];
    }
}

-(void)hideBars
{
    [hideBarsTimer invalidate];
    hideBarsTimer = nil;
 
    if (!viewVisibleNow)
        return;
    
    if (!hideControls) {
        hideControls = YES;
        
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        
        __unsafe_unretained ASGalleryViewController* SELF = self;
        
        if ([SELF.delegate respondsToSelector:@selector(menuBarsWillDisappearInGalleryController:)])
            [SELF.delegate menuBarsWillDisappearInGalleryController:self];
        [self.visiblePages makeObjectsPerformSelector:@selector(menuBarsWillDisappear)];
        
        [UIView animateWithDuration:SHOW_HIDE_ANIMATION_TIME animations:^{
            
            SELF.navigationController.navigationBar.alpha = 0.0;
            if ([SELF.delegate respondsToSelector:@selector(galleryController:willAnimateMenuBarsDisappearWithDuration:)])
                [SELF.delegate galleryController:self willAnimateMenuBarsDisappearWithDuration:SHOW_HIDE_ANIMATION_TIME];
            
            [self.visiblePages enumerateObjectsUsingBlock:^(ASGalleryPage* page, BOOL *stop) {
                [page willAnimateMenuBarsDisappearWithDuration:SHOW_HIDE_ANIMATION_TIME];
            }];
            
        }completion:^(BOOL finished) {
            
            [self.navigationController setNavigationBarHidden:YES animated:NO];
            pagingScrollView.frame = [self frameForPagingScrollView];

            if ([SELF.delegate respondsToSelector:@selector(menuBarsDidDisappearInGalleryController:)])
                [SELF.delegate menuBarsDidDisappearInGalleryController:self];
            [self.visiblePages makeObjectsPerformSelector:@selector(menuBarsDidDisappear)];
        }];
        
    }
}

-(void)showBars
{
    if (hideControls) {
        hideControls = NO;

        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        
        [self.navigationController setNavigationBarHidden:NO  animated:NO];
        pagingScrollView.frame = [self frameForPagingScrollView];
        
        __unsafe_unretained ASGalleryViewController* SELF = self;
        
        if ([SELF.delegate respondsToSelector:@selector(menuBarsWillAppearInGalleryController:)])
            [SELF.delegate menuBarsWillAppearInGalleryController:self];
        [self.visiblePages makeObjectsPerformSelector:@selector(menuBarsWillAppear)];

        [UIView animateWithDuration:SHOW_HIDE_ANIMATION_TIME animations:^{
            
            SELF.navigationController.navigationBar.alpha = 1.0;
            if ([SELF.delegate respondsToSelector:@selector(galleryController:willAnimateMenuBarsAppearWithDuration:)])
                [SELF.delegate galleryController:self willAnimateMenuBarsAppearWithDuration:SHOW_HIDE_ANIMATION_TIME];
            
            [self.visiblePages enumerateObjectsUsingBlock:^(ASGalleryPage* page, BOOL *stop) {
                [page willAnimateMenuBarsAppearWithDuration:SHOW_HIDE_ANIMATION_TIME];
            }];
            
        }completion:^(BOOL finished) {
            
            if ([SELF.delegate respondsToSelector:@selector(menuBarsDidAppearInGalleryController:)])
                [SELF.delegate menuBarsDidAppearInGalleryController:self];
            [self.visiblePages makeObjectsPerformSelector:@selector(menuBarsDidAppear)];
        }];
    }
}

-(void)resetTimeout
{
    [hideBarsTimer invalidate];
    hideBarsTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(hideBars) userInfo:nil repeats:NO];
}

-(void)singleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    if (playBackStarted)
        return; // Ignoring, because now PlayBackStarted
    
    if (hideControls)
    {
        [self showBars];
        [self resetTimeout];
    }else {
        [self hideBars];
    }
}

@end
