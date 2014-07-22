//
//  EmailDataParser.m
//  EmailParse
//
//  Created by Aaron Burke on 7/14/14.
//  Copyright (c) 2014 Adb. All rights reserved.
//

#import "EmailDataParser.h"
#import "EmailParsedObject.h"

@interface EmailDataParser ()

@property (nonatomic, strong) NSArray *headerSearchArray; // Header data of interest search terms
@property (nonatomic, strong) NSArray *messageSearchArray; // Content format data of interest search terms

@property (nonatomic, strong) EmailParsedObject *emailParsedObject;

@property (nonatomic, strong) NSString *emailHeader; // Holds header info of source email
@property (nonatomic, strong) NSMutableArray *messageSectionsArray; // Array of message sections

@property (nonatomic, strong) NSString *boundaryStr; // Boundary id of multipart email


@end

@implementation EmailDataParser

- (id)init
{
    if (self = [super init])
    {
        // This could be enclosed in a sorting data class
        self.headerSearchArray = @[@"From:", @"To:", @"Reply-To:", @"Subject:"];
        self.messageSearchArray = @[@"Content-Transfer-Encoding:", @"Content-Type:", @"charset=", @"format="];
    }
    return self;
}

- (EmailParsedObject *)parseEmailData:(NSData*)emailData
{
    // Return out if data is nil
    if (emailData == nil)
    {
        return nil;
    }
    
    self.emailParsedObject = [[EmailParsedObject alloc] init];
    self.messageSectionsArray = [[NSMutableArray alloc] init];
    
    NSString *emailStr = [[NSString alloc] initWithData:emailData encoding:NSUTF8StringEncoding];
    
    if (emailStr)
    {
        
        self.boundaryStr = [self findBoundary:emailStr];
        if (self.boundaryStr)
        {
            // Create sections of email
            [self splitMultiPartEmail:emailStr boundary:self.boundaryStr];
        }
        else
        {
            [self splitEmail:emailStr];
        }
        
    }
    // Extract email header data
    if (self.emailHeader)
    {
        [self extractHeaderData:self.emailHeader];
    }
    // Extract email sections with data
    if (self.messageSearchArray)
    {
        self.emailParsedObject.emailMessageArray = [self extractMessageData:self.messageSectionsArray];
    }
    // Decode sections
    // Only created for quoted-printable for this demo
    for (NSDictionary *dict in self.emailParsedObject.emailMessageArray) {
        if ([[dict objectForKey:@"Content-Transfer-Encoding"] isEqualToString:@"quoted-printable"]) {
            [dict setValue:[self quotedPrintableDecode:[dict objectForKey:@"messageData"]]
                    forKey:@"messageData"];
            
        }
    }
    
    return self.emailParsedObject;
}

// Find the boundary string for multipart email
- (NSString*)findBoundary:(NSString*)emailStr
{
    
    NSScanner *theScanner = [NSScanner scannerWithString:emailStr];
    NSCharacterSet *newLine = [NSCharacterSet newlineCharacterSet];
    NSString *boundaryStr;
    NSString *finalStr;
    
    while ([theScanner isAtEnd] == NO)
    {
        
        [theScanner scanUpToString:@"boundary=" intoString:NULL];
        [theScanner setScanLocation: [theScanner scanLocation]];
        [theScanner scanUpToString:@"\"" intoString:NULL];
        [theScanner scanUpToCharactersFromSet:newLine intoString:&boundaryStr];
        
    }
    
    if (boundaryStr)
    {

        NSString *stringWithoutQuotes = [boundaryStr stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        finalStr = [NSString stringWithFormat:@"--%@", stringWithoutQuotes];

    }
    else
    {
        finalStr = nil;
    }
    
    return finalStr;
}

// Split single-part email into header and body
- (void)splitEmail:(NSString*)emailStr
{
    NSScanner *theScanner = [NSScanner scannerWithString:emailStr];
    NSString *headerStr;
    NSString *lastLineInHeader;
    NSString *bodyStr;

    [theScanner scanUpToString:@"\n\r\n" intoString:&headerStr];
    theScanner = [NSScanner scannerWithString:headerStr];
    
    while ([theScanner isAtEnd] == NO)
    {
        [theScanner scanUpToString:@"\n" intoString:&lastLineInHeader];
        
    }

    NSArray *lines=[emailStr componentsSeparatedByString:lastLineInHeader];
    if (lines)
    {
        bodyStr = lines[1];
    }
    
    if (headerStr) {
        self.emailHeader = headerStr;
    }
    
    if (bodyStr) {
        self.messageSectionsArray[0] = bodyStr;
    }

    
}

- (void)splitMultiPartEmail:(NSString*)emailStr boundary:(NSString*)boundaryStr
{
    NSArray *array = [emailStr componentsSeparatedByString:boundaryStr];
    
    if (array)
    {
        self.emailHeader = array[0]; // Header pulled out
        [self.messageSectionsArray addObjectsFromArray:array];
        [self.messageSectionsArray removeObjectAtIndex:0]; // Remove the header data
        if (self.messageSectionsArray.count >= 2) {
            // Remove trailing -- section from multipart
            // Created by last boundary with an added -- at the end
            [self.messageSectionsArray removeObjectAtIndex:self.messageSectionsArray.count-1];
        }
    }
    
    
}

- (void)extractHeaderData:(NSString*)emailHeader
{
    for(NSString *findStr in self.headerSearchArray)
    {
        
        NSScanner *theScanner = [NSScanner scannerWithString:emailHeader];
        NSCharacterSet *newLine = [NSCharacterSet newlineCharacterSet];
        NSString *valueStr;
        
        while ([theScanner isAtEnd] == NO)
        {
            
            [theScanner scanUpToString:findStr intoString:NULL];
            [theScanner setScanLocation: [theScanner scanLocation]];
            [theScanner scanUpToString:@" " intoString:NULL];
            [theScanner scanUpToCharactersFromSet:newLine intoString:&valueStr];
            
        }
        
        // Kind of a dirty implementation but since the data set will never be that large this should be efficient enough
        if (valueStr) {
            if ([findStr isEqualToString:@"From:"])
            {
                self.emailParsedObject.emailFrom = valueStr;
            }
            else if ([findStr isEqualToString:@"To:"])
            {
                self.emailParsedObject.emailTo = valueStr;
            }
            else if ([findStr isEqualToString:@"Reply-To:"])
            {
                self.emailParsedObject.emailReplyTo = valueStr;
            }
            else if ([findStr isEqualToString:@"Subject:"])
            {
                self.emailParsedObject.emailSubject = valueStr;
            }
        }
        
    }
    
}

- (NSMutableArray*)extractMessageData:(NSMutableArray*)messageArray
{
    NSMutableArray *sectionDictArray = [[NSMutableArray alloc] initWithCapacity:messageArray.count];
    for (NSString *section in messageArray)
    {
        // Dictionary to hold section data
        NSMutableDictionary *sectionDictionary = [[NSMutableDictionary alloc] init];
        
        for(NSString *findStr in self.messageSearchArray)
        {
            NSScanner *theScanner;
            
            // Need to use self.emailHeader if not multipart
            if (messageArray.count == 1)
            {
                theScanner = [NSScanner scannerWithString:self.emailHeader];
            }
            else
            {
               theScanner = [NSScanner scannerWithString:section];
            }
            
            [theScanner setCharactersToBeSkipped:nil];
            NSCharacterSet *newLine = [NSCharacterSet newlineCharacterSet];
            NSCharacterSet *customSet = [NSCharacterSet characterSetWithCharactersInString:@";\n"];
            NSString *valueStr;
            
            while ([theScanner isAtEnd] == NO)
            {
                [theScanner scanUpToString:findStr intoString:NULL];
                if ([findStr isEqualToString:@"charset="] || [findStr isEqualToString:@"format="]) {
                    [theScanner scanUpToCharactersFromSet:customSet intoString:&valueStr];
                    break;
                }
                [theScanner scanUpToString:@" " intoString:NULL];
                if ([findStr isEqualToString:@"Content-Type:"])
                {
                   [theScanner scanUpToString:@";" intoString:&valueStr];
                }
                else
                {
                   [theScanner scanUpToCharactersFromSet:newLine intoString:&valueStr];
                }
                
            }
            
            // Kind of a dirty implementation but since the data set will never be that large this should be efficient enough
            if (valueStr) {
                if ([findStr isEqualToString:@"Content-Transfer-Encoding:"])
                {
                    [sectionDictionary setObject:[valueStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
                                          forKey:@"Content-Transfer-Encoding"];
                }
                else if ([findStr isEqualToString:@"Content-Type:"])
                {
                    [sectionDictionary setObject:[valueStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
                                          forKey:@"Content-Type"];
                }
                else if ([findStr isEqualToString:@"charset="])
                {
                    [sectionDictionary setObject:[[valueStr substringFromIndex:8] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]]
                                          forKey:@"charset="];
                }
                else if ([findStr isEqualToString:@"format="])
                {
                    [sectionDictionary setObject:[[valueStr substringFromIndex:7] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]]
                                          forKey:@"format"];
                }
            }
        }
        
        if (messageArray.count > 1)
        {
            NSScanner *theScanner = [NSScanner scannerWithString:section];
            NSString *headerStr;
            NSString *lastContentDataLine;
            
            [theScanner scanUpToString:@"\n\r\n" intoString:&headerStr];
            theScanner = [NSScanner scannerWithString:headerStr];
            
            while ([theScanner isAtEnd] == NO)
            {
                [theScanner scanUpToString:@"\n" intoString:&lastContentDataLine];
                
            }
            
            NSArray *lines=[section componentsSeparatedByString:lastContentDataLine];
            [sectionDictionary setObject:lines[1] forKey:@"messageData"];
        }
        else
        {
            [sectionDictionary setObject:section forKey:@"messageData"];
        }
        [sectionDictArray addObject:sectionDictionary];
        
    }

    return sectionDictArray;
}

- (NSString *)quotedPrintableDecode:(NSString*)sectionStr
{
    NSString *decodedString = [sectionStr stringByReplacingOccurrencesOfString:@"=\r\n" withString:@""]; // Ditch the line wrap indicators
    decodedString = [decodedString stringByReplacingOccurrencesOfString:@"=" withString:@"%"]; // Change the ='s to %'s
    decodedString = [decodedString stringByReplacingOccurrencesOfString:@"=\n" withString:@""];
    decodedString = [decodedString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]; // Replace the escaped strings.
    
    return decodedString;
}

@end
