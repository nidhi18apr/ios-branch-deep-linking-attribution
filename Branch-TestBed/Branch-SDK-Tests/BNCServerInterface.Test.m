//
//  BNCServerInterface.Test.m
//  Branch
//
//  Created by Graham Mueller on 3/31/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCTestCase.h"
#import "BNCServerInterface.h"
#import "BNCPreferenceHelper.h"
#import "BranchConstants.h"
#import <OCMock/OCMock.h>
#import <OHHTTPStubs/HTTPStubs.h>
#import <OHHTTPStubs/HTTPStubsResponse+JSON.h>

typedef void (^UrlConnectionCallback)(NSURLResponse *, NSData *, NSError *);

@interface BNCServerInterface()

// private BNCServerInterface method/properties to prepare dictionary for requests
@property (copy, nonatomic) NSString *requestEndpoint;
- (NSMutableDictionary *)prepareParamDict:(NSDictionary *)params
                               key:(NSString *)key
                       retryNumber:(NSInteger)retryNumber
                              requestType:(NSString *)reqType;
@end



@interface BNCServerInterfaceTests : BNCTestCase
@end

@implementation BNCServerInterfaceTests

#pragma mark - Tear Down

- (void)tearDown {
  [HTTPStubs removeAllStubs];
  [super tearDown];
}


#pragma mark - Key tests

//==================================================================================
// TEST 01
// This test checks to see that the branch key has been added to the GET request

- (void)testParamAddForBranchKey {
  [HTTPStubs removeAllStubs];
  BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
  XCTestExpectation* expectation =
    [self expectationWithDescription:@"NSURLSessionDataTask completed"];

  __block int callCount = 0;
  [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        // We're not sending a request, just verifying a "branch_key=key_xxx" is present.
        callCount++;
        NSLog(@"\n\nCall count %d.\nRequest: %@\n", callCount, request);
        if (callCount == 1) {
            BOOL foundIt = ([request.URL.query rangeOfString:@"branch_key=key_"].location != NSNotFound);
            XCTAssertTrue(foundIt, @"Branch Key not added");
            BNCAfterSecondsPerformBlockOnMainThread(0.01, ^{ [expectation fulfill]; });
            return YES;
        }
        return NO;
    }
    withStubResponse:^HTTPStubsResponse *(NSURLRequest *request) {
        NSDictionary* dummyJSONResponse = @{@"key": @"value"};
        return [HTTPStubsResponse responseWithJSONObject:dummyJSONResponse statusCode:200 headers:nil];
    }
  ];
  
  [serverInterface getRequest:nil url:@"http://foo" key:@"key_live_foo" callback:NULL];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
  [HTTPStubs removeAllStubs];
}

#pragma mark - Retry tests

//==================================================================================
// TEST 03
// This test simulates a poor network, with three failed GET attempts and one final success,
// for 4 connections.

- (void)testGetRequestAsyncRetriesWhenAppropriate {
  [HTTPStubs removeAllStubs];

  //Set up nsurlsession and data task, catching response
  BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
  serverInterface.preferenceHelper = [[BNCPreferenceHelper alloc] init];
  serverInterface.preferenceHelper.retryCount = 3;

  XCTestExpectation* successExpectation = [self expectationWithDescription:@"success"];
  
  __block NSInteger connectionAttempts = 0;
  __block NSInteger failedConnections = 0;
  __block NSInteger successfulConnections = 0;
  
  [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    BOOL foundBranchKey = [request.URL.query rangeOfString:@"branch_key=key_"].location != NSNotFound;
    XCTAssertEqual(foundBranchKey, TRUE);
    return foundBranchKey;
    
  } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
    @synchronized (self) {
        connectionAttempts++;
        NSLog(@"Attempt # %lu", (unsigned long)connectionAttempts);
        if (connectionAttempts < 3) {

          // Return an error the first three times
          NSDictionary* dummyJSONResponse = @{@"bad": @"data"};
          
          ++failedConnections;
          return [HTTPStubsResponse responseWithJSONObject:dummyJSONResponse statusCode:504 headers:nil];
          
        } else if (connectionAttempts == 3) {

          // Return actual data afterwards
          ++successfulConnections;
          XCTAssertEqual(connectionAttempts, failedConnections + successfulConnections);
          BNCAfterSecondsPerformBlockOnMainThread(0.01, ^{
            NSLog(@"==> Fullfill.");
            [successExpectation fulfill];
          });

          NSDictionary* dummyJSONResponse = @{@"key": @"value"};
          return [HTTPStubsResponse responseWithJSONObject:dummyJSONResponse statusCode:200 headers:nil];

        } else {

            XCTFail(@"Too many connection attempts: %ld.", (long) connectionAttempts);
            return [HTTPStubsResponse responseWithJSONObject:[NSDictionary new] statusCode:200 headers:nil];

        }
    }
  }];
  
  [serverInterface getRequest:nil url:@"http://foo" key:@"key_live_foo" callback:NULL];
  [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

//==================================================================================
// TEST 04
// This test checks to make sure that GET retries are not attempted when they have a retry
// count > 0, but retries aren't needed. Based on Test #3 above.

- (void)testGetRequestAsyncRetriesWhenInappropriateResponse {
  [HTTPStubs removeAllStubs];

  BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
  serverInterface.preferenceHelper = [[BNCPreferenceHelper alloc] init];
  serverInterface.preferenceHelper.retryCount = 3;
  
  XCTestExpectation* successExpectation = [self expectationWithDescription:@"success"];
  
  __block NSUInteger connectionAttempts = 0;
  
  [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    BOOL foundBranchKey = [request.URL.query rangeOfString:@"branch_key=key_"].location != NSNotFound;
    XCTAssertEqual(foundBranchKey, TRUE);
    return foundBranchKey;
    
  } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
    @synchronized (self) {
        // Return actual data on first attempt
        NSDictionary* dummyJSONResponse = @{@"key": @"value"};
        connectionAttempts++;
        XCTAssertEqual(connectionAttempts, 1);
        BNCAfterSecondsPerformBlockOnMainThread(0.01, ^ {
            [successExpectation fulfill];
        });
        return [HTTPStubsResponse responseWithJSONObject:dummyJSONResponse statusCode:200 headers:nil];
    }
  }];
  
  [serverInterface getRequest:nil url:@"http://foo" key:@"key_live_foo" callback:NULL];
  [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

//==================================================================================
// TEST 05
// This test checks to make sure that GET retries are not attempted when they have a retry
// count == 0, but retries aren't needed. Based on Test #4 above

- (void)testGetRequestAsyncRetriesWhenInappropriateRetryCount {
  [HTTPStubs removeAllStubs];

  BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
  serverInterface.preferenceHelper = [[BNCPreferenceHelper alloc] init];
  serverInterface.preferenceHelper.retryCount = 0;
  
  XCTestExpectation* successExpectation = [self expectationWithDescription:@"success"];
  
  __block NSUInteger connectionAttempts = 0;
  
  [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    BOOL foundBranchKey = [request.URL.query rangeOfString:@"branch_key=key_"].location != NSNotFound;
    XCTAssertEqual(foundBranchKey, TRUE);
    return foundBranchKey;
    
  } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
    @synchronized (self) {
        // Return actual data on first attempt
        NSDictionary* dummyJSONResponse = @{@"key": @"value"};
        connectionAttempts++;
        XCTAssertEqual(connectionAttempts, 1);
        BNCAfterSecondsPerformBlockOnMainThread(0.01, ^{
            [successExpectation fulfill];
        });
        return [HTTPStubsResponse responseWithJSONObject:dummyJSONResponse statusCode:200 headers:nil];
    }
  }];
  
  [serverInterface getRequest:nil url:@"http://foo" key:@"key_live_foo" callback:NULL];
  [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

//==================================================================================
// TEST 06
// This test simulates a poor network, with three failed GET attempts and one final success,
// for 4 connections. Based on Test #3 above

- (void)testPostRequestAsyncRetriesWhenAppropriate {
  [HTTPStubs removeAllStubs];

  //Set up nsurlsession and data task, catching response
  BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
  serverInterface.preferenceHelper = [[BNCPreferenceHelper alloc] init];
  serverInterface.preferenceHelper.retryCount = 3;
  [serverInterface.preferenceHelper synchronize];
  
  XCTestExpectation* successExpectation = [self expectationWithDescription:@"success"];
  
  __block NSUInteger connectionAttempts = 0;
  __block NSUInteger failedConnections = 0;
  __block NSUInteger successfulConnections = 0;
  
  [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    BOOL foundBranchKey = [request.URL.query rangeOfString:@"branch_key=key_"].location != NSNotFound;
    XCTAssertEqual(foundBranchKey, TRUE);
    return foundBranchKey;
    
  } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
    connectionAttempts++;
    NSLog(@"attempt # %lu", (unsigned long)connectionAttempts);
    if (connectionAttempts < 3) {
      // Return an error the first three times
      NSDictionary* dummyJSONResponse = @{@"bad": @"data"};
      
      ++failedConnections;
      return [HTTPStubsResponse responseWithJSONObject:dummyJSONResponse statusCode:504 headers:nil];
      
    } else if (connectionAttempts == 3) {

      // Return actual data afterwards
      ++successfulConnections;
      NSDictionary* dummyJSONResponse = @{@"key": @"value"};
      XCTAssertEqual(connectionAttempts, failedConnections + successfulConnections);
      BNCAfterSecondsPerformBlockOnMainThread(0.01, ^ {
        NSLog(@"==>> Fullfill <<==");
        [successExpectation fulfill];
      });
      return [HTTPStubsResponse responseWithJSONObject:dummyJSONResponse statusCode:200 headers:nil];

    } else {

        XCTFail(@"Too many connection attempts: %ld.", (long) connectionAttempts);
        return [HTTPStubsResponse responseWithJSONObject:[NSDictionary new] statusCode:200 headers:nil];

    }
  }];
  
  [serverInterface postRequest:nil url:@"http://foo" key:@"key_live_foo" callback:NULL];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

//==================================================================================
// TEST 07
// This test checks to make sure that POST retries are not attempted when they have a retry
// count == 0, and retries aren't needed. Based on Test #4 above

- (void)testPostRequestAsyncRetriesWhenInappropriateResponse {
  [HTTPStubs removeAllStubs];

  BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
  serverInterface.preferenceHelper = [[BNCPreferenceHelper alloc] init];
  serverInterface.preferenceHelper.retryCount = 3;
  
  XCTestExpectation* successExpectation = [self expectationWithDescription:@"success"];
  
  __block NSUInteger connectionAttempts = 0;
  
  [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    BOOL foundBranchKey = [request.URL.query rangeOfString:@"branch_key=key_"].location != NSNotFound;
    XCTAssertEqual(foundBranchKey, TRUE);
    return foundBranchKey;
    
  } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
    // Return actual data on first attempt
    NSDictionary* dummyJSONResponse = @{@"key": @"value"};
    connectionAttempts++;
    XCTAssertEqual(connectionAttempts, 1);
    BNCAfterSecondsPerformBlockOnMainThread(0.01, ^{ [successExpectation fulfill]; });
    return [HTTPStubsResponse responseWithJSONObject:dummyJSONResponse statusCode:200 headers:nil];
    
  }];
  
  [serverInterface postRequest:nil url:@"http://foo" key:@"key_live_foo" callback:NULL];
  [self waitForExpectationsWithTimeout:1.0 handler:nil];
  
}

//==================================================================================
// TEST 08
// This test checks to make sure that GET retries are not attempted when they have a retry
// count == 0, and retries aren't needed. Based on Test #4 above

- (void)testPostRequestAsyncRetriesWhenInappropriateRetryCount {
  [HTTPStubs removeAllStubs];

  BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
  serverInterface.preferenceHelper = [[BNCPreferenceHelper alloc] init];
  serverInterface.preferenceHelper.retryCount = 0;
  
  XCTestExpectation* successExpectation = [self expectationWithDescription:@"success"];
  
  __block NSUInteger connectionAttempts = 0;
  
  [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    BOOL foundBranchKey = [request.URL.query rangeOfString:@"branch_key=key_"].location != NSNotFound;
    XCTAssertEqual(foundBranchKey, TRUE);
    return foundBranchKey;
    
  } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
    // Return actual data on first attempt
    NSDictionary* dummyJSONResponse = @{@"key": @"value"};
    connectionAttempts++;
    XCTAssertEqual(connectionAttempts, 1);
    BNCAfterSecondsPerformBlockOnMainThread(0.01, ^{ [successExpectation fulfill]; });
    return [HTTPStubsResponse responseWithJSONObject:dummyJSONResponse statusCode:200 headers:nil];
  }];
  
  [serverInterface getRequest:nil url:@"http://foo" key:@"key_live_foo" callback:NULL];
  [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

//==================================================================================
// TEST 09
// Test certifcate pinning functionality.

// We do NOT pin by default anymore.
//- (void) testCertificatePinning {
//
//    [OHHTTPStubs removeAllStubs];
//    BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
//
//    XCTestExpectation* pinSuccess = [self expectationWithDescription:@"PinSuccess1"];
//    [serverInterface getRequest:[NSDictionary new]
//        url:@"https://branch.io"
//        key:@""
//        callback:^ (BNCServerResponse*response, NSError*error) {
//            XCTAssertEqualObjects(response.statusCode, @200);
//            [pinSuccess fulfill];
//        }];
//
//    XCTestExpectation* pinFail1 = [self expectationWithDescription:@"PinFail1"];
//    [serverInterface getRequest:[NSDictionary new]
//        url:@"https://google.com"
//        key:@""
//        callback:^ (BNCServerResponse*response, NSError*error) {
//            XCTAssertEqualObjects(response.statusCode, @-999);
//            [pinFail1 fulfill];
//        }];
//
//#if 0
//    // TODO: Fix so the end point so the test works on external (outside the Branch office) networks.
//
//    XCTestExpectation* pinFail2 = [self expectationWithDescription:@"PinFail2"];
//    [serverInterface getRequest:[NSDictionary new]
//        url:@"https://internal-cert-pinning-test-470549067.us-west-1.elb.amazonaws.com/"
//        key:@""
//        callback:^ (BNCServerResponse*response, NSError*error) {
//            XCTAssertEqualObjects(response.statusCode, @-999);
//            //XCTAssertEqualObjects(response.statusCode, @200);
//            [pinFail2 fulfill];
//        }];
//#endif
//
//  [self waitForExpectationsWithTimeout:10.0 handler:nil];
//}


//==================================================================================
// TEST 10
// Test mapping of X-Branch-Request-Id to [BNCServerResponse requestId]

- (void)testRequestIdFromHeader {
    [HTTPStubs removeAllStubs];

    BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
    NSString *requestId = @"1325e434fa294d3bb7d461349118602d-2020102721";

    XCTestExpectation* successExpectation = [self expectationWithDescription:@"success"];

    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        // Return the following response for any request
        return YES;
    } withStubResponse:^HTTPStubsResponse *(NSURLRequest *request) {
        // Stub out a response with a X-Branch-Request-Id header
        return [HTTPStubsResponse responseWithJSONObject:@{} statusCode:200 headers:@{@"X-Branch-Request-Id": requestId}];
    }];

    // POST to trigger the stubbed response.
    [serverInterface postRequest:@{} url:@"https://api.branch.io/v1/open" key:@"key_live_xxxx" callback:^(BNCServerResponse *response, NSError *error) {
        // Verify the request ID value on the BNCServerResponse
        BNCAfterSecondsPerformBlockOnMainThread(0.01, ^{ [successExpectation fulfill]; });
        XCTAssertEqualObjects(response.requestId, requestId);
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void) testServerInterfaceDictionaryPrepForGbraid {
    
    [HTTPStubs removeAllStubs];
    
    BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
    serverInterface.preferenceHelper = [BNCPreferenceHelper sharedInstance];
    serverInterface.preferenceHelper.retryCount = 3;
    serverInterface.requestEndpoint = @"/v2/event/standard";
    
    [BNCPreferenceHelper sharedInstance].randomizedBundleToken = @"575759106028389737";
 
    // Set referrerGBRAID and referrerGBRAIDInitDate
    NSString *gbraidValue = @"CjwKCAiA3L6PBhBvEiwAINlJ9Chixm216y8kYYJ1K94dm4FEkOgFfhIdKQdjWsYB7FqE7rf_zkGNEhoCuIEQAvD_BwE";
    [BNCPreferenceHelper sharedInstance].referrerGBRAID = gbraidValue;
    NSDate *now = [NSDate date];
    [BNCPreferenceHelper sharedInstance].referrerGBRAIDInitDate = now;
    
    //Check - gbraid should be present
    NSMutableDictionary *result = [serverInterface prepareParamDict:NULL key:@"1234567890" retryNumber:3 requestType:@"POST"];
    XCTAssertNotNil([result objectForKey:BRANCH_REQUEST_KEY_REFERRER_GBRAID]);
    XCTAssertTrue([[result objectForKey:BRANCH_REQUEST_KEY_REFERRER_GBRAID] isEqualToString:gbraidValue]);
    
    // Check for gbraid timestamp
    XCTAssertNotNil([result objectForKey:BRANCH_REQUEST_KEY_REFERRER_GBRAID_TIMESTAMP]);
    NSString *tsInMs = [NSString stringWithFormat:@"%lld", (long long)([now timeIntervalSince1970]*1000)];
    XCTAssertTrue([[result objectForKey:BRANCH_REQUEST_KEY_REFERRER_GBRAID_TIMESTAMP] isEqualToString:tsInMs]);

    //Check - gbraid should  be present - endpoint is open
    serverInterface.requestEndpoint = @"/v1/open";
    result = [serverInterface prepareParamDict:NULL key:@"1234567890" retryNumber:3 requestType:@"POST"];
    XCTAssertNotNil([result objectForKey:BRANCH_REQUEST_KEY_REFERRER_GBRAID]);
    
    //Check - gbraid should not be present - validity is expired
    NSDate *pastDate = [[NSDate date] dateByAddingTimeInterval:-2592001];
    [BNCPreferenceHelper sharedInstance].referrerGBRAIDInitDate = pastDate;
    serverInterface.requestEndpoint = @"/v2/event/standard";
    result = [serverInterface prepareParamDict:NULL key:@"1234567890" retryNumber:3 requestType:@"POST"];
    XCTAssertNil([result objectForKey:BRANCH_REQUEST_KEY_REFERRER_GBRAID]);
    
    //Check - gbraid should be present. Date is reset
    [BNCPreferenceHelper sharedInstance].referrerGBRAIDInitDate = now;
    result = [serverInterface prepareParamDict:NULL key:@"1234567890" retryNumber:3 requestType:@"POST"];
    XCTAssertNotNil([result objectForKey:BRANCH_REQUEST_KEY_REFERRER_GBRAID]);
    XCTAssertTrue([[result objectForKey:BRANCH_REQUEST_KEY_REFERRER_GBRAID] isEqualToString:gbraidValue]);
    
    [BNCPreferenceHelper sharedInstance].referrerGBRAID = nil;
  
}

@end
