//
//  BNCNativecompute.swift
//  Branch-TestBed
//

import Foundation
import NativeComputeSDK


@objc public class BNCNativeCompute: NSObject {
    
    @objc public var native: NativeCompute!
    @objc public var schemaMap: [String:Any]!
    
    @objc public init(branchKey: String) {
        super.init()
        self.native = createNativeCompute(branchKey: branchKey)
        print("Native initialized")
    }
    
    
    
    /**
     Initialize NativeCompute instance using branch_key
     
      - Parameter branchKey: branch_key used for Branch instance
      - Returns: NativeCompute instance
     */
    @objc public func createNativeCompute(branchKey: String) -> NativeCompute {
        let allowedUrlSet = Set<String>()
        return SharedNativeCompute().getInstance(domainWhiteList: allowedUrlSet, mode: Mode.production, branchKey: branchKey)
    }
    
    /**
        Calls Native isntance's sync schema service to pull down and update static and dyname Db instances
        Also processes configuration urls returned by sync schema service to pull down configurations e.g. capping
     
        - Parameter group: DispatchGroup semaphore to control this call completes before execution continues
     */
    @objc public func syncSchema(group: DispatchGroup) -> Void {
        self.native.launch() { err in
            guard err == nil else {
                print("Schema Update failed with error: ", err as Any)
                group.leave()
                return
            }
            self.native.getDebugHash { hash, err in
                print(" ===== Debug Hash ===== " + (hash ?? ""))
                group.leave()
            }
        }
    }
    /**
        Calls Native instance's registerEvent method to register the event and check whether to cap the event. Awaits for result
     
        - Parameter event: Event request data
        - Returns: input Event request object with capping results added
     */
    @objc public func checkNativeCapping(event: [String: Any]) -> NSMutableDictionary {
        var capMap = NSMutableDictionary()
        let nativeGroup = DispatchGroup()
        nativeGroup.enter()
        // current KMM memory model requires suspend/coroutines code blocks to be run on main thread
        DispatchQueue.main.sync {
            self.native.registerEvent(event: event) { result, err in
                guard result != nil else {
                    print("Register Event workflow invocation failed with error: ", err as Any)
                    nativeGroup.leave()
                    return
                }
                // registerEvent returns a Deferred future object.
                // Need to get results immediate before moving on and needs to be called on the main thread
                DispatchQueue.main.sync {
                    result?.await(completionHandler: { wfResult, wfError in
                        guard wfError == nil && wfResult != nil else {
                            print("Register Event processing failed with error: " , wfError as Any)
                            nativeGroup.leave()
                            return
                        }
                    capMap = wfResult as! NSMutableDictionary
                    nativeGroup.leave()
                    })
                }
            }
        }
        nativeGroup.wait()
        return capMap
    }
    
    /**
        Marks the event that has had a successful response to be completed. Fire and forget method. Do not need to await for result
     
        - Parameter event: Native capping results map that is included in the event request object as part of checkNativeCapping() method
     */
    @objc public func markEventAsCompleted(event: [String: Any]) -> Void {
        self.native.markEventAsCompleted(event: event) { result, err in
            guard err == nil else {
                print("Marked event workflow invocation failed with error: ", err as Any)
                return
            }
        }
    }
    
    
    /**
     Runs workflow to determine Native generated database content state
     
     - Returns: input Event request object with capping results added
     @objc public func syncSchema(native: NativeCompute, completion: @escaping ()->()) -> Void {
     */
    @objc public func getDeviceSchemaState(completion: @escaping ([String:Any])->()) -> Void {
        var schemaMap = [String:Any]()
        let nativeGroup = DispatchGroup()
        nativeGroup.enter()
        DispatchQueue.main.sync {
            self.native.getDeviceSchemaState { result, err in
                guard err == nil else {
                    print("Error running Get Device Schema State workflow: ", err as Any)
                    nativeGroup.leave()
                    return
                }
                DispatchQueue.main.sync {
                    result?.await(completionHandler: { wfResult, wfError in
                        guard wfError == nil else {
                            print("Device schema state workflow result contains error: ", wfError as Any)
                            nativeGroup.leave()
                            return
                        }
                        schemaMap = (wfResult as! [String:Any])
                        nativeGroup.leave()
                    })
                }
            }
        }
        nativeGroup.wait()
        completion(schemaMap)
    }
    
    /**
     
     - Returns: a randomly generated hash
     */
    @objc public func getDebugHash() -> String {
        var debugHash = ""
        let nativeGroup = DispatchGroup()
        nativeGroup.enter()
        DispatchQueue.main.sync {
            self.native.getDebugHash { hash, err in
                guard err == nil else {
                    nativeGroup.leave()
                    return
                }
                debugHash = hash ?? ""
                nativeGroup.leave()
            }
        }
        
        nativeGroup.wait()
        return debugHash
    }
    
    /**
     Runs a standalone workflow based on name
     
     - Parameter input: input map with workflow name and wofklow inputs
     
     */
    @objc public func runWorkflow(input: [String: Any]) -> Void {
        let workflowName = input["workflow"] as! String
        let workflowInputs = input["inputs"] as! [String:Any]

        self.native.invokeWorkflow(workflowName: workflowName, inputs: workflowInputs) { result, err in
            guard err == nil else {
                print("Error running Get Device Schema State workflow: ", err as Any)
                return
            }
            DispatchQueue.main.sync {
                result?.await(completionHandler: { wfResult, wfError in
                    guard wfError == nil else {
                        print("Device schema state workflow result contains error: ", wfError as Any)
                        return
                    }
                })
            }
        }
    }
    
}

