//: Playground - noun: a place where people can play

import Promise
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

Promise.resolve(value: "Hello, promise").then(onFulfilled:{value->Void in
    let resolvedValue = value
})
Promise<String>.reject(reason: PromiseError.timeout).then(onRejected:{reason->Void in
    let rejectedReason = reason
})

// MARK: fulfillment

let _ = Promise<String>({resolve in
    resolve("immediatelly fulfilled in initializer")
}).then(onFulfilled:{val in
    return val
})

let _ = Promise({resolve in
    deferExecution(in:1){resolve("defered fulfillment in initializer")}
}).then(onFulfilled: {(val:String)->Void in
    let resolvedValue = val
})

let _ = Promise({(resolve:@escaping (String)->Void) in
    let _ = deferExecution(in:1){resolve("defered fulfillment in initializer")}
}).then(onFulfilled:{(val:String)->Promise<String> in
    val
    return Promise({resolve in
        deferExecution(in:1){
            resolve("defered fulfillment in then")
        }
    })
}).then(onFulfilled: {(val:String)->Void in
    let resolvedValue = val
}).catch(onRejected:{reason->Void in
    let rejectedReason = reason
})

let _ = Promise({(resolve:@escaping (Int)->Void) in
    resolve(3)
}).then(onFulfilled: {val->Promise<Int> in
    return Promise<Int>({(resolve:@escaping (Int)->Void) in
        var x = val + 1
        deferExecution(in:1){
            x += 1
            resolve(x)
        }
    })
})
.then(onFulfilled:{val in
    val + 1
}).then(onFulfilled: {val in
    val + 1
})


// MARK: rejection

let _ = Promise<String>({_, reject in
    reject(PromiseError.timeout)
}).then(onRejected: {reason->Void in
    let rejectedReason = reason
})

let _ = Promise<String>({_, reject in
    deferExecution(in:1){reject(PromiseError.timeout)}
}).then(onRejected: {reason->Void in
    let rejectedReason = reason
})

let _ = Promise({resolve in
    resolve("immediatelly fulfilled in initializer")
}).then(onFulfilled: {val->Promise<String> in
    return Promise<String>({_, reject in
        deferExecution(in:1){reject(PromiseError.timeout)}
    })
}).catch(onRejected:{reason->Void in
    let rejectedReason = reason
})

// MARK: Promise.all

var promises:Array<Promise<Int>> = []
promises.append(Promise({resolve in deferExecution(in:2){resolve(1)}}))
promises.append(Promise({resolve in resolve(2)}))
promises.append(Promise({resolve in deferExecution(in:1){resolve(3)}}))
let _ = Promise.all(promises: promises).then(onFulfilled:{(value:[Int])->Void in
    let resolvedValue = value
})

promises = []
promises.append(Promise<Int>({_, reject in deferExecution(in:1){reject(PromiseError.timeout)}}))
promises.append(Promise({resolve in resolve(2)}))
promises.append(Promise({resolve in deferExecution(in:1){resolve(3)}}))
let _ = Promise.all(promises: promises).catch(onRejected:{reason->Void in
    let rejectedReason = reason
})

// MARK: Promise.race

promises = []
promises.append(Promise({_, reject in deferExecution(in:2){reject(PromiseError.timeout)}}))
promises.append(Promise({resolve in resolve(2)}))
promises.append(Promise({resolve in deferExecution(in:1){resolve(3)}}))
let _ = Promise.race(promises: promises).then(onFulfilled:{(value:Int)->Void in
    let resolvedValue = value
})

promises = []
promises.append(Promise<Int>({_, reject in deferExecution(in:1){reject(PromiseError.timeout)}}))
promises.append(Promise<Int>({resolve in deferExecution(in:2){resolve(3)}}))
let _ = Promise.race(promises: promises).catch(onRejected:{reason->Void in
    let rejectedReason = reason
})

// MARK: throw

let _ = Promise<String>({_, _ in
    throw PromiseError.timeout
}).catch(onRejected: {reason->Void in
    let rejectedReason = reason
})

let _ = Promise({resolve in
    deferExecution(in:1){resolve(2)}
}).then(onFulfilled: {val->Promise<Int> in
    return Promise({_, _ in
        throw PromiseError.timeout
    })
}).catch(onRejected: {reason->Void in
    let rejectedReason = reason
})

deferExecution(in:2){PlaygroundPage.current.finishExecution()}

