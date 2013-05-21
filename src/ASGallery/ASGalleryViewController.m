//
//  ASGalleryController.m
//
//  Created by Andrey Syvrachev on 07.11.12.
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
#define SHOW_HIDE_ANIMATION_TIME 0.3

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

-(NSUInteger)numberOfAssets
{
    assert(0);
    return 0;
}

-(id<ASGalleryAsset>)assetAtIndex:(NSUInteger)index
{
    assert(0);
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
    CGRect bounds = pagingScrollView.bounds;
    CGRect pageFrame = bounds;
    pageFrame.size.width -= (2 * PADDING);
    pageFrame.origin.x = (bounds.size.width * index) + PADDING;
    return pageFrame;
}

- (CGSize)contentSizeForPagingScrollView {
    // We have to use the paging scroll view's bounds to calculate the contentSize, for the same reason outlined above.
    CGRect bounds = pagingScrollView.bounds;
    return CGSizeMake(bounds.size.width * [self.dataSource numberOfAssets], bounds.size.height);
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
    
    //    NSLog(@"pagingScrollViewFrame = %@ frame = %@ bounds = %@ orientation = %u",NSStringFromCGRect(pagingScrollViewFrame),NSStringFromCGRect(pagingScrollView.frame),NSStringFromCGRect(pagingScrollView.bounds),self.interfaceOrientation);
    
    pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
    
    pagingScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    pagingScrollView.delegate = self;
    
    CGRect frameForParentView = [[UIScreen mainScreen] bounds];
    if (!UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
        frameForParentView.size = CGSizeMake(frameForParentView.size.height,frameForParentView.size.width);
    
    self.view = [[UIView alloc] initWithFrame:frameForParentView];
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
    [self tilePagesWithMaxImageType:ASGalleryImageFullScreen];
    
    [self resetTimeout];
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [hideBarsTimer invalidate];
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

-(void)preloadPageWithIndex:(NSInteger)index imageType:(ASGalleryImageType)imageType
{
    assert(index >=0);
    ASGalleryPage *page = [self visiblePageForIndex:index];
    if (!page) {

        page = [self dequeueRecycledPage];
        if (page == nil) {
            page = [[self.galleryPageClass alloc] init];
            page.delegate = self;
        }
        
        page.tag = index;
        page.frame = [self frameForPageAtIndex:index];
        [page prepareForReuse];
        page.asset = [self.dataSource assetAtIndex:index];
        page.imageType = imageType;
        
        [pagingScrollView addSubview:page];
        [_visiblePages addObject:page];
        
        
        //NSLog(@"PAGE: %u ADDED",page.index);
    }else
        page.imageType = imageType;
}

-(void)reloadData
{
    pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
    [self tilePagesWithMaxImageType:ASGalleryImageFullScreen];
}

// maxImageType - needed to prevent loading FullScreen images while scrolling, because this is cause jittering
- (void)tilePagesWithMaxImageType:(ASGalleryImageType)maxImageType
{
    // Calculate which pages are visible
    if (processingRotationNow)
        return;
    
    NSUInteger numberOfAssets = [self.dataSource numberOfAssets];

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
            if ([self.delegate respondsToSelector:@selector(selectedIndexDidChanged)])
                [self.delegate selectedIndexDidChanged];
        }
    }
    //    DLog(@"%u %u",firstVisiblePageIndex,lastVisiblePageIndex);
    
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
            //   NSLog(@"PAGE: %u REMOVED",page.tag);
        }
    }
    [_visiblePages minusSet:recycledPages];
    
 //   TLog(@"tilePages: [%u {%u:%u}  %u]",firstNeededPageIndex,firstVisiblePageIndex,lastVisiblePageIndex,lastNeededPageIndex);
    // add missing pages
    //ASGalleryImageType maxImageType = ASGalleryImagePreview;//ASGalleryImageFullScreen;
    
    for (int index = firstVisiblePageIndex; index <= lastVisiblePageIndex; index++)
        [self preloadPageWithIndex:index imageType:maxImageType];

    for (int step = 1; step <= self.previewImagesToPreload; step++) {
        
        ASGalleryImageType imageType = step > self.fullScreenImagesToPreload ? ASGalleryImagePreview: maxImageType;
        int loIndex = firstVisiblePageIndex - step;
        if (loIndex >= 0)
            [self preloadPageWithIndex:loIndex imageType:imageType];
        
        int hiIndex = lastVisiblePageIndex + step;
        if (hiIndex < numberOfAssets)
            [self preloadPageWithIndex:hiIndex imageType:imageType];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self tilePagesWithMaxImageType:ASGalleryImagePreview];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    //    DLog(@"toInterfaceOrientation = %u duration = %f",toInterfaceOrientation,duration);
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

//-(void)setSelectedIndex:(NSUInteger)selectedIndex
//{
//    ILog(@"selected  = %u",selectedIndex);
//    _selectedIndex = selectedIndex;
//}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    //  DLog(@"BEGIN toInterfaceOrientation = %u duration = %f",toInterfaceOrientation,duration);
    
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
    
    [self tilePagesWithMaxImageType:ASGalleryImageFullScreen];
    //  DLog(@"END selectedIndex = %u",self.selectedIndex);
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
    [self tilePagesWithMaxImageType:ASGalleryImageFullScreen];
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
}

-(void)hideBars
{
    [hideBarsTimer invalidate];
    hideBarsTimer = nil;
    if (!hideControls) {
        hideControls = YES;
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        
        __weak ASGalleryViewController* SELF = self;
        
        if ([SELF.delegate respondsToSelector:@selector(menuBarsWillDisappear)])
            [SELF.delegate menuBarsWillDisappear];
        
        [UIView animateWithDuration:SHOW_HIDE_ANIMATION_TIME animations:^{
            SELF.navigationController.navigationBar.alpha = 0.0;
            if ([SELF.delegate respondsToSelector:@selector(willAnimateMenuBarsDisappearWithDuration:)])
                [SELF.delegate willAnimateMenuBarsDisappearWithDuration:SHOW_HIDE_ANIMATION_TIME];
        }completion:^(BOOL finished) {
            [self.navigationController setNavigationBarHidden:YES animated:NO];
            
            if ([SELF.delegate respondsToSelector:@selector(menuBarsDidDisappear)])
                [SELF.delegate menuBarsDidDisappear];
        }];
        
    }
}

-(void)showBars
{
    if (hideControls) {
        hideControls = NO;
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        [self.navigationController setNavigationBarHidden:NO  animated:NO];
        
        __weak ASGalleryViewController* SELF = self;
        
        if ([SELF.delegate respondsToSelector:@selector(menuBarsWillAppear)])
            [SELF.delegate menuBarsWillAppear];

        [UIView animateWithDuration:SHOW_HIDE_ANIMATION_TIME animations:^{
            SELF.navigationController.navigationBar.alpha = 1.0;
            if ([SELF.delegate respondsToSelector:@selector(willAnimateMenuBarsAppearWithDuration:)])
                [SELF.delegate willAnimateMenuBarsAppearWithDuration:SHOW_HIDE_ANIMATION_TIME];
        }completion:^(BOOL finished) {
            if ([SELF.delegate respondsToSelector:@selector(menuBarsDidAppear)])
                [SELF.delegate menuBarsDidAppear];
        }];
        
  //      [self showPageTitles:YES animated:YES];
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
