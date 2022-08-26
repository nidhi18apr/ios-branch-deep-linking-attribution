//
//  NativeComputeDebugViewControllerTableViewController.m
//  Branch
//
//  Created by Usman Shafique on 8/26/22.
//  Copyright © 2022 Branch, Inc. All rights reserved.
//

#import "NativeComputeDebugViewControllerTableViewController.h"
#import "NativeComputeDebugCell.h"
#import "NativeComputeDebugButtonCell.h"

@interface NativeComputeDebugViewControllerTableViewController ()
@property(nonatomic, strong) NSDictionary *schemaMap;
@end

@implementation NativeComputeDebugViewControllerTableViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView setEstimatedRowHeight:150.0];
    [self.tableView setRowHeight:UITableViewAutomaticDimension];
    [self.tableView registerClass:[NativeComputeDebugButtonCell class] forCellReuseIdentifier:@"NativeComputeDebugCell"];
    [self.tableView registerClass:[NativeComputeDebugButtonCell class] forCellReuseIdentifier:@"NativeComputeDebugButtonCell"];
    [self.tableView setDataSource:self];
    [self.tableView setDelegate:self];
    
    //dismiss view when app goes in background
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appMovedToBackground:) name: UIApplicationWillResignActiveNotification object:nil];
    
}

- (void)appMovedToBackground:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (NSDictionary<NSString *, id>*)arrayDict:(NSInteger)section {
    NSArray *sections = [self.schemaMap objectForKey:@"sections"];
    NSDictionary<NSString *, id>* data = sections[section];
    return data;
}

- (NSArray<NSDictionary<NSString *, id>*>*)items:(NSInteger)section {
    NSDictionary<NSString *, id>* arrayDict = [self arrayDict:section];
    NSArray<NSDictionary<NSString *, id>*>* data = [arrayDict objectForKey:@"values"];
    return data;
}

- (NSArray<NSDictionary<NSString *, id>*>*)item:(NSIndexPath *)indexPath {
    return [self items:indexPath.section];
}


- (void)schemaMap:(NSDictionary<NSString *, id>*)schemaMap {
    self.schemaMap = schemaMap;
}

- (void)runWorkflow:(NSIndexPath *)indexPath {
    NSDictionary<NSString *, id>* dict = [self arrayDict:indexPath.section];
    NSArray<NSDictionary<NSString *, id>*>* actions = [dict objectForKey:@"actions"];
    for (NSUInteger i = 0; i < actions.count; i++) {
        
    }
}


//func runWorkflow(indexPath: IndexPath) -> Void {
//    let dict = self.arrayDict(for: indexPath.section)
//    let actions = dict["actions"] as! [[String:Any]]
//    for action in actions {
//        self.bncNative.runWorkflow(input: action)
//    }
//}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSArray<id>* sections = [self.schemaMap objectForKey:@"sections"];
    return sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    NSArray<NSDictionary<NSString *, id>*>* values = [self item:indexPath];
    
    NSMutableString* cellText = [[NSMutableString alloc] initWithString:@""];
    @try {
        NSData* prettyJsonData = [NSJSONSerialization dataWithJSONObject:values options: NSJSONWritingPrettyPrinted error:nil];
        NSMutableString* prettyPrintedJson = [[NSMutableString alloc] initWithData:prettyJsonData encoding:NSUTF8StringEncoding];
        cellText = prettyPrintedJson;
    } @catch (NSException *exception) {
        NSLog(@"Error during deserialization: , %@", exception);
    }
    NSDictionary<NSString *, id>* content = [self arrayDict:indexPath.section];
    if ([content objectForKey:@"actions"]) {
        NativeComputeDebugCell *cell = (NativeComputeDebugCell *) [self.tableView dequeueReusableCellWithIdentifier:@"NativeComputeDebugCell" forIndexPath:indexPath];
        [cell.textView setText:cellText];
        return cell;
    } else {
        NativeComputeDebugButtonCell *cell = (NativeComputeDebugButtonCell *) [self.tableView dequeueReusableCellWithIdentifier:@"NativeComputeDebugButtonCellNativeComputeDebugButtonCell" forIndexPath:indexPath];
        [cell.textView setText:cellText];
        
        
        return cell;
    }
    
//        cell.buttonTapCallback = {
//            print("button clicked")
//            self.runWorkflow(indexPath: indexPath)
//            let alert = UIAlertController(title: "Alert", message: "All config urls processed", preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
//            self.present(alert, animated: true, completion: nil)
//        }
//        return cell
//    }
    
    
    
}



- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSDictionary<NSString *, id>* titleSection = [self arrayDict:section];
    return [[titleSection objectForKey:@"name"] stringValue];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView* headerView = (UITableViewHeaderFooterView *) view;
        headerView.textLabel.backgroundColor = UIColor.clearColor;
        headerView.textLabel.textColor = UIColor.blackColor;
        
    }
}


@end
