//
//  ViewController.m
//  LuceneTest
//
//  Created by xiss burg on 1/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import "OHAttributedLabel.h"
#import "NSAttributedString+Attributes.h"

#define kOHAttributedLabelTag 123456
#define kSearchResultArrayKey @"searchResultArray"
#define kFileNameKey @"fileName"

@implementation ViewController
@synthesize tableView = _tableView;
@synthesize searchBar = _searchBar;
@synthesize searchResultsArray;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.searchResultsArray = [[NSMutableArray alloc] init];
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [self setSearchBar:nil];
    [super viewDidUnload];
}

- (void) viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.searchResultsArray count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSDictionary *fileSearchDictionary = [self.searchResultsArray objectAtIndex:section];
    NSArray *fileSearchArray = [fileSearchDictionary objectForKey:kSearchResultArrayKey];
    return [fileSearchArray count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSDictionary *fileSearchDictionary = [self.searchResultsArray objectAtIndex:section];
    return [fileSearchDictionary objectForKey:kFileNameKey];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    OHAttributedLabel *label = (OHAttributedLabel *)[cell viewWithTag:kOHAttributedLabelTag];
    label.attributedText = [self.searchResultsArray objectAtIndex:indexPath.row];
    return cell;
}

#pragma mark - UITableViewDelegate 

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

@end
