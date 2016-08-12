//
//  Promise.swift
//  Promises
//
//  Created by Iukhym Goncharuk on 8/2/16.
//  Copyright © 2016 Efim Goncharuk. All rights reserved.
//

import Foundation

class Promise<T>{
    //MARK: properties
    var resolvedValue:T? = nil
    var rejectReason:Error? = nil
    var state:State = .pending
    var fulfilmentHandler:((_:T)->Promise<T>)?
    var rejectionHandler:((error:Error)->Promise<T>)?
    var upChainPromise:Promise<T>?
    
    //MARK: static functions
    
    static func all(){}
    static func race(){}

    
    static func resolve(value:T)->Promise<T>{
        let promise = Promise()
        promise.onFulfilled(value:value)
        return promise
    }
    
    // MARK: initializers
    
    private init() {
        
    }
    
    init(_ executor:(resolve:(_:T)->Void, reject:(_:Error)->Void)->Void){
        executor(resolve: onFulfilled, reject: onRejected);
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
    
    private func onFulfilled(value:T) -> Void {
        if let fulfilmentHandler = self.fulfilmentHandler {
            self.fulfilmentHandler = nil;
            let fulfillmentPromise = fulfilmentHandler(value)

            if fulfillmentPromise.state == .pending{
                fulfillmentPromise.upChainPromise = self
            }
            else if fulfillmentPromise.state == .fulfilled {
                onFulfilled(value: fulfillmentPromise.resolvedValue!)
            }
        }
        else{
            state = .fulfilled;
            resolvedValue = value;
        }

        if let fulfillmentUpChainPromise = self.upChainPromise {
            fulfillmentUpChainPromise.onFulfilled(value: value)
        }
    }
    
    func `catch`(onRejected reject:(_:Error)->Promise<T>)->Promise<T>{
        if state == .rejected {
            return reject(rejectReason!)
        }
        
        rejectionHandler = reject
        return self
    }
    
    func `catch`(onRejected reject:(_:Error)->Void)->Promise<T>{
        return `catch`(onRejected: {(reason:Error)->Promise<T> in
            reject(reason)
            return self
        })
    }
    
    func onRejected(reason:Error)->Void{
        if let rejectionHandler = self.rejectionHandler {
            self.rejectionHandler = nil;
            let rejectionPromise = rejectionHandler(error: reason)
            
            if rejectionPromise.state == .pending{
                rejectionPromise.upChainPromise = self
            }
            else if rejectionPromise.state == .rejected {
                onRejected(reason: rejectionPromise.rejectReason!)
            }
        }
        else{
            state = .rejected;
            rejectReason = reason;
        }
        
        if let rejectionUpChainPromise = self.upChainPromise {
            rejectionUpChainPromise.onRejected(reason: reason)
        }
    }
}
