//
//  Cube.m
//  arkit-by-example
//
//  Created by md on 6/15/17.
//  Copyright © 2017 ruanestudios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Cube.h"
#import "CollisionCategory.h"
#import "PBRMaterial.h"

static int currentMaterialIndex = 0;

@implementation Cube

- (instancetype)initAtPosition:(SCNVector3)position withMaterial:(SCNMaterial *)material {
  self = [super init];
  
  float dimension = 0.2;
  SCNBox *cube = [SCNBox boxWithWidth:dimension height:dimension length:dimension chamferRadius:0];
  cube.materials = @[material];
  SCNNode *node = [SCNNode nodeWithGeometry:cube];
  
  // The physicsBody tells SceneKit this geometry should be manipulated by the physics engine
  node.physicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeDynamic shape:nil];
  node.physicsBody.mass = 2.0;
  node.physicsBody.categoryBitMask = CollisionCategoryCube;
  node.position = position;
  
  [self addChildNode:node];
  return self;
}

- (void)changeMaterial {
  // Static, all future cubes use this to have the same material
  currentMaterialIndex = (currentMaterialIndex + 1) % 4;
  [self.childNodes firstObject].geometry.materials = @[[Cube currentMaterial]];
}

+ (SCNMaterial *)currentMaterial {
  NSString *materialName;
  switch(currentMaterialIndex) {
    case 0:
      materialName = @"rustediron-streaks";
      break;
    case 1:
      materialName = @"carvedlimestoneground";
      break;
    case 2:
      materialName = @"granitesmooth";
      break;
    case 3:
      materialName = @"old-textured-fabric";
      break;
  }
  return [[PBRMaterial materialNamed:materialName] copy];
}

- (void) remove {
  [self removeFromParentNode];
}

@end
