//
//  AssetsLibrary.h
//  Photos
//
//  Created by Andrey Syvrachev on 21.05.13.
//  Copyright (c) 2013 Andrey Syvrachev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ASAssetsLibrary : NSObject

+(ASAssetsLibrary*)sharedInstance;

@property (nonatomic,strong) NSArray* groups;


@end
