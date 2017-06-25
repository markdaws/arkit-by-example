//
//  ViewController.m
//  arkit-by-example
//
//  Created by md on 6/8/17.
//  Copyright © 2017 ruanestudios. All rights reserved.
//

#import "ViewController.h"
#import <SceneKit/SceneKitTypes.h>
#import "CollisionCategory.h"
#import "PBRMaterial.h"
#import "ConfigViewController.h"

@interface ViewController () <ARSCNViewDelegate, UIGestureRecognizerDelegate, SCNPhysicsContactDelegate>
@property (nonatomic, strong) IBOutlet ARSCNView *sceneView;
@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  // Used to keep track of the current tracking state of the ARSession
  self.currentTrackingState = ARTrackingStateNormal;
  
  [self setupScene];
  [self setupLights];
  [self setupPhysics];
  [self setupRecognizers];
  
  // Create a ARSession confi object we can re-use
  self.arConfig = [ARWorldTrackingSessionConfiguration new];
  self.arConfig.lightEstimationEnabled = YES;
  self.arConfig.planeDetection = ARPlaneDetectionHorizontal;
  
  Config *config = [Config new];
  config.showStatistics = NO;
  config.showWorldOrigin = YES;
  config.showFeaturePoints = YES;
  config.showPhysicsBodies = NO;
  config.detectPlanes = YES;
  self.config = config;
  [self updateConfig];
  
  // Stop the screen from dimming while we are using the app
  [UIApplication.sharedApplication setIdleTimerDisabled:YES];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.navigationController setNavigationBarHidden:YES animated:NO];
  
  // Run the view's session
  [self.sceneView.session runWithConfiguration: self.arConfig options: 0];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
    
  // Pause the view's session
  [self.sceneView.session pause];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Release any cached data, images, etc that aren't in use.
}

- (void)setupScene {
  // Setup the ARSCNViewDelegate - this gives us callbacks to handle new
  // geometry creation
  self.sceneView.delegate = self;
  
  // A dictionary of all the current planes being rendered in the scene
  self.planes = [NSMutableDictionary new];
  
  // A list of all the cubes being rendered in the scene
  self.cubes = [NSMutableArray new];
  
  // Make things look pretty :)
  self.sceneView.antialiasingMode = SCNAntialiasingModeMultisampling4X;
  
  // This is the object that we add all of our geometry to, if you want
  // to render something you need to add it here
  SCNScene *scene = [SCNScene new];
  self.sceneView.scene = scene;
}

- (void)setupPhysics {
  
  // For our physics interactions, we place a large node a couple of meters below the world
  // origin, after an explosion, if the geometry we added has fallen onto this surface which
  // is place way below all of the surfaces we would have detected via ARKit then we consider
  // this geometry to have fallen out of the world and remove it
  SCNBox *bottomPlane = [SCNBox boxWithWidth:1000 height:0.5 length:1000 chamferRadius:0];
  SCNMaterial *bottomMaterial = [SCNMaterial new];
  
  // Make it transparent so you can't see it
  bottomMaterial.diffuse.contents = [UIColor colorWithWhite:1.0 alpha:0.0];
  bottomPlane.materials = @[bottomMaterial];
  SCNNode *bottomNode = [SCNNode nodeWithGeometry:bottomPlane];
  
  // Place it way below the world origin to catch all falling cubes
  bottomNode.position = SCNVector3Make(0, -10, 0);
  bottomNode.physicsBody = [SCNPhysicsBody
                            bodyWithType:SCNPhysicsBodyTypeKinematic
                            shape: nil];
  bottomNode.physicsBody.categoryBitMask = CollisionCategoryBottom;
  bottomNode.physicsBody.contactTestBitMask = CollisionCategoryCube;
  
  SCNScene *scene = self.sceneView.scene;
  [scene.rootNode addChildNode:bottomNode];
  scene.physicsWorld.contactDelegate = self;
}

- (void)setupLights {
  // Turn off all the default lights SceneKit adds since we are handling it ourselves
  self.sceneView.autoenablesDefaultLighting = NO;
  self.sceneView.automaticallyUpdatesLighting = NO;
  
  UIImage *env = [UIImage imageNamed: @"./Assets.scnassets/Environment/spherical.jpg"];
  self.sceneView.scene.lightingEnvironment.contents = env;
  
  //TODO: wantsHdr
}

- (void)setupRecognizers {
  // Single tap will insert a new piece of geometry into the scene
  UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(insertCubeFrom:)];
  tapGestureRecognizer.numberOfTapsRequired = 1;
  [self.sceneView addGestureRecognizer:tapGestureRecognizer];
  
  // Press and hold will open a config menu for the selected geometry
  UILongPressGestureRecognizer *materialGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(geometryConfigFrom:)];
  materialGestureRecognizer.minimumPressDuration = 0.5;
  [self.sceneView addGestureRecognizer:materialGestureRecognizer];
  
  // Press and hold with two fingers causes an explosion
  UILongPressGestureRecognizer *explodeGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(explodeFrom:)];
  explodeGestureRecognizer.minimumPressDuration = 1;
  explodeGestureRecognizer.numberOfTouchesRequired = 2;
  [self.sceneView addGestureRecognizer:explodeGestureRecognizer];
}

- (void)insertCubeFrom: (UITapGestureRecognizer *)recognizer {
  // Take the screen space tap coordinates and pass them to the hitTest method on the ARSCNView instance
  CGPoint tapPoint = [recognizer locationInView:self.sceneView];
  NSArray<ARHitTestResult *> *result = [self.sceneView hitTest:tapPoint types:ARHitTestResultTypeExistingPlaneUsingExtent];
  
  // If the intersection ray passes through any plane geometry they will be returned, with the planes
  // ordered by distance from the camera
  if (result.count == 0) {
    return;
  }
  
  // If there are multiple hits, just pick the closest plane
  ARHitTestResult * hitResult = [result firstObject];
  [self insertCube:hitResult];
}

- (void)explodeFrom: (UILongPressGestureRecognizer *)recognizer {
  if (recognizer.state != UIGestureRecognizerStateBegan) {
    return;
  }
  
  // Perform a hit test using the screen coordinates to see if the user pressed on
  // a plane.
  CGPoint holdPoint = [recognizer locationInView:self.sceneView];
  NSArray<ARHitTestResult *> *result = [self.sceneView hitTest:holdPoint types:ARHitTestResultTypeExistingPlaneUsingExtent];
  if (result.count == 0) {
    return;
  }
  
  ARHitTestResult * hitResult = [result firstObject];
  [self explode:hitResult];
}

- (void)geometryConfigFrom: (UILongPressGestureRecognizer *)recognizer {
  if (recognizer.state != UIGestureRecognizerStateBegan) {
    return;
  }
  
  // Perform a hit test using the screen coordinates to see if the user pressed on
  // any 3D geometry in the scene, if so we will open a config menu for that
  // geometry to customize the appearance
  
  CGPoint holdPoint = [recognizer locationInView:self.sceneView];
  NSArray<SCNHitTestResult *> *result = [self.sceneView hitTest:holdPoint
                                                        options:@{SCNHitTestBoundingBoxOnlyKey: @YES, SCNHitTestFirstFoundOnlyKey: @YES}];
  if (result.count == 0) {
    return;
  }
  
  SCNHitTestResult * hitResult = [result firstObject];
  SCNNode *node = hitResult.node;
  
  // We add all the geometry as children of the Plane/Cube SCNNode object, so we can
  // get the parent and see what type of geometry this is
  SCNNode *parentNode = node.parentNode;
  if ([parentNode isKindOfClass:[Cube class]]) {
    [((Cube *)parentNode) changeMaterial];
  } else {
    [((Plane *)parentNode) changeMaterial];
  }
}

- (void)hidePlanes {
  for(NSUUID *planeId in self.planes) {
    [self.planes[planeId] hide];
  }
}

- (void)disableTracking:(BOOL)disabled {
  // Stop detecting new planes or updating existing ones.
  
  if (disabled) {
    self.arConfig.planeDetection = ARPlaneDetectionNone;
  } else {
    self.arConfig.planeDetection = ARPlaneDetectionHorizontal;
  }
  
  [self.sceneView.session runWithConfiguration:self.arConfig];
}

- (void)explode:(ARHitTestResult *)hitResult {
  // For an explosion, we take the world position of the explosion and the position of each piece of geometry
  // in the world. We then take the distance between those two points, the closer to the explosion point the
  // geometry is the stronger the force of the explosion.
  
  // The hitResult will be a point on the plane, we move the explosion down a little bit below the
  // plane so that the goemetry fly upwards off the plane
  float explosionYOffset = 0.1;
  
  SCNVector3 position = SCNVector3Make(
                                       hitResult.worldTransform.columns[3].x,
                                       hitResult.worldTransform.columns[3].y - explosionYOffset,
                                       hitResult.worldTransform.columns[3].z
                                       );
  
  // We need to find all of the geometry affected by the explosion, ideally we would have some
  // spatial data structure like an octree to efficiently find all geometry close to the explosion
  // but since we don't have many items, we can just loop through all of the current geoemtry
  for(SCNNode *cubeNode in self.cubes) {
    // The distance between the explosion and the geometry
    SCNVector3 distance = SCNVector3Make(
                                          cubeNode.worldPosition.x - position.x,
                                          cubeNode.worldPosition.y - position.y,
                                          cubeNode.worldPosition.z - position.z
                                          );
    
    float len = sqrtf(distance.x * distance.x + distance.y * distance.y + distance.z * distance.z);
    
    // Set the maximum distance that the explosion will be felt, anything further than 2 meters from
    // the explosion will not be affected by any forces
    float maxDistance = 2;
    float scale = MAX(0, (maxDistance - len));
    
    // Scale the force of the explosion
    scale = scale * scale * 5;
    
    // Scale the distance vector to the appropriate scale
    distance.x = distance.x / len * scale;
    distance.y = distance.y / len * scale;
    distance.z = distance.z / len * scale;
    
    // Apply a force to the geometry. We apply the force at one of the corners of the cube
    // to make it spin more, vs just at the center
    [[cubeNode.childNodes firstObject].physicsBody applyForce:distance atPosition:SCNVector3Make(0.05, 0.05, 0.05) impulse:YES];
  }
}

- (void)insertCube:(ARHitTestResult *)hitResult {
  // We insert the geometry slightly above the point the user tapped, so that it drops onto the plane
  // using the physics engine
  float insertionYOffset = 0.5;
  SCNVector3 position = SCNVector3Make(
                                       hitResult.worldTransform.columns[3].x,
                                       hitResult.worldTransform.columns[3].y + insertionYOffset,
                                       hitResult.worldTransform.columns[3].z
                                       );
  
  Cube *cube = [[Cube alloc] initAtPosition:position withMaterial:[Cube currentMaterial]];
  [self.cubes addObject:cube];
  [self.sceneView.scene.rootNode addChildNode:cube];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  // Called just before we transition to the config screen
  ConfigViewController *configController = (ConfigViewController *)segue.destinationViewController;
  
  // NOTE: I am using a popover so that we do't get the viewWillAppear method called when
  // we close the popover, if that gets called (like if you did a modal settings page), then
  // the session configuration is updated and we lose tracking. By default it shouldn't but
  // it still seems to.
  configController.modalPresentationStyle = UIModalPresentationPopover;
  configController.popoverPresentationController.delegate = self;
  configController.config = self.config;
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
  return UIModalPresentationNone;
}

- (IBAction)settingsUnwind:(UIStoryboardSegue *)segue {
  // Called after we navigate back from the config screen
  
  ConfigViewController *configView = (ConfigViewController *)segue.sourceViewController;
  Config *config = self.config;
  
  config.showPhysicsBodies = configView.physicsBodies.on;
  config.showFeaturePoints = configView.featurePoints.on;
  config.showWorldOrigin = configView.worldOrigin.on;
  config.showStatistics = configView.statistics.on;
  [self updateConfig];
}

- (IBAction)detectPlanesChanged:(id)sender {
  BOOL enabled = ((UISwitch *)sender).on;
  
  if (enabled == self.config.detectPlanes) {
    return;
  }
  
  self.config.detectPlanes = enabled;
  if (enabled) {
    [self disableTracking: NO];
  } else {
    [self disableTracking: YES];
  }
}

- (void)updateConfig {
  SCNDebugOptions opts = SCNDebugOptionNone;
  Config *config = self.config;
  if (config.showWorldOrigin) {
    opts |= ARSCNDebugOptionShowWorldOrigin;
  }
  if (config.showFeaturePoints) {
    opts = ARSCNDebugOptionShowFeaturePoints;
  }
  if (config.showPhysicsBodies) {
    opts |= SCNDebugOptionShowPhysicsShapes;
  }
  self.sceneView.debugOptions = opts;
  if (config.showStatistics) {
    self.sceneView.showsStatistics = YES;
  } else {
    self.sceneView.showsStatistics = NO;
  }
}

- (void)refresh {
  for (NSUUID *planeId in self.planes) {
    [self.planes[planeId] remove];
  }
  for (Cube *cube in self.cubes) {
    [cube remove];
  }
  [self.sceneView.session runWithConfiguration:self.arConfig options:ARSessionRunOptionResetTracking | ARSessionRunOptionRemoveExistingAnchors];
}

#pragma mark - SCNPhysicsContactDelegate

- (void)physicsWorld:(SCNPhysicsWorld *)world didBeginContact:(SCNPhysicsContact *)contact {
  // Here we detect a collision between pieces of geometry in the world, if one of the pieces
  // of geometry is the bottom plane it means the geometry has fallen out of the world. just remove it
  CollisionCategory contactMask = contact.nodeA.physicsBody.categoryBitMask | contact.nodeB.physicsBody.categoryBitMask;
  
  if (contactMask == (CollisionCategoryBottom | CollisionCategoryCube)) {
    if (contact.nodeA.physicsBody.categoryBitMask == CollisionCategoryBottom) {
      [contact.nodeB removeFromParentNode];
    } else {
      [contact.nodeA removeFromParentNode];
    }
  }
}

#pragma mark - ARSCNViewDelegate

- (void)renderer:(id <SCNSceneRenderer>)renderer updateAtTime:(NSTimeInterval)time {
  ARLightEstimate *estimate = self.sceneView.session.currentFrame.lightEstimate;
  if (!estimate) {
    return;
  }
  
  // A value of 1000 is considered neutral, lighting environment intensity normalizes
  // 1.0 to neutral so we need to scale the ambientIntensity value
  CGFloat intensity = estimate.ambientIntensity / 1000.0;
  self.sceneView.scene.lightingEnvironment.intensity = intensity;
}

/**
 Called when a new node has been mapped to the given anchor.
 
 @param renderer The renderer that will render the scene.
 @param node The node that maps to the anchor.
 @param anchor The added anchor.
 */
- (void)renderer:(id <SCNSceneRenderer>)renderer didAddNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor {
  if (![anchor isKindOfClass:[ARPlaneAnchor class]]) {
    return;
  }
  
  // When a new plane is detected we create a new SceneKit plane to visualize it in 3D
  Plane *plane = [[Plane alloc] initWithAnchor: (ARPlaneAnchor *)anchor isHidden: NO withMaterial:[Plane currentMaterial]];
  [self.planes setObject:plane forKey:anchor.identifier];
  [node addChildNode:plane];
}

/**
 Called when a node has been updated with data from the given anchor.
 
 @param renderer The renderer that will render the scene.
 @param node The node that was updated.
 @param anchor The anchor that was updated.
 */
- (void)renderer:(id <SCNSceneRenderer>)renderer didUpdateNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor {
  Plane *plane = [self.planes objectForKey:anchor.identifier];
  if (plane == nil) {
    return;
  }
  
  // When an anchor is updated we need to also update our 3D geometry too. For example
  // the width and height of the plane detection may have changed so we need to update
  // our SceneKit geometry to match that
  [plane update:(ARPlaneAnchor *)anchor];
}

/**
 Called when a mapped node has been removed from the scene graph for the given anchor.
 
 @param renderer The renderer that will render the scene.
 @param node The node that was removed.
 @param anchor The anchor that was removed.
 */
- (void)renderer:(id <SCNSceneRenderer>)renderer didRemoveNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor {
  // Nodes will be removed if planes multiple individual planes that are detected to all be
  // part of a larger plane are merged.
  [self.planes removeObjectForKey:anchor.identifier];
}

/**
 Called when a node will be updated with data from the given anchor.
 
 @param renderer The renderer that will render the scene.
 @param node The node that will be updated.
 @param anchor The anchor that was updated.
 */
- (void)renderer:(id <SCNSceneRenderer>)renderer willUpdateNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor {
}

/**
 Implement this to provide a custom node for the given anchor.
 
 @discussion This node will automatically be added to the scene graph.
 If this method is not implemented, a node will be automatically created.
 If nil is returned the anchor will be ignored.
 @param renderer The renderer that will render the scene.
 @param anchor The added anchor.
 @return Node that will be mapped to the anchor or nil.
 */
//- (nullable SCNNode *)renderer:(id <SCNSceneRenderer>)renderer nodeForAnchor:(ARAnchor *)anchor {
//  return nil;
//}

- (void)showMessage:(NSString *)message {
  [self.messageViewer queueMessage:message];
}

- (void)session:(ARSession *)session cameraDidChangeTrackingState:(ARCamera *)camera {
  ARTrackingState trackingState = camera.trackingState;
  if (self.currentTrackingState == trackingState) {
    return;
  }
  self.currentTrackingState = trackingState;
  
  switch(trackingState) {
    case ARTrackingStateNotAvailable:
      [self showMessage:@"Camera tracking is not available on this device"];
      break;
      
    case ARTrackingStateLimited:
      switch(camera.trackingStateReason) {
        case ARTrackingStateReasonExcessiveMotion:
          [self showMessage:@"Limited tracking: slow down the movement of the device"];
          break;
          
        case ARTrackingStateReasonInsufficientFeatures:
          [self showMessage:@"Limited tracking: too few feature points, view areas with more textures"];
          break;
          
        case ARTrackingStateReasonNone:
          NSLog(@"Tracking limited none");
          break;
      }
      break;
      
    case ARTrackingStateNormal:
      [self showMessage:@"Tracking is back to normal"];
      break;
  }
}

- (void)session:(ARSession *)session didFailWithError:(NSError *)error {
  // Present an error message to the user
  [self showMessage:@"session error"];
}

- (void)sessionWasInterrupted:(ARSession *)session {
  // Inform the user that the session has been interrupted, for example, by presenting an overlay, or being put in to the background
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Interruption" message:@"The tracking session has been interrupted. The session will be reset once the interruption has completed" preferredStyle:UIAlertControllerStyleAlert];
  
  UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
  }];
  
  [alert addAction:ok];
  [self presentViewController:alert animated:YES completion:^{
  }];
  
}

- (void)sessionInterruptionEnded:(ARSession *)session {
  // Reset tracking and/or remove existing anchors if consistent tracking is required
  [self showMessage:@"Tracking session has been reset due to interruption"];
  [self refresh];
}

@end
