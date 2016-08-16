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
    var fulfilmentHandler:((_:T)throws->Promise<T>)?
    var rejectionHandler:((error:Error)->Promise<T>)?
    var upChainPromise:Promise<T>?
    
    //MARK: static functions
    

    static func resolve(value:T)->Promise<T>{
        let promise = Promise()
        promise.onFulfilled(value:value)
        return promise
    }
    
    static func reject(reason:Error)->Promise<T>{
        let promise = Promise()
        promise.onRejected(reason:reason)
        return promise
    }
    
    static func all<S:Sequence where S.Iterator.Element == Promise<T>>(promises:S)->Promise<[T]>{
        let result = Promise<[T]>()
        var arrayOfPromises:[Promise<T>] = []
        var resolvedCount = 0
        
        for promise in promises{
            if promise.state == .rejected{
                result.onRejected(reason:promise.rejectReason!)
                return result
            }
            
            arrayOfPromises.append(promise)
        }
        
        var resolvedValues:Array<T?> = [T?](repeating:nil, count:arrayOfPromises.count)
        
        for (index, promise) in arrayOfPromises.enumerated(){
             let _ = promise
                .then(onFulfilled:{(value:T)->Void in
                    if result.state != .pending {
                        return
                    }

                    resolvedCount += 1
                    resolvedValues[index] = value
                    if arrayOfPromises.count == resolvedCount {
                        result.onFulfilled(value:resolvedValues.map({$0!}))
                    }
                }, onRejected:{(reason:Error)->Void in
                    if result.state != .pending {
                        return
                    }
                    result.onRejected(reason:reason)
                })
        }

        return result
    }
    
    static func race<S:Sequence where S.Iterator.Element == Promise<T>>(promises:S)->Promise<T>{
        let result = Promise<T>()
        
        for promise in promises{
            let _ = promise.then(onFulfilled:{(value:T)->Void in
                if result.state != .pending {
                    return
                }
                result.onFulfilled(value:value)
            }, onRejected:{(reason:Error)->Void in
                if result.state != .pending {
                    return
                }
                result.onRejected(reason:reason)
            })
        }
        return result
    }
    
    private static func normalizeVoidHandler(reject handler:(_:Error)->Void, forPromise promise:Promise<T>)->(_:Error)->Promise<T>{
        return {(reason:Error)->Promise<T> in
            handler(reason)
            return promise
        }
    }
    
    // MARK: initializers
    
    private init() {}
    
    init(_ executor:(resolve:(_:T)->Void, reject:(_:Error)->Void)throws->Void){
        do {
            try executor(resolve:onFulfilled, reject:onRejected)
        } catch {
            onRejected(reason:error)
        }
    }
    
    init(_ executor:(resolve:(_:T)->Void)throws->Void){
        do {
            try executor(resolve:onFulfilled)
        } catch {
            onRejected(reason:error)
        }
    }
    
    // MARK: methods
    
    
    func then(onFulfilled resolve:(_:T)throws->Promise<T>)->Promise<T>{
        if state == .fulfilled {
            do {
                return try resolve(resolvedValue!)
            } catch {
                onRejected(reason:error)
            }
        }
        
        fulfilmentHandler = resolve
        return self
    }
    
    func then(onFulfilled resolve:(_:T)throws->Promise<T>, onRejected reject:(_:Error)->Promise<T>)->Promise<T>{
        if state == .fulfilled {
            return then(onFulfilled:resolve)
        }
        else if state == .rejected {
            return reject(rejectReason!)
        }
        
        fulfilmentHandler = resolve
        rejectionHandler = reject
        return self
    }
    
    func then(onFulfilled resolve:(_:T)->T)->Promise<T>{
        return then(onFulfilled:{(resolvingValue:T)->Promise<T> in
            return Promise.resolve(value:resolve(resolvingValue))
        })
    }
    
    func then(onFulfilled resolve:(_:T)->T, onRejected reject:(_:Error)->Void)->Promise<T>{
        return then(onFulfilled:{(resolvingValue:T)->Promise<T> in
            return Promise.resolve(value:resolve(resolvingValue))
        }, onRejected:Promise.normalizeVoidHandler(reject:reject, forPromise:self))
    }
    
    func then(onFulfilled resolve:(_:T)->T, onRejected reject:(_:Error)->Promise<T>)->Promise<T>{
        return then(onFulfilled:{(resolvingValue:T)->Promise<T> in
            return Promise.resolve(value:resolve(resolvingValue))
        }, onRejected:reject)
    }
    
    func then(onFulfilled resolve:(_:T)->Void)->Promise<T>{
        return then(onFulfilled:{(resolvingValue:T)->Promise<T> in
            resolve(resolvingValue)
            return self
        })
    }

    func then(onFulfilled resolve:(_:T)->Void, onRejected reject:(_:Error)->Void)->Promise<T>{
        return then(onFulfilled:{(resolvingValue:T)->Promise<T> in
            resolve(resolvingValue)
            return self
        }, onRejected:Promise.normalizeVoidHandler(reject:reject, forPromise:self))
    }
    
    func then(onFulfilled resolve:(_:T)->Void, onRejected reject:(_:Error)->Promise<T>)->Promise<T>{
        return then(onFulfilled:{(resolvingValue:T)->Promise<T> in
            resolve(resolvingValue)
            return self
        }, onRejected:reject)
    }

    
    private func onFulfilled(value:T) -> Void {
        if let fulfilmentHandler = self.fulfilmentHandler {
            self.rejectionHandler = nil;
            self.fulfilmentHandler = nil;
            
            let fulfillmentPromise:Promise<T>?
            do {
                fulfillmentPromise =  try fulfilmentHandler(value)
            } catch {
                onRejected(reason:error)
                return
            }
            
            if fulfillmentPromise! === self {
                state = .fulfilled;
                resolvedValue = value;
                return
            }

            if fulfillmentPromise!.state == .pending{
                fulfillmentPromise!.upChainPromise = self
            }
            else if fulfillmentPromise!.state == .fulfilled {
                onFulfilled(value:fulfillmentPromise!.resolvedValue!)
            }
            else if fulfillmentPromise!.state == .rejected {
                onRejected(reason: fulfillmentPromise!.rejectReason!)
            }
        }
        else{
            state = .fulfilled;
            resolvedValue = value;
        }

        if let fulfillmentUpChainPromise = self.upChainPromise {
            fulfillmentUpChainPromise.onFulfilled(value:value)
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
        let onRejected =  Promise.normalizeVoidHandler(reject:reject, forPromise:self)
        return `catch`(onRejected:onRejected)
    }
    
    func onRejected(reason:Error)->Void{
        if let rejectionHandler = self.rejectionHandler {
            self.rejectionHandler = nil;
            self.fulfilmentHandler = nil;
            let rejectionPromise = rejectionHandler(error:reason)
            
            if rejectionPromise === self {
                state = .rejected;
                rejectReason = reason;
                return
            }
            
            if rejectionPromise.state == .pending{
                rejectionPromise.upChainPromise = self
            }
            else if rejectionPromise.state == .rejected {
                onRejected(reason:rejectionPromise.rejectReason!)
            }
            else if rejectionPromise.state == .fulfilled {
                onFulfilled(value:rejectionPromise.resolvedValue!)
            }
            
        }
        else{
            state = .rejected;
            rejectReason = reason;
        }
        
        if let rejectionUpChainPromise = self.upChainPromise {
            rejectionUpChainPromise.onRejected(reason:reason)
        }
    }
}
