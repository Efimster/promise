//: Playground - noun: a place where people can play

import Promise

Promise.resolve(value: "Hello, promise").resolvedValue

Promise<String>({resolve in
    resolve("immediatelly fulfilled in initializer")
}).resolvedValue






