//
//  ConfigViewController.h
//  arkit-by-example
//
//  Created by md on 6/15/17.
//  Copyright © 2017 ruanestudios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Config.h"

@interface ConfigViewController : UITableViewController
@property (weak) IBOutlet UISwitch *featurePoints;
@property (weak) IBOutlet UISwitch *worldOrigin;
@property (weak) IBOutlet UISwitch *physicsBodies;
@property (weak) IBOutlet UISwitch *statistics;
@property (nonatomic, retain) Config *config;
@end
