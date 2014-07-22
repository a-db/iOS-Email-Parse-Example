//
//  EmailParseTableVC.m
//  EmailParse
//
//  Created by Aaron Burke on 7/14/14.
//  Copyright (c) 2014 Adb. All rights reserved.
//

#import "EmailParseTableVC.h"
#import "EmailDataParser.h"
#import "EmailParsedObject.h"
#import "EmailDetailVC.h"

@interface EmailParseTableVC ()

@property (strong, nonatomic) EmailParsedObject *emailParsedObject;
@property (strong, nonatomic) NSArray *emailFileList;
@property (strong, nonatomic) NSMutableArray *parsedEmailOjects;


@end

@implementation EmailParseTableVC

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.parsedEmailOjects = [[NSMutableArray alloc] init];
    self.emailFileList = @[@"email-multipart", @"email-singlepart"];
    
    if (self.emailFileList)
    {
        for (NSString *fileName in self.emailFileList)
        {
            NSString *filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"txt"];
            NSData *emailData = [NSData dataWithContentsOfFile:filePath];
            
            if (emailData)
            {
                EmailDataParser *parser = [[EmailDataParser alloc] init];
                self.emailParsedObject = [parser parseEmailData:emailData];
                [self.parsedEmailOjects addObject:self.emailParsedObject];
            }
        }
    }
    
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    return self.parsedEmailOjects.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    
    cell.textLabel.text =[NSString stringWithFormat:@"Email: %@", [self.emailFileList objectAtIndex:indexPath.row] ];
    
    return cell;
}



 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
     if ([segue.identifier isEqualToString:@"emailDetailPush"]) {
         NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
         EmailDetailVC *destViewController = segue.destinationViewController;
         if (destViewController) {
             destViewController.emailParsedObject = [self.parsedEmailOjects objectAtIndex:indexPath.row];
         }
     }
 }





@end
