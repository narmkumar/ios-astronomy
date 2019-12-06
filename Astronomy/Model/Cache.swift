//
//  Cache.swift
//  Astronomy
//
//  Created by Niranjan Kumar on 12/5/19.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import Foundation

// Hashable allows two different things to be tied together in a dictionary (a key <> value pair)
class Cache<Key: Hashable , Value> {
    
    // a place for items to be cached
    private var cache = [Key: Value]()
    // serial queue so that everyoen fcan use shared resources without using NSLock
    private var queue = DispatchQueue(label: "com.LambdaSchool.Astronomy.ConcurrentOperationStateQueue")
    
    // have a function to add items to the cache
    func cache(key: Key, value: Value) {
        queue.async {
            self.cache[key] = value
        }
    }
    
    // have a function to return items that are cache
    func value(key: Key) -> Value? {
        return queue.sync {
            cache[key]
        }
    }
    
}
