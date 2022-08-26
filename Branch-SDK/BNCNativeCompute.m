//
//  BNCNativeCompute.m
//  Branch
//
//  Created by Usman Shafique on 8/26/22.
//  Copyright © 2022 Branch, Inc. All rights reserved.
//

#import "BNCNativeCompute.h"
@import NativeComputeSDK;

@interface BNCNativeCompute()
@property (strong, nonatomic) NCSDKNativeCompute *native;
@end

@implementation BNCNativeCompute


/**
 Initialize NativeCompute instance using branch_key
 
  - Parameter branchKey: branch_key used for Branch instance
  - Returns: NativeCompute instance
 */
- (void)initNativeCompute:(NSString *)branchKey {
    NSSet *allowedURLSet = [[NSSet alloc] init];
    self.native = [[NCSDKSharedNativeCompute alloc] getInstanceDomainWhiteList:allowedURLSet mode:NCSDKMode.production branchKey:branchKey];
}


/**
    Calls Native isntance's sync schema service to pull down and update static and dyname Db instances
    Also processes configuration urls returned by sync schema service to pull down configurations e.g. capping
 
    - Parameter group: DispatchGroup semaphore to control this call completes before execution continues
 */
- (void)syncSchema:(dispatch_group_t)group {
    [self.native launchCallback:^(NCSDKKotlinThrowable * error) {
        if (error != nil) {
            NSLog(@"Schema Update failed with error: %@", error);
            dispatch_group_leave(group);
        }
        [self.native getDebugHashWithCompletionHandler:^(NSString * debugHashResult, NSError * debugHashError) {
            if (debugHashError != nil) {
                NSLog(@"Debug Hash: ");
            } else {
                NSLog(@"Debug Hash : %@", debugHashResult);
            }
        }];
        
    }];
}


/**
    Calls Native instance's registerEvent method to register the event and check whether to cap the event. Awaits for result
 
    - Parameter event: Event request data
    - Returns: input Event request object with capping results added
 */
- (NSMutableDictionary *)checkNativeCapping:(NSDictionary<NSString *, id>*)event {
    __block NSMutableDictionary *capMap = [[NSMutableDictionary alloc] init];
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    dispatch_sync(dispatch_get_main_queue(), ^ {
        [self.native registerEventEvent:event completionHandler:^(NCSDKWorkflowResult * wfResult, NSError * wfError) {
            if (wfError != nil) {
                NSLog(@"Register Event workflow invocation failed with error: ,%@", wfError);
                return;
            }
            dispatch_sync(dispatch_get_main_queue(), ^ {
                [wfResult awaitWithCompletionHandler:^(id result, NSError * error) {
                    if (error != nil) {
                        NSLog(@"Register Event processing failed with error: ,%@", error);
                        return;
                    }
                    capMap = (NSMutableDictionary *)wfResult;
                    dispatch_group_leave(group);
                }];
            });
        }];
    });
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    return capMap;
}


/**
    Marks the event that has had a successful response to be completed. Fire and forget method. Do not need to await for result
 
    - Parameter event: Native capping results map that is included in the event request object as part of checkNativeCapping() method
 */
- (void)markEventAsCompleted:(NSDictionary<NSString *, id>*)event {
    [self.native markEventAsCompletedEvent:event completionHandler:^(NCSDKWorkflowResult * result, NSError * error) {
        if (error != nil) {
            NSLog(@"Mark event workflow invocation failed with error: %@", error);
            return;
        }
    }];
}


/**
 
 - Returns: a randomly generated hash
 */
-(NSString *)getDebugHash {
    __block NSMutableString* debugHash = [[NSMutableString alloc] initWithString:@""];
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    dispatch_sync(dispatch_get_main_queue(), ^ {
        [self.native getDebugHashWithCompletionHandler:^(NSString * debugHashResult, NSError * debugHashError) {
            if (debugHashError != nil) {
                NSLog(@"Error retrieving debug hash: %@", debugHashError);
                dispatch_group_leave(group);
            } else {
                debugHash = [[NSMutableString alloc] initWithString:debugHashResult];
            }
        }];
    });
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    return debugHash;
}

/**
 Runs a standalone workflow based on name

 - Parameter input: input map with workflow name and wofklow inputs

 */
-(void)runWorkflow:(NSDictionary<NSString *, id>*)input {
    NSString *workflowName = [[input objectForKey:@"workflow"] stringValue];
    NSDictionary<NSString *, id>* workflowInputs = [input objectForKey:@"inputs"];
    
    [self.native invokeWorkflowWorkflowName:workflowName inputs:workflowInputs completionHandler:^(NCSDKWorkflowResult * wfResult, NSError * wfError) {
        if (wfError != nil) {
            NSLog(@"Error running Get Device Schema State workflow: %@", wfError);
            return;
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^ {
                [wfResult awaitWithCompletionHandler:^(id result, NSError * error) {
                    if (error != nil) {
                        NSLog(@"Device schema state workflow result contains error: %@", error);
                        return;
                    }
                }];
            });
        }
    }];
}



/**
 Runs workflow to determine Native generated database content state
 
 - Returns: input Event request object with capping results added
 @objc public func syncSchema(native: NativeCompute, completion: @escaping ()->()) -> Void {
 */
- (void)getDeviceSchemaState {
    __block NSMutableDictionary *schemaMap = [[NSMutableDictionary alloc] init];
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    dispatch_sync(dispatch_get_main_queue(), ^ {
        [self.native getDeviceSchemaStateWithCompletionHandler:^(NCSDKWorkflowResult * wfResult, NSError * wfError) {
            if (
                }];
    });
}
//
//@objc public func getDeviceSchemaState(completion: @escaping ([String:Any])->()) -> Void {
//    var schemaMap = [String:Any]()
//    let nativeGroup = DispatchGroup()
//    nativeGroup.enter()
//    DispatchQueue.main.sync {
//        self.native.getDeviceSchemaState { result, err in
//            guard err == nil else {
//                print("Error running Get Device Schema State workflow: ", err as Any)
//                nativeGroup.leave()
//                return
//            }
//            DispatchQueue.main.sync {
//                result?.await(completionHandler: { wfResult, wfError in
//                    guard wfError == nil else {
//                        print("Device schema state workflow result contains error: ", wfError as Any)
//                        nativeGroup.leave()
//                        return
//                    }
//                    schemaMap = (wfResult as! [String:Any])
//                    nativeGroup.leave()
//                })
//            }
//        }
//    }
//    nativeGroup.wait()
//    completion(schemaMap)
//}

@end
