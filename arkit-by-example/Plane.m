//
//  Plane.m
//  arkit-by-example
//
//  Created by md on 6/9/17.
//  Copyright © 2017 ruanestudios. All rights reserved.
//

#import "Plane.h"
#import "PBRMaterial.h"

static int currentMaterialIndex = 0;

@implementation Plane

- (instancetype)initWithAnchor:(ARPlaneAnchor *)anchor isHidden:(BOOL)hidden withMaterial:(SCNMaterial *)material {
  self = [super init];
  
  self.anchor = anchor;
  float width = anchor.extent.x;
  float length = anchor.extent.z;
  
  // Using a SCNBox and not SCNPlane to make it easy for the geometry we add to the
  // scene to interact with the plane.
  
  // For the physics engine to work properly give the plane some height so we get interactions
  // between the plane and the gometry we add to the scene
  float planeHeight = 0.01;
  
  self.planeGeometry = [SCNBox boxWithWidth:width height:planeHeight length:length chamferRadius:0];
  
  // Since we are using a cube, we only want to render the tron grid
  // on the top face, make the other sides transparent
  SCNMaterial *transparentMaterial = [SCNMaterial new];
  transparentMaterial.diffuse.contents = [UIColor colorWithWhite:1.0 alpha:0.0];
  
  if (hidden) {
    self.planeGeometry.materials = @[transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial];
  } else {
    self.planeGeometry.materials = @[transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, material, transparentMaterial];
  }
  
  SCNNode *planeNode = [SCNNode nodeWithGeometry:self.planeGeometry];
  
  // Since our plane has some height, move it down to be at the actual surface
  planeNode.position = SCNVector3Make(0, -planeHeight / 2, 0);
  
  // Give the plane a physics body so that items we add to the scene interact with it
  planeNode.physicsBody = [SCNPhysicsBody
                           bodyWithType:SCNPhysicsBodyTypeKinematic
                           shape: [SCNPhysicsShape shapeWithGeometry:self.planeGeometry options:nil]];
  
  [self setTextureScale];
  [self addChildNode:planeNode];
  return self;
}

- (void) remove {
  [self removeFromParentNode];
}

- (void)changeMaterial {
  // Static, all future cubes use this to have the same material
  currentMaterialIndex = (currentMaterialIndex + 1) % 5;
  
  SCNMaterial *material = [Plane currentMaterial];
  SCNMaterial *transparentMaterial = [SCNMaterial new];
  transparentMaterial.diffuse.contents = [UIColor colorWithWhite:1.0 alpha:0.0];
  if (material == nil) {
    material = transparentMaterial;
  }
  SCNMatrix4 transform = self.planeGeometry.materials[4].diffuse.contentsTransform;
  material.diffuse.contentsTransform = transform;
  material.roughness.contentsTransform = transform;
  material.metalness.contentsTransform = transform;
  material.normal.contentsTransform = transform;
  self.planeGeometry.materials = @[transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, material, transparentMaterial];
}

+ (SCNMaterial *)currentMaterial {
  NSString *materialName;
  switch(currentMaterialIndex) {
    case 0:
      materialName = @"tron";
      break;
    case 1:
      materialName = @"oakfloor2";
      break;
    case 2:
      materialName = @"sculptedfloorboards";
      break;
    case 3:
      materialName = @"granitesmooth";
      break;
    case 4:
      // planes will be transparent
      return nil;
      break;
  }
  return [[PBRMaterial materialNamed:materialName] copy];
}

- (void)update:(ARPlaneAnchor *)anchor {
  // As the user moves around the extend and location of the plane
  // may be updated. We need to update our 3D geometry to match the
  // new parameters of the plane.
  self.planeGeometry.width = anchor.extent.x;
  self.planeGeometry.length = anchor.extent.z;
  
  // When the plane is first created it's center is 0,0,0 and the nodes
  // transform contains the translation parameters. As the plane is updated
  // the planes translation remains the same but it's center is updated so
  // we need to update the 3D geometry position
  self.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z);
  
  SCNNode *node = [self.childNodes firstObject];
  node.physicsBody = [SCNPhysicsBody
                      bodyWithType:SCNPhysicsBodyTypeKinematic
                      shape: [SCNPhysicsShape shapeWithGeometry:self.planeGeometry options:nil]];
  [self setTextureScale];
}

- (void)setTextureScale {
  CGFloat width = self.planeGeometry.width;
  CGFloat height = self.planeGeometry.length;
  
  // As the width/height of the plane updates, we want our tron grid material to
  // cover the entire plane, repeating the texture over and over. Also if the
  // grid is less than 1 unit, we don't want to squash the texture to fit, so
  // scaling updates the texture co-ordinates to crop the texture in that case
  SCNMaterial *material = self.planeGeometry.materials[4];
  //NSLog(@"width: %f, height: %f", width, height);
  float scaleFactor = 1;
  SCNMatrix4 m = SCNMatrix4MakeScale(width * scaleFactor, height * scaleFactor, 1);
  material.diffuse.contentsTransform = m;
  material.roughness.contentsTransform = m;
  material.metalness.contentsTransform = m;
  material.normal.contentsTransform = m;
}

- (void)hide {
  SCNMaterial *transparentMaterial = [SCNMaterial new];
  transparentMaterial.diffuse.contents = [UIColor colorWithWhite:1.0 alpha:0.0];
  self.planeGeometry.materials = @[transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial];
}

@end
