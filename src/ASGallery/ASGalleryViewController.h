//
//  ASGalleryController.h
//  TimeGallery
//
//  Created by Andrey Syvrachev on 07.11.12.
//  Copyright (c) 2012 Andrey Syvrachev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ASImageScrollView.h"

typedef enum{
  ASGalleryImageNone = 0,
  ASGalleryImagePreview,
  ASGalleryImageFullScreen,
  ASGalleryImageFullResolution,
}ASGalleryImageType;

typedef void (^ASImageSetBlock)(ASGalleryImageType type, UIImage* image);

@protocol ASGalleryImageView <NSObject>

-(void)setImage:(UIImage*)image;

@end

@protocol ASGalleryAsset <NSObject>

-(BOOL)isVideo;
-(NSOperation*)loadImage:(id<ASGalleryImageView>)galleryImageView withImageType:(ASGalleryImageType)imageType;
-(NSURL*)url;
@end

@protocol ASGalleryViewControllerDataSource <NSObject>

-(NSUInteger)numberOfAssets;
-(id<ASGalleryAsset>)assetAtIndex:(NSUInteger)index;

@end

@protocol ASGalleryViewControllerDelegate <NSObject>

@optional

-(void)selectedIndexDidChanged;

-(void)menuBarsWillAppear;
-(void)willAnimateMenuBarsAppearWithDuration:(CGFloat)duration;
-(void)menuBarsDidAppear;

-(void)menuBarsWillDisappear;
-(void)willAnimateMenuBarsDisappearWithDuration:(CGFloat)duration;
-(void)menuBarsDidDisappear;

@end


@interface ASGalleryViewController : UIViewController<ASGalleryViewControllerDataSource,ASGalleryViewControllerDelegate>

@property(nonatomic,weak) id<ASGalleryViewControllerDataSource> dataSource;
@property(nonatomic,weak) id<ASGalleryViewControllerDelegate> delegate;

@property (nonatomic,strong)     NSMutableSet    *visiblePages;


@property(nonatomic,assign) NSUInteger selectedIndex;

@property(nonatomic,assign) NSUInteger fullScreenImagesToPreload;   // +- 1 by default
@property(nonatomic,assign) NSUInteger previewImagesToPreload;      // +- 5 by default

@property(nonatomic,strong) Class galleryPageClass;  // by default ASGalleryPage (you can have ASGalleryPage as parent class!)

-(void)reloadData;

@property(nonatomic,strong) ASImageScrollView* currentImageView;

@end
