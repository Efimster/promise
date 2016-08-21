//: Playground - noun: a place where people can play

import Promise
import XCPlayground

XCPlaygroundPage.currentPage.needsIndefiniteExecution = true

enum PromiseError:Error{
    case timeout
}

Promise.resolve(value: "Hello, promise").resolvedValue

//Promise<String>({resolve in
//    resolve("immediatelly fulfilled in initializer")
//}).resolvedValue

//Promise({resolve in
//    resolve("Hello, promise")
//}).then(onFulfilled: {val -> String in
//    return "fulfilled in then() by returning plain value"
//}).resolvedValue
//
//
//Promise({resolve in
//    resolve("Hello, promise")
//}).then(onFulfilled: {val -> Promise<String> in
//    return Promise({resolve in
//        resolve("fulfilled in then() by returning resolved promise")
//    })
//}).resolvedValue


//Promise({resolve in
//    resolve("Hello, promise")
//}).then(onFulfilled: {(val:String) -> Void in
//    print("returning void")
//}).resolvedValue
//
//Promise({(resolve:@escaping (Int)->Void) in
//    print("tttt")
//    deferExecution(in:1){resolve(2)}
//}).then(onFulfilled: {val -> Int in
//    print("xxx")
//    return 7
//}).then(onFulfilled: {val -> Int in
//    return val
//})

//var x = 0
//Promise({(resolve:@escaping (Int)->Void) in
//    x += 1
//    resolve(x)
//}).then(onFulfilled: {val -> Promise<Int> in
//    return Promise<Int>({(resolve:@escaping (Int)->Void) in
//        var x = val + 1
//        deferExecution(in:1){
//            x += 1
//            resolve(x)
//        }
//    })
//})
//.then(onFulfilled:{val in
//    val + 1
//}).then(onFulfilled: {val in
//    val + 1
//})


//deferExecution(in:1){XCPlaygroundPage.currentPage.finishExecution()}

