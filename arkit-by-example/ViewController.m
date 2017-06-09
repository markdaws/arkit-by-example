//
//  ViewController.m
//  arkit-by-example
//
//  Created by md on 6/8/17.
//  Copyright © 2017 ruanestudios. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <ARSCNViewDelegate>

@property (nonatomic, strong) IBOutlet ARSCNView *sceneView;

@end

    
@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
    
  // Show statistics such as fps and timing information
  self.sceneView.showsStatistics = YES;
  self.sceneView.autoenablesDefaultLighting = YES;
  
  SCNScene *scene = [SCNScene new];
  SCNBox *boxGeometry = [SCNBox
                         boxWithWidth:0.1
                         height:0.1
                         length:0.1
                         chamferRadius:0.0];
  SCNNode *boxNode = [SCNNode nodeWithGeometry:boxGeometry];
  boxNode.position = SCNVector3Make(0, 0, -0.5);
  [scene.rootNode addChildNode:boxNode];
  
  // Set the scene to the view
  self.sceneView.scene = scene;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
    
  // Create a session configuration
  ARWorldTrackingSessionConfiguration *configuration = [ARWorldTrackingSessionConfiguration new];
    
  // Run the view's session
  [self.sceneView.session runWithConfiguration:configuration];
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

#pragma mark - ARSCNViewDelegate

/*
 // Set the view's delegate
 //self.sceneView.delegate = self;
// Override to create and configure nodes for anchors added to the view's session.
- (SCNNode *)renderer:(id<SCNSceneRenderer>)renderer nodeForAnchor:(ARAnchor *)anchor {
    SCNNode *node = [SCNNode new];
 
    // Add geometry to the node...
 
    return node;
}
*/

- (void)session:(ARSession *)session didFailWithError:(NSError *)error {
  // Present an error message to the user
}

- (void)sessionWasInterrupted:(ARSession *)session {
  // Inform the user that the session has been interrupted, for example, by presenting an overlay
}

- (void)sessionInterruptionEnded:(ARSession *)session {
  // Reset tracking and/or remove existing anchors if consistent tracking is required
}

@end
