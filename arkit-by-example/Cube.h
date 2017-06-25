//
//  Cube.h
//  arkit-by-example
//
//  Created by md on 6/15/17.
//  Copyright © 2017 ruanestudios. All rights reserved.
//

#import <SceneKit/SceneKit.h>

@interface Cube : SCNNode

- (instancetype)initAtPosition:(SCNVector3)position withMaterial:(SCNMaterial *)material;
- (void)changeMaterial;
- (void)remove;
+ (SCNMaterial *)currentMaterial;

@end
