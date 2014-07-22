//
//  EmailParsedObject.h
//  EmailParse
//
//  Created by Aaron Burke on 7/14/14.
//  Copyright (c) 2014 Adb. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EmailParsedObject : NSObject

@property (nonatomic, strong) NSString *emailFrom;
@property (nonatomic, strong) NSString *emailTo;
@property (nonatomic, strong) NSString *emailReplyTo;
@property (nonatomic, strong) NSString *emailSubject;
@property (nonatomic, strong) NSString *emailDate;
@property (nonatomic, strong) NSMutableArray *emailMessageArray; // Array of message section dictionaries


@end
