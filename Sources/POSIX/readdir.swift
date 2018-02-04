/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import libc

extension dirent {
#if CYGWIN
    public var d_namlen: UInt16 {
        get {
            var d_name = self.d_name
            let name = withUnsafePointer(to: &d_name) {
                $0.withMemoryRebound(to: CChar.self, capacity: 255) {
                    String.init(validatingUTF8: $0)
                }
            }
            if name != nil {
                return UInt16(name!.characters.count)
            }
            return 0
        }
        set {
        }
    }
#elseif !os(macOS)
    // Add a portability wrapper.
    //
    // FIXME: This should come from the standard library: https://bugs.swift.org/browse/SR-1726
    public var d_namlen: UInt16 {
        get {
            return d_reclen
        }
        set {
            d_reclen = newValue
        }
    }
#endif

    /// Get the directory name.
    ///
    /// This returns nil if the name is not valid UTF8.
    public var name: String? {
        var d_name = self.d_name
        return withUnsafePointer(to: &d_name) {
            String(validatingUTF8: UnsafeRawPointer($0).assumingMemoryBound(to: CChar.self))
        }
    }
}

// Re-export the typealias, for portability.
public typealias dirent = libc.dirent
