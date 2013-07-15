//
//  AssetsLibrary.m
//  Photos
//
//  Created by Andrey Syvrachev on 21.05.13.
//  Copyright (c) 2013 Andrey Syvrachev. All rights reserved.
//

#import "ASAssetsLibrary.h"
#import "AssetsLibrary/AssetsLibrary.h"

@interface ASAssetsLibrary (){
    ALAssetsLibrary* library;
}

@end

@implementation ASAssetsLibrary

+(ASAssetsLibrary*)sharedInstance
{
    static ASAssetsLibrary* assetsLibrary = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        assetsLibrary = [[ASAssetsLibrary alloc] init];
    });
    return assetsLibrary;
}

-(id)init
{
    self = [super init];
    if (self){
        library = [[ALAssetsLibrary alloc] init];
        [self performSelectorOnMainThread:@selector(enumAlbums) withObject:nil waitUntilDone:NO];
    }
    return self;
}

-(void)enumAlbums
{
    NSMutableArray* __groups = [NSMutableArray array];
    
    [library enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        
        if (group){
            [__groups addObject:group];
        }else{
            self.groups = __groups;
        }
        
        
    } failureBlock:^(NSError *error) {
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AssetsLibrary access denied"
                                                        message:[error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }];
}

@end
