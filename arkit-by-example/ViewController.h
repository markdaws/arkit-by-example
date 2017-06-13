//
//  ViewController.h
//  arkit-by-example
//
//  Created by md on 6/8/17.
//  Copyright © 2017 ruanestudios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <SceneKit/SceneKit.h>
#import <ARKit/ARKit.h>
#import "Plane.h"

@interface ViewController : UIViewController
- (void)setupScene;
- (void)setupSession;
- (void)setupRecognizers;
- (void)insertGeometry:(ARHitTestResult *)hitResult;
- (void)explode:(ARHitTestResult *)hitResult;
- (void)handleTapFrom: (UITapGestureRecognizer *)recognizer;
- (void)handleHoldFrom: (UILongPressGestureRecognizer *)recognizer;
- (void)handleHidePlaneFrom: (UILongPressGestureRecognizer *)recognizer;
@property NSMutableDictionary *planes;
@property NSMutableArray *boxes;
@end
