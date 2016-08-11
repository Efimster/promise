//
//  PromisesTests.swift
//  PromisesTests
//
//  Created by Iukhym Goncharuk on 8/2/16.
//  Copyright © 2016 Iukhym Goncharuk. All rights reserved.
//

import XCTest
@testable import Promises

class PromisesTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPromiseShouldBeImmediatellyFulfilledInInitializer() {
        let p1 = Promise({resolve in
            resolve(2)
        })
        
        XCTAssertNotNil(p1)
        XCTAssertNotNil(p1.resolvedValue)
        XCTAssertEqual(p1.resolvedValue!, 2)        
    }
    
    func testPromiseShouldBeFulfilledInThenFunctionByReturningPlainValue() {
        let p1 = Promise({resolve in
            resolve(2)
        }).then(onFulfilled: {val -> Int in
            XCTAssertEqual(val, 2)
            return 7
        })
        
        XCTAssertNotNil(p1)
        XCTAssertNotNil(p1.resolvedValue)
        XCTAssertEqual(p1.resolvedValue!, 7)
    }
    
    func testPromiseShouldBeFulfilledInThenFunctionByReturningAnotherResolvedPromise() {
        let p1 = Promise({resolve in
            resolve(2)
        }).then(onFulfilled: {val -> Promise<Int> in
            XCTAssertEqual(val, 2)
            return Promise({resolve in
                resolve(8)
            })
        })
        
        XCTAssertNotNil(p1)
        XCTAssertNotNil(p1.resolvedValue)
        XCTAssertEqual(p1.resolvedValue!, 8)
    }
    
    func testPromiseShouldBeFulfilledInThenFunction() {
        let p1 = Promise({resolve in
            resolve(2)
        }).then(onFulfilled: {(val:Int) -> Void in
            XCTAssertEqual(val, 2)
        })
        
        XCTAssertNotNil(p1)
        XCTAssertNotNil(p1.resolvedValue)
        XCTAssertEqual(p1.resolvedValue!, 2)
    }
    
    func testPromiseShouldAcceptDeferedFulfillmentInInitializer() {
        let expect = expectation(description: "promise has been resolved")
        let p1 = Promise({(resolve:(Int)->Void) in
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + .seconds(1), qos: .default, flags: .inheritQoS){
                resolve(2)
                expect.fulfill()
            }
        })
        
        waitForExpectations(timeout: 1.1) { error in
            XCTAssert(true, error.debugDescription)
        }

        XCTAssertNotNil(p1)
        XCTAssertNotNil(p1.resolvedValue)
        XCTAssertEqual(p1.resolvedValue!, 2)
    }
    
    func testPromiseShouldPerformDeferedFulfillmentInInitializerAndImmediateFulfilmentInThenFunction() {
        let expect = expectation(description: "promise has been resolved")
        
        let p1 = Promise({(resolve:(Int)->Void) in
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + .seconds(1), qos: .default, flags: .inheritQoS){
                resolve(2)
            }
        }).then(onFulfilled: {val -> Int in
            defer{
                expect.fulfill()
            }
            XCTAssertEqual(val, 2)
            return 7
        })
        
        waitForExpectations(timeout: 1.1) {error in
            XCTAssertNil(error)
        }
        
        XCTAssertNotNil(p1)
        XCTAssertNotNil(p1.resolvedValue)
        XCTAssertEqual(p1.resolvedValue!, 7)
    }
    
    func testPromiseShouldPerformDeferedFulfilmentInThenFunction() {
        let expect = expectation(description: "promise has been resolved")
        
        let p1 = Promise({(resolve:(Int)->Void) in
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + .seconds(1), qos: .default, flags: .inheritQoS){
                resolve(2)
            }
        }).then(onFulfilled: {val -> Promise<Int> in
            XCTAssertEqual(val, 2)
            let result = Promise({(resolve:(Int)->Void) in
                DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + .seconds(1), qos: .default, flags: .inheritQoS){
                    resolve(7)
                    expect.fulfill()
                }
            })
            return result
        })
        
        waitForExpectations(timeout: 2.5) { error in
            XCTAssertNil(error)
        }
        
        XCTAssertNotNil(p1)
        XCTAssertNotNil(p1.resolvedValue)
        XCTAssertEqual(p1.resolvedValue!, 7)
    }
    
    
    
//    func testPromiseShouldBeFulfilledInThenFunctionByReturningPlainValue2() {
//        let p1 = Promise({resolve in
//            resolve(2)
//        }).then(onFulfilled: {val in
//            XCTAssertEqual(val, 2)
//            return Promise({resolve in
//                resolve(7)
//            })
//        }).then(onFulfilled: {val in
//            XCTAssertEqual(val, 7)
//            return Promise({resolve in
//                resolve(8)
//            })
//        })
//        
//        XCTAssertNotNil(p1)
//        XCTAssertNotNil(p1.resolvedValue)
//        XCTAssertEqual(p1.resolvedValue!, 8)
//        
//    }
    
//    func testDelayedExecution() {
//        let p1 = Promise({resolve in
//            resolve(2)
//        }).then(onFulfilled: {val in
//            XCTAssertEqual(val, 2)
//            return Promise({resolve in
//                resolve(7)
//            })
//        }).then(onFulfilled: {val in
//            XCTAssertEqual(val, 7)
//            return Promise({resolve in
//                resolve(8)
//            })
//        })
//        
//        XCTAssertNotNil(p1)
//        XCTAssertNotNil(p1.resolvedValue)
//        XCTAssertEqual(p1.resolvedValue!, 8)
//        
//    }
    

    
}
