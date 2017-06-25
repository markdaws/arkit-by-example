//
//  MessageView.h
//  arkit-by-example
//
//  Created by md on 6/24/17.
//  Copyright © 2017 ruanestudios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MessageView : UIVisualEffectView
- (void)queueMessage: (NSString *)message;
@property (nonatomic, retain) NSString *currentMessage;
@property (nonatomic, retain) NSString *nextMessage;
@property (nonatomic, retain) NSTimer *timer;
@end

