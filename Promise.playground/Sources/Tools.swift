import Foundation

public enum PromiseError:Error{
    case timeout
}

public func deferExecution(in seconds:Int, execute work: @escaping @convention(block) () -> Swift.Void){
    DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + .seconds(seconds), qos: .default, flags: .inheritQoS, execute:work);
}
