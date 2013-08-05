//
//  ASGalleryController.h
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

#import <UIKit/UIKit.h>
#import "ASImageScrollView.h"

typedef enum{
  ASGalleryImageNone = 0,
  ASGalleryImagePreview,
  ASGalleryImageFullScreen,
  ASGalleryImageFullResolution,
  ASGalleryImageThumbnail
}ASGalleryImageType;

typedef void (^ASImageSetBlock)(ASGalleryImageType type, UIImage* image);

@protocol ASGalleryImageView <NSObject>

-(void)setImage:(UIImage*)image;

@end

@protocol ASGalleryAsset <NSObject>
-(BOOL)isImageForTypeAvailable:(ASGalleryImageType)imageType;
-(BOOL)isVideo;
-(NSOperation*)loadImage:(id<ASGalleryImageView>)galleryImageView withImageType:(ASGalleryImageType)imageType;
-(NSURL*)url;
@end


@class ASGalleryViewController;
@protocol ASGalleryViewControllerDataSource <NSObject>

-(NSUInteger)numberOfAssetsInGalleryController:(ASGalleryViewController*)controller;
-(id<ASGalleryAsset>)galleryController:(ASGalleryViewController*)controller assetAtIndex:(NSUInteger)index;

@end

@protocol ASGalleryViewControllerDelegate <NSObject>

@optional

-(void)selectedIndexDidChangedInGalleryController:(ASGalleryViewController*)controller;

-(void)menuBarsWillAppearInGalleryController:(ASGalleryViewController*)controller;
-(void)galleryController:(ASGalleryViewController*)controller willAnimateMenuBarsAppearWithDuration:(CGFloat)duration;
-(void)menuBarsDidAppearInGalleryController:(ASGalleryViewController*)controller;

-(void)menuBarsWillDisappearInGalleryController:(ASGalleryViewController*)controller;
-(void)galleryController:(ASGalleryViewController*)controller willAnimateMenuBarsDisappearWithDuration:(CGFloat)duration;
-(void)menuBarsDidDisappearInGalleryController:(ASGalleryViewController*)controller;

@end

@class ASGalleryPage;
@interface ASGalleryViewController : UIViewController<ASGalleryViewControllerDataSource,ASGalleryViewControllerDelegate>

@property(nonatomic,unsafe_unretained) id<ASGalleryViewControllerDataSource> dataSource;
@property(nonatomic,unsafe_unretained) id<ASGalleryViewControllerDelegate> delegate;

@property (nonatomic,strong)     NSMutableSet    *visiblePages;


@property(nonatomic,assign) NSUInteger selectedIndex;

@property(nonatomic,assign) NSUInteger fullScreenImagesToPreload;   // +- 1 by default
@property(nonatomic,assign) NSUInteger previewImagesToPreload;      // +- 5 by default

@property(nonatomic,strong) Class galleryPageClass;  // by default ASGalleryPage (you can have ASGalleryPage as parent class!)

@property(nonatomic,strong) ASImageScrollView* currentImageView;

@property (nonatomic,assign) BOOL doNotHideBarsOnScrollBegin;


-(void)reloadData;

- (ASGalleryPage*)visiblePageForIndex:(NSUInteger)index;

// can be ovveride, for create and preinit ASGalleryPage subclass. also you can use galleryPageClass only or together with this method
-(ASGalleryPage*)createGalleryPage;
        
@end
