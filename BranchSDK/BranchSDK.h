//
//  BranchSDK.h
//  BranchSDK
//
//  Created by Ernest Cho on 4/5/22.
//

#import <Foundation/Foundation.h>

//! Project version number for BranchSDK.
FOUNDATION_EXPORT double BranchSDKVersionNumber;

//! Project version string for BranchSDK.
FOUNDATION_EXPORT const unsigned char BranchSDKVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <BranchSDK/PublicHeader.h>

// Public API for Apps
#import <BranchSDK/Branch.h>
#import <BranchSDK/BranchScene.h>
#import <BranchSDK/BranchEvent.h>
#import <BranchSDK/BranchUniversalObject.h>
#import <BranchSDK/BranchLinkProperties.h>

// Public API for internal Branch use. Plugins, Tests and Debugging.
#import <BranchSDK/BranchPluginSupport.h>
#import <BranchSDK/BNCConfig.h>
#import <BranchSDK/BNCLog.h>

#if !TARGET_OS_TV
// tvOS does not support these features
#import <BranchSDK/BranchShareLink.h>
#import <BranchSDK/BranchActivityItemProvider.h>
#import <BranchSDK/BranchCSSearchableItemAttributeSet.h>
#endif
