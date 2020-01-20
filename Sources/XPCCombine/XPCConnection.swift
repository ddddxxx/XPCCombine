#if canImport(XPC)

import Foundation
import Dispatch
import XPC
import CXShim

public class XPCConnection: Publisher {
    
    public typealias Output = xpc_object_t
    public typealias Failure = XPCError
    
    private let connection: xpc_connection_t
    
    private lazy var inner = Subscription(parent: self)
    
    private init(connection: xpc_connection_t) {
        self.connection = connection
        xpc_connection_set_event_handler(connection) { [weak self] message in
            self?.inner.handleMessage(message)
        }
        // TODO: resume when requst
        connection.connectionResume()
    }
    
    deinit {
        connection.connectionCancel()
    }
    
    public func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
        inner.recieve(subscriber: subscriber.eraseToAnySubscriber())
    }
}

extension XPCConnection {
    
    final class Subscription: CXShim.Subscription {
        
        private let lock = NSLock()
        
        private var parent: XPCConnection?
        
        private var demand = Subscribers.Demand.none
        
        private let downstreamLock = NSLock()
        
        private var downstreams: [AnySubscriber<xpc_object_t, XPCError>] = []
        
        init(parent: XPCConnection) {
            self.parent = parent
        }
        
        func recieve(subscriber: AnySubscriber<xpc_object_t, XPCError>) {
            lock.lock()
            guard parent != nil else {
                lock.unlock()
                return
            }
            downstreams.append(subscriber)
            lock.unlock()
        }
        
        func handleMessage(_ message: xpc_object_t) {
            lock.lock()
            let downstreams = self.downstreams
            if let error = XPCError.fromXPC(message) {
                lockedTerminate()
                lock.unlock()
                downstreamLock.lock()
                downstreams.forEach { $0.receive(completion: .failure(error)) }
                downstreamLock.unlock()
            } else {
                demand -= 1
                lock.unlock()
                downstreamLock.lock()
                let newDemand = downstreams.reduce(into: Subscribers.Demand.none) {
                    $0 += $1.receive(message)
                }
                downstreamLock.unlock()
                lock.lock()
                demand += newDemand
                lock.unlock()
            }
        }
        
        func request(_ demand: Subscribers.Demand) {
            lock.lock()
            self.demand += demand
            lock.unlock()
        }
        
        func cancel() {
            lock.lock()
            guard let parent = self.parent else {
                lock.unlock()
                return
            }
            let downstreams = self.downstreams
            lockedTerminate()
            lock.unlock()
            downstreamLock.lock()
            downstreams.forEach { $0.receive(completion: .finished) }
            downstreamLock.unlock()
        }
        
        func lockedTerminate() {
            self.parent = nil
            self.downstreams = []
        }
    }
}

#endif
