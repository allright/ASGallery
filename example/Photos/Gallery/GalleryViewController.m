//
//  GalleryViewController.m
//  Photos
//
//  Created by Andrey Syvrachev on 21.05.13.
//  Copyright (c) 2013 Andrey Syvrachev. All rights reserved.
//

#import "GalleryViewController.h"

@interface GalleryViewController ()<ASGalleryViewControllerDelegate>

@end

@implementation GalleryViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self setWantsFullScreenLayout:YES];
}

-(NSUInteger)numberOfAssetsInGalleryController:(ASGalleryViewController *)controller
{
    return [self.assets count];
}

-(id<ASGalleryAsset>)galleryController:(ASGalleryViewController *)controller assetAtIndex:(NSUInteger)index
{
    return self.assets[index];
}

-(void)updateTitle
{
    self.title = [NSString stringWithFormat:NSLocalizedString(@"%u of %u", nil),self.selectedIndex + 1,[self numberOfAssetsInGalleryController:self]];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateTitle];
}

-(void)selectedIndexDidChangedInGalleryController:(ASGalleryViewController*)controller;
{
    [self updateTitle];
}

@end
