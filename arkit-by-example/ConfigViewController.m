//
//  ConfigViewController.m
//  arkit-by-example
//
//  Created by md on 6/15/17.
//  Copyright © 2017 ruanestudios. All rights reserved.
//

#import "ConfigViewController.h"

@implementation ConfigViewController

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  // Set the initial values
  Config *config = self.config;
  self.featurePoints.on = config.showFeaturePoints;
  self.worldOrigin.on = config.showWorldOrigin;
  self.statistics.on = config.showStatistics;
  self.physicsBodies.on = config.showPhysicsBodies;
}

@end
