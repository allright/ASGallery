//
//  AlbumListViewController.m
//  Photos
//
//  Created by Andrey Syvrachev on 21.05.13.
//  Copyright (c) 2013 Andrey Syvrachev. All rights reserved.
//

#import "AlbumListViewController.h"
#import "ASAssetsLibrary.h"
#import "GalleryViewController.h"
#import "ALAssetAdapter.h"

@interface AlbumListViewController ()

@end

@implementation AlbumListViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)dealloc
{
    [[ASAssetsLibrary sharedInstance] removeObserver:self forKeyPath:@"groups"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[ASAssetsLibrary sharedInstance] addObserver:self forKeyPath:@"groups" options:0 context:nil];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[ASAssetsLibrary sharedInstance].groups count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    ALAssetsGroup* group = [ASAssetsLibrary sharedInstance].groups[indexPath.row];
    
    cell.textLabel.text = [group valueForProperty:ALAssetsGroupPropertyName];
    cell.imageView.image = [UIImage imageWithCGImage:[group posterImage]];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"(%u)",[group numberOfAssets]];
    
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
    NSMutableArray* assets = [NSMutableArray array];
    ALAssetsGroup* group = [ASAssetsLibrary sharedInstance].groups[indexPath.row];
    [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {

        if (result){
            ALAssetAdapter* asset = [[ALAssetAdapter alloc] init];
            asset.asset = result;
            
            [assets addObject:asset];
        }else{
            
            GalleryViewController* galleryViewController = [[GalleryViewController alloc] init];
            galleryViewController.assets = assets;
            [self.navigationController pushViewController:galleryViewController animated:YES];
        }
            
    }];
    
    
    

    
}

@end
