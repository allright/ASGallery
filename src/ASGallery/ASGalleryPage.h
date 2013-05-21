//
//  ASGalleryPage.h
//  TimeGallery
//
//  Created by Andrey Syvrachev on 07.11.12.
//  Copyright (c) 2012 Andrey Syvrachev. All rights reserved.
//

#import "ASGalleryViewController.h"


@protocol ASGalleryPageDelegate <NSObject>

-(void)playButtonPressed;
-(void)playbackFinished;

@end


@protocol ASGalleryAsset;
@interface ASGalleryPage : UIView

@property(nonatomic,weak) id<ASGalleryPageDelegate> delegate;
@property(nonatomic,strong) id<ASGalleryAsset> asset;
@property(nonatomic,assign) ASGalleryImageType imageType;

@property(nonatomic,strong,readonly) ASImageScrollView* imageView;

-(void)pause;
-(void)prepareForReuse;
-(void)updateFrame:(CGRect)frame;
-(void)resetToDefaults;

-(void)doubleTap:(UITapGestureRecognizer *)gestureRecognizer;


@end
