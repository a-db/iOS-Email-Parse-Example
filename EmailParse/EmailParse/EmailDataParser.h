//
//  EmailDataParser.h
//  EmailParse
//
//  Created by Aaron Burke on 7/14/14.
//  Copyright (c) 2014 Adb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EmailParsedObject.h"

@interface EmailDataParser : NSObject

- (EmailParsedObject *)parseEmailData:(NSData*)emailData;

@end
