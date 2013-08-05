//
//  ASGalleryPage.m
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

#import "ASGalleryPage.h"
#import "ASImageScrollView.h"
#import "ASGalleryViewController.h"
#import <MediaPlayer/MediaPlayer.h>


@interface ASGalleryPage ()<ASGalleryImageView,ASImageScrollViewDelegate>{
    ASImageScrollView* imageScrollView;
    NSOperation* loadImageOp;
    ASGalleryImageType _currentLoadingImageType;
    
    MPMoviePlayerController *moviePlayer;

    UIButton*   playButton;
}

@end

static UIImage* playButtonImage()
{
    static UIImage* image = nil;
    if (image == nil)
        image = [UIImage imageNamed:@"playButton.png"];
    return image;
}

@implementation ASGalleryPage

-(ASImageScrollView*)imageView
{
    return imageScrollView;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        imageScrollView = [[ASImageScrollView alloc] initWithFrame:frame];
        imageScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        imageScrollView.zoomDelegate = self;
        [self addSubview:imageScrollView];
    }
    return self;
}

-(void)loadImageIfNeeded
{
    BOOL downgrade = NO;
    if (_imageType > _currentLoadingImageType){
        _currentLoadingImageType++;
        
            if (![_asset isImageForTypeAvailable:ASGalleryImagePreview] && _currentLoadingImageType == ASGalleryImagePreview){
                
                if (_imageType > _currentLoadingImageType){
                    _currentLoadingImageType++;
                }else
                    return;
            }
    }else if (_imageType < _currentLoadingImageType){
        
        _currentLoadingImageType--;
        downgrade = YES;
    }else
        return;
    
//    DLog(@"%@ _imageType = %u _currentLoadingImageType = %u",self,_imageType,_currentLoadingImageType);
    
    if (_currentLoadingImageType == ASGalleryImagePreview && downgrade)
        return;
    /* Never downgrade from fullscreen to preview or None look at the implementation tilePagesWithMaxImageType,
     if remove this string -> will downgrade to Preview while a little shift photo!  */
    
    if (_currentLoadingImageType == ASGalleryImageNone)
    {
        imageScrollView.image = nil;
        return;
    }
    [loadImageOp cancel];
    loadImageOp = [_asset loadImage:self withImageType:_currentLoadingImageType];
}

-(void)setImage:(UIImage *)image
{
    imageScrollView.image = image;
    [self loadImageIfNeeded];
}

-(void)setImageType:(ASGalleryImageType)imageType
{
    if (_imageType != imageType){
        _imageType = imageType;
        [self loadImageIfNeeded];
    }
}

-(void)imageViewDidEndZoomingAtScale:(CGFloat)scale
{
    if (_imageType != ASGalleryImageFullResolution &&  scale > imageScrollView.minimumZoomScale)
    {
        self.imageType = ASGalleryImageFullResolution;
    }
}

-(void)prepareForReuse
{
    [playButton removeFromSuperview];
    playButton = nil;
    [loadImageOp cancel];
    loadImageOp = nil;
    _imageType = ASGalleryImageNone;
    _currentLoadingImageType = ASGalleryImageNone;
    [imageScrollView prepareForReuse];
}

-(void)updateFrame:(CGRect)frame
{
    CGPoint restorePoint = [imageScrollView pointToCenterAfterRotation];
    CGFloat restoreScale = [imageScrollView scaleToRestoreAfterRotation];
    self.frame = frame;
    [imageScrollView setMaxMinZoomScalesForCurrentBounds];
    [imageScrollView restoreCenterPoint:restorePoint scale:restoreScale];
}

-(void)resetToDefaults
{
    self.imageType = ASGalleryImageFullScreen;
    [imageScrollView resetToDefaults];
}

-(void)dealloc
{
    [loadImageOp cancel];
}

-(UIImage*)image
{
    return imageScrollView.image;
}

-(void)doubleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    BOOL isVideo = _asset.isVideo;
    if (isVideo)
    {
        if (imageScrollView.zoomScale > imageScrollView.minimumZoomScale)
        {
            [imageScrollView setZoomScale:imageScrollView.minimumZoomScale animated:YES];
        }else
            [imageScrollView setZoomScale:imageScrollView.maximumZoomScale animated:YES];
        
        return;
    }
    
    
    CGPoint point = isVideo ? CGPointMake(self.frame.size.width/2,self.frame.size.height/2):[gestureRecognizer locationInView:imageScrollView.imageView];
    
    float newScale;
    if (imageScrollView.zoomScale > imageScrollView.minimumZoomScale)
    {
        self.imageType = ASGalleryImageFullScreen;
        newScale = imageScrollView.minimumZoomScale;
    }else
    {
        self.imageType = ASGalleryImageFullResolution;
        newScale = imageScrollView.maximumZoomScale;
    }
    
    CGRect zoomRect = [imageScrollView zoomRectForScale:newScale withCenter:point];
    //    NSLog(@"point = %@ zoomRect = %@",NSStringFromCGPoint(point),NSStringFromCGRect(zoomRect));
    [imageScrollView zoomToRect:zoomRect animated:YES];
}


/*  video support */
-(void)moviePlayBackDidFinish:(NSDictionary*)userInfo
{
    moviePlayer.scalingMode = imageScrollView.zoomScale > imageScrollView.minimumZoomScale ? MPMovieScalingModeAspectFill : UIViewContentModeScaleAspectFit;
    imageScrollView.zoomScale = moviePlayer.scalingMode == MPMovieScalingModeAspectFit ? imageScrollView.minimumZoomScale:imageScrollView.maximumZoomScale;
    
    [moviePlayer.view removeFromSuperview];
    moviePlayer = nil;
    
    if ([self.delegate respondsToSelector:@selector(playbackFinished)]){
        [self.delegate playbackFinished];
    }
}

-(void)pause
{
    [moviePlayer pause];
}


-(void)play
{
    // hideBars if need
    if ([self.delegate respondsToSelector:@selector(playButtonPressed)]){
        [self.delegate playButtonPressed];
    }

    assert(_asset.isVideo);
    moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:_asset.url];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackDidFinish:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:moviePlayer];
    
    moviePlayer.controlStyle = MPMovieControlStyleFullscreen;
    // moviePlayer.shouldAutoplay = YES;
    
    
    [moviePlayer.view setFrame: self.bounds];
    moviePlayer.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    moviePlayer.scalingMode = imageScrollView.zoomScale > imageScrollView.minimumZoomScale ? MPMovieScalingModeAspectFill : UIViewContentModeScaleAspectFit;
    
    [self addSubview:moviePlayer.view];
    
    [moviePlayer play];
    
}

-(UIButton*)createPlayButton
{
    UIImage* buttonImage = playButtonImage();
    CGSize buttonSize = buttonImage.size;
    CGRect frameToCenter = CGRectMake(floorf((self.bounds.size.width - buttonSize.width) / 2),
                                      floorf((self.bounds.size.height - buttonSize.height) / 2),
                                      buttonSize.width,
                                      buttonSize.height);
    UIButton* button = [[UIButton alloc] initWithFrame:frameToCenter];
    button.autoresizingMask =   UIViewAutoresizingFlexibleLeftMargin    |
    UIViewAutoresizingFlexibleTopMargin     |
    UIViewAutoresizingFlexibleRightMargin   |
    UIViewAutoresizingFlexibleBottomMargin;
    
    [button setImage:buttonImage forState:UIControlStateNormal];
    [button addTarget:self action:@selector(play) forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}


-(void)setAsset:(id<ASGalleryAsset>)asset
{
    _asset = asset;
   
    imageScrollView.isVideo = _asset.isVideo;
    if (_asset.isVideo)
    {
        playButton = [self createPlayButton];
        [self addSubview:playButton];
    }
}

-(void)menuBarsWillAppear
{
}

-(void)willAnimateMenuBarsAppearWithDuration:(CGFloat)duration
{
}

-(void)menuBarsDidAppear
{
}

-(void)menuBarsWillDisappear
{
}

-(void)willAnimateMenuBarsDisappearWithDuration:(CGFloat)duration
{
}

-(void)menuBarsDidDisappear
{
}

@end
