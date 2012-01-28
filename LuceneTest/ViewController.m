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
#import "S4FileUtilities.h"
#import "LoadingView.h"

#define kOHAttributedLabelTag 123456
#define kSearchResultArrayKey @"searchResultArray"
#define kFileNameKey @"fileName"
#define kFieldText @"T"
#define kFieldPath @"P"

@interface ViewController ()

@property (strong, nonatomic) NSMutableDictionary *searchResultsDictionary;
@property (strong, nonatomic) LCIndexSearcher *searcher;
@property (strong, nonatomic) LoadingView *loadingView;

- (void)fillDirectory:(LCFSDirectory *)rd;
- (LCFSDirectory *)createFileDirectory;

@end

@implementation ViewController
@synthesize tableView = _tableView;
@synthesize searchBar = _searchBar;
@synthesize searchResultsDictionary = _searchResultsDictionary;
@synthesize searcher = _searcher;
@synthesize loadingView = _loadingView;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.loadingView = [[LoadingView alloc] initWithFrame:CGRectZero];
    self.searchResultsDictionary = [[NSMutableDictionary alloc] init];
    
    [self.loadingView showOnView:self.view animated:NO];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(queue, ^{
        LCFSDirectory *directory = [self createFileDirectory];
        LCIndexSearcher *searcher = [[LCIndexSearcher alloc] initWithDirectory:directory];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.searcher = searcher;
            [self.loadingView hideAnimated:YES];
        });
    });
}

- (void)viewDidUnload
{
    [self setLoadingView:nil];
    [self setSearchResultsDictionary:nil];
    [self setSearcher:nil];
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
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - Methods

- (void)fillDirectory:(LCFSDirectory *)rd
{
    LCSimpleAnalyzer *analyzer = [[LCSimpleAnalyzer alloc] init];
    LCIndexWriter *writer = [[LCIndexWriter alloc] initWithDirectory:rd analyzer:analyzer create:YES];
    NSArray *paths = [[NSBundle mainBundle] pathsForResourcesOfType:@".txt" inDirectory:nil];
    
    for (NSString *path in paths) {
        NSString *text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        NSArray *lines = [text componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        
        for (int i=0; i<lines.count; ++i) {
            NSString *line = [lines objectAtIndex:i];
            
            if (line.length == 0) {
                continue;
            }
            
            LCDocument *document = [[LCDocument alloc] init];
            LCField *field1 = [[LCField alloc] initWithName:kFieldText string:line store:LCStore_NO index:LCIndex_Tokenized];
            LCField *field2 = [[LCField alloc] initWithName:kFieldPath string:[NSString stringWithFormat:@"%@:%d", path, i] store:LCStore_YES index:LCIndex_NO];
            [document addField:field1];
            [document addField:field2];
            [writer addDocument:document];
        }
    }
    
    [writer close];
}


- (LCFSDirectory *)createFileDirectory
{
    // FIXME should be the application support folder
    NSString *supportPath = [S4FileUtilities documentsDirectory];
    NSString *path = [supportPath stringByAppendingPathComponent:@"index.idx"];

    if ([[NSFileManager defaultManager] isReadableFileAtPath:path])
	{
        return [[LCFSDirectory alloc] initWithPath:path create:NO];
    }
    
    LCFSDirectory *rd = [[LCFSDirectory alloc] initWithPath:path create:YES];
    [self fillDirectory:rd];
    
    return rd;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.searchResultsDictionary allKeys] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *filenameArray = [self.searchResultsDictionary allKeys];
    NSArray *lineArray = [self.searchResultsDictionary objectForKey:[filenameArray objectAtIndex:section]];
    return [lineArray count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSArray *filenameArray = [self.searchResultsDictionary allKeys];
    return [filenameArray objectAtIndex:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    NSArray *filenameArray = [self.searchResultsDictionary allKeys];
    NSArray *lineArray = [self.searchResultsDictionary objectForKey:[filenameArray objectAtIndex:indexPath.section]];
    OHAttributedLabel *label = (OHAttributedLabel *)[cell viewWithTag:kOHAttributedLabelTag];
    label.text = [lineArray objectAtIndex:indexPath.row];
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
    [self.loadingView showOnView:self.tableView animated:YES];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(queue, ^{
        LCTerm *t = [[LCTerm alloc] initWithField:kFieldText text:searchText];
        LCTermQuery *tq = [[LCTermQuery alloc] initWithTerm:t];
        LCHits *hits = [self.searcher search:tq];
        LCHitIterator *iterator = [hits iterator];
        NSMutableDictionary *resultDictionary = [[NSMutableDictionary alloc] init];
        
        while ([iterator hasNext])
        {
            LCHit *hit = [iterator next];
            NSString *path = [hit stringForField:kFieldPath];
            NSString *lastPath = [path lastPathComponent];
            NSLog(@"%@ -> %@", hit, lastPath);
            
            NSArray *components = [lastPath componentsSeparatedByString:@":"];
            NSString *filename = [components objectAtIndex:0];
            NSString *line = [components objectAtIndex:1];
            
            NSMutableArray *lines = [resultDictionary objectForKey:filename];
            
            if (lines != nil) {
                [lines addObject:line];
            }
            else {
                lines = [[NSMutableArray alloc] initWithObjects:line, nil];
                [resultDictionary setObject:lines forKey:filename];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.searchResultsDictionary = resultDictionary;
            [self.tableView reloadData];
            [self.loadingView hideAnimated:YES];
        });
    });
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [UIView animateWithDuration:0.3 animations:^{
        CGRect r = self.tableView.frame;
        r.size.height = 200;
        self.tableView.frame = r;
    }];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{       
    [UIView animateWithDuration:0.3 animations:^{
        CGRect r = self.tableView.frame;
        r.size.height = self.view.frame.size.height - self.searchBar.frame.size.height;
        self.tableView.frame = r;
    }];
}

@end
