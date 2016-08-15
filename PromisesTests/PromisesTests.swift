//
//  PromisesTests.swift
//  PromisesTests
//
//  Created by Iukhym Goncharuk on 8/2/16.
//  Copyright © 2016 Efim Goncharuk. All rights reserved.
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
    
    enum TestError:Error{
        case test
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
        let p1 = Promise({(resolve:(Int)->Void, nil) in
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + .seconds(1), qos: .default, flags: .inheritQoS){
                resolve(2)
                expect.fulfill()
            }
        })
        
        waitForExpectations(timeout: 1.1) { error in
            XCTAssertNil(error)
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
        
        let p1 = Promise({resolve in
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
    
    func testPromiseShouldBeImmediatellyRejectedInInitializer() {
        let p1 = Promise<Int>({_, reject in
            reject(TestError.test)
        })
        
        XCTAssertNotNil(p1)
        XCTAssertNil(p1.resolvedValue)
        XCTAssertNotNil(p1.rejectReason)
        XCTAssertEqual(String(p1.rejectReason!), String(TestError.test))
    }
    
    func testPromiseShouldDoDeferedRejectionInInitializer() {
        let expect = expectation(description: "promise has been rejected")
        let p1 = Promise<Int>({_, reject in
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + .seconds(1), qos: .default, flags: .inheritQoS){
                reject(TestError.test)
                expect.fulfill()
            }
        })
        
        waitForExpectations(timeout: 1.1) { error in
            XCTAssertNil(error)
        }
        
        XCTAssertNotNil(p1)
        XCTAssertNil(p1.resolvedValue)
        XCTAssertNotNil(p1.rejectReason)
        XCTAssertEqual(String(p1.rejectReason!), String(TestError.test))
    }
    
    func testPromiseShouldPerformRejectionInThenFunction() {
        let expect = expectation(description: "promise has been resolved")
        
        let p1 = Promise({resolve in
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + .seconds(1), qos: .default, flags: .inheritQoS){
                resolve(2)
            }
        }).then(onFulfilled: {val -> Promise<Int> in
            XCTAssertEqual(val, 2)
            let result = Promise<Int>({_, reject in
                DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + .seconds(1), qos: .default, flags: .inheritQoS){
                    reject(TestError.test)
                    expect.fulfill()
                }
            })
            return result
        })
        
        waitForExpectations(timeout: 2.5) { error in
            XCTAssertNil(error)
        }
        
        XCTAssertNotNil(p1)
        XCTAssertNil(p1.resolvedValue)
        XCTAssertNotNil(p1.rejectReason)
        XCTAssertEqual(String(p1.rejectReason!), String(TestError.test))
    }
    
    func testPromiseShouldCatchImmediateRejectitionInCatchFunction() {
        let p1 = Promise<Int>({_, reject in
            reject(TestError.test)
        }).then(onFulfilled:{_ in
            XCTAssert(false)
        }).catch(onRejected:{(reason:Error)->Void in
            print("rejected")
            XCTAssertEqual(String(reason), String(TestError.test))
        })
        
        XCTAssertNotNil(p1)
        XCTAssertNil(p1.resolvedValue)
        XCTAssertNotNil(p1.rejectReason)
        XCTAssertEqual(String(p1.rejectReason!), String(TestError.test))
    }
    
    func testPromiseCouldBeFulfilledAfterRejectionInCatchFunction() {
        let expect = expectation(description: "promise has been resolved")
        
        let p1 = Promise<Int>({_, reject in
            reject(TestError.test)
        }).then(onFulfilled:{_ in
            XCTAssert(false)
        }).catch(onRejected:{(reason: Error) -> Promise<Int> in
            print("rejected")
            XCTAssertEqual(String(reason), String(TestError.test))
            return Promise<Int>({resolve, reject in
                DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + .seconds(1), qos: .default, flags: .inheritQoS){
                    resolve(7)
                    expect.fulfill()
                }
            })
        })
        
        waitForExpectations(timeout: 1.1) { error in
            XCTAssertNil(error)
        }

        
        XCTAssertNotNil(p1)
        XCTAssertNotNil(p1.resolvedValue)
        XCTAssertNil(p1.rejectReason)
        XCTAssertEqual(p1.resolvedValue!, 7)
    }
    
    func testPromiseShouldCatchImmediateRejectitionInThenFunction() {
        let p1 = Promise<Int>({_, reject in
            reject(TestError.test)
        }).then(onFulfilled:{_ in
            XCTAssert(false)
        }, onRejected:{(reason: Error) -> Void in
            print("rejected")
            XCTAssertEqual(String(reason), String(TestError.test))
        })
        
        XCTAssertNotNil(p1)
        XCTAssertNil(p1.resolvedValue)
        XCTAssertNotNil(p1.rejectReason)
        XCTAssertEqual(String(p1.rejectReason!), String(TestError.test))
    }
    
    func testPromiseCouldBeFulfilledAfterRejectionInThenFunction() {
        let expect = expectation(description: "promise has been resolved")
        
        let p1 = Promise<Int>({_, reject in
            reject(TestError.test)
        }).then(onFulfilled:{(_:Int)->Void in
            XCTAssert(false)
        }, onRejected:{(reason: Error) -> Promise<Int> in
            print("rejected")
            XCTAssertEqual(String(reason), String(TestError.test))
            return Promise<Int>({resolve, reject in
                DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + .seconds(1), qos: .default, flags: .inheritQoS){
                    resolve(7)
                    expect.fulfill()
                }
            })
        })
        
        waitForExpectations(timeout: 1.1) { error in
            XCTAssertNil(error)
        }
        
        
        XCTAssertNotNil(p1)
        XCTAssertNotNil(p1.resolvedValue)
        XCTAssertNil(p1.rejectReason)
        XCTAssertEqual(p1.resolvedValue!, 7)
    }
    
    func testPromiseAllShoudBeFullfilledOnceAllProsisesAreFulfilled() {
        let expect = expectation(description: "promise has been fulfilled")
        var promises:Array<Promise<Int>> = []
        promises.append(Promise({(resolve:(Int)->Void, _) in
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + .seconds(2), qos: .default, flags: .inheritQoS){
                resolve(1)
            }
        }))

        
        promises.append(Promise({(resolve:(Int)->Void, _) in
            resolve(2)
        }))
        
        promises.append(Promise({(resolve:(Int)->Void, _) in
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + .seconds(1), qos: .default, flags: .inheritQoS){
                resolve(3)
                
            }
        }))
        
        let p1 = Promise.all(promises: promises).then(onFulfilled:{(value:[Int])->Void in
            XCTAssertNotNil(value)
            XCTAssertEqual(value.count, 3)
            expect.fulfill()
        })
        
        waitForExpectations(timeout: 2.3) { error in
            XCTAssertNil(error)
        }
        
        XCTAssertNotNil(p1)
        XCTAssertNotNil(p1.resolvedValue)
        XCTAssertNil(p1.rejectReason)
        XCTAssertEqual(p1.resolvedValue!, [1, 2, 3])

    }
    
    func testPromiseAllShoudBeRejectedOnceOneOfProsisesGetRejected() {
        let expect = expectation(description: "promise has been rejected")
        var promises:Array<Promise<Int>> = []
        promises.append(Promise<Int>({_, reject in
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + .seconds(1), qos: .default, flags: .inheritQoS){
                reject(TestError.test)
            }
        }))
        
        
        promises.append(Promise({(resolve:(Int)->Void, nil) in
            resolve(2)
        }))
        
        promises.append(Promise({(resolve:(Int)->Void, nil) in
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + .seconds(1), qos: .default, flags: .inheritQoS){
                resolve(3)
                
            }
        }))
        
        let p1 = Promise.all(promises: promises).catch(onRejected:{reason in
            expect.fulfill()
        })
        
        waitForExpectations(timeout: 2.3) { error in
            XCTAssertNil(error)
        }
        
        XCTAssertNotNil(p1)
        XCTAssertNil(p1.resolvedValue)
        XCTAssertNotNil(p1.rejectReason)
        XCTAssertEqual(String(p1.rejectReason!), String(TestError.test))
    }
}
