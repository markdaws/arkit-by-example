//
//  CollisionCategory.h
//  arkit-by-example
//
//  Created by md on 6/15/17.
//  Copyright © 2017 ruanestudios. All rights reserved.
//

#ifndef CollisionCategory_h
#define CollisionCategory_h

typedef NS_OPTIONS(NSUInteger, CollisionCategory) {
  CollisionCategoryBottom  = 1 << 0,
  CollisionCategoryCube    = 1 << 1,
};

#endif /* CollisionCategory_h */
