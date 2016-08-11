//
//  Promise.swift
//  Promises
//
//  Created by Iukhym Goncharuk on 8/2/16.
//  Copyright © 2016 Iukhym Goncharuk. All rights reserved.
//

import Foundation

class Promise<T>{
    //MARK: properties
    var resolvedValue:T? = nil
    var rejectReason:Error? = nil
    var state:State = .pending
    var fulfilmentHandler:((_:T)->Promise<T>)?
    var rejectionHandler:((error:Error)->Void)?
    var fulfillmentUpChainPromise:Promise<T>?
    
    //MARK: static functions
    
    static func all(){}
    static func race(){}
//    static func reject(reason:ErrorProtocol)->Promise<T>{
//        let promise = Promise()
//        promise.onReject(reason: reason)
//        return promise
//    }
    
    static func resolve(value:T)->Promise<T>{
        let promise = Promise()
        promise.onFulfilled(value:value)
        return promise
    }
    
    // MARK: initializers
    
    private init() {
        
    }
    
    init(_ executor:(resolve:(_:T)->Void)->Void){
        executor(resolve: onFulfilled);
    }
    
    // MARK: methods
    
    
    func then(onFulfilled resolve:(_:T)->Promise<T>)->Promise<T>{
        if state == .fulfilled {
            return resolve(resolvedValue!)
        }
        
        fulfilmentHandler = resolve
        return self
    }
    
    func then(onFulfilled resolve:(_:T)->T)->Promise<T>{
        return then(onFulfilled: {(resolvingValue:T)->Promise<T> in
            return Promise.resolve(value: resolve(resolvingValue))
        })
    }

    func then(onFulfilled resolve:(_:T)->Void)->Promise<T>{
        return then(onFulfilled: {(resolvingValue:T)->Promise<T> in
            resolve(resolvingValue)
            return self
        })
    }

    func error(){}
    
    private func onFulfilled(value:T) -> Void {
        if let fulfilmentHandler = self.fulfilmentHandler {
            self.fulfilmentHandler = nil;
            let fulfillmentPromise = fulfilmentHandler(value)

            if fulfillmentPromise.state == .pending{
                fulfillmentPromise.fulfillmentUpChainPromise = self
            }
            else if fulfillmentPromise.state == .fulfilled {
                onFulfilled(value: fulfillmentPromise.resolvedValue!)
            }
        }
        else{
            state = .fulfilled;
            resolvedValue = value;
        }

        if let fulfillmentUpChainPromise = self.fulfillmentUpChainPromise {
            fulfillmentUpChainPromise.onFulfilled(value: value)
        }
    }
    
    func onReject(reason:Error)->Void{
        state = .rejected;
        rejectReason = reason;
    }
}

enum State{
    case pending
    case fulfilled
    case rejected
}
