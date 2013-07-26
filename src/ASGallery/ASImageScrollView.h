//
//  ASImageScrollView.h
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

// ведает загрузкой ассета до FullScreen
@protocol ASImageScrollViewDelegate <NSObject>

-(void)imageViewDidEndZoomingAtScale:(CGFloat)scale;


@end

@interface ASImageScrollView : UIScrollView

@property(nonatomic,unsafe_unretained) id<ASImageScrollViewDelegate> zoomDelegate;
@property (nonatomic,strong) UIImage* image;
@property (nonatomic,assign) BOOL isVideo;
@property (nonatomic,strong,readonly) UIImageView   *imageView;


-(void)prepareForReuse;
-(void)setMaxMinZoomScalesForCurrentBounds;
-(void)restoreCenterPoint:(CGPoint)oldCenter scale:(CGFloat)oldScale;
-(CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center;
-(CGFloat)scaleToRestoreAfterRotation;
-(CGPoint)pointToCenterAfterRotation;
-(void)resetToDefaults;

-(void)restoreDefaultZoomScaleWithCompletionBlock:(dispatch_block_t)block;

@end
