//
//  EmailDetailVC.m
//  EmailParse
//
//  Created by Aaron Burke on 7/15/14.
//  Copyright (c) 2014 Adb. All rights reserved.
//

#import "EmailDetailVC.h"

@interface EmailDetailVC ()

@property (weak, nonatomic) IBOutlet UILabel *toLabel;
@property (weak, nonatomic) IBOutlet UILabel *fromLabel;
@property (weak, nonatomic) IBOutlet UILabel *subjectLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *showBodyControl;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UITextView *plainTextView;


@end

@implementation EmailDetailVC

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
    if (self.emailParsedObject) {
        [self setLabels];
    }
    
    BOOL plainText = FALSE;
    BOOL html = FALSE;
    
    for (NSMutableDictionary *dict in self.emailParsedObject.emailMessageArray) {
        if ([[dict objectForKey:@"Content-Type"] isEqualToString:@"text/plain"]) {
            self.plainTextView.text = [dict objectForKey:@"messageData"];
            plainText = TRUE;
        }
        if ([[dict objectForKey:@"Content-Type"] isEqualToString:@"text/html"]) {
            [self.webView loadHTMLString:[dict objectForKey:@"messageData"] baseURL:nil];
            html = TRUE;
        }
    }
    
    if (!plainText) {
        [self.showBodyControl setEnabled:NO forSegmentAtIndex:0];
    }
    if (!html) {
        [self.showBodyControl setEnabled:NO forSegmentAtIndex:1];
    }

    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setLabels
{
    if (self.emailParsedObject.emailTo) {
        self.toLabel.text = [NSString stringWithFormat:@"To: %@", self.emailParsedObject.emailTo];
    }
    if (self.emailParsedObject.emailFrom) {
        self.fromLabel.text = [NSString stringWithFormat:@"From: %@", self.emailParsedObject.emailFrom];

    }
    if (self.emailParsedObject.emailSubject) {
        self.subjectLabel.text = [NSString stringWithFormat:@"Subject: %@", self.emailParsedObject.emailSubject];
    }
}
- (IBAction)segmentedAction:(id)sender
{
    switch ([sender selectedSegmentIndex])
    {
        case 0:
            if (!self.webView.isHidden) {
                self.webView.hidden = TRUE;
                self.plainTextView.hidden = FALSE;
            }
            
            for (NSMutableDictionary *dict in self.emailParsedObject.emailMessageArray) {
                if ([[dict objectForKey:@"Content-Type"] isEqualToString:@"text/plain"]) {
                    self.plainTextView.text = [dict objectForKey:@"messageData"];
                }
            }
            
            break;
        case 1:
            if (!self.plainTextView.isHidden) {
                self.plainTextView.hidden = TRUE;
                self.webView.hidden = FALSE;
            }
            for (NSMutableDictionary *dict in self.emailParsedObject.emailMessageArray) {
                if ([[dict objectForKey:@"Content-Type"] isEqualToString:@"text/html"]) {
                   [self.webView loadHTMLString:[dict objectForKey:@"messageData"] baseURL:nil];
                }
            }
            break;
            
        default:
            break;
    }
    
}




@end
