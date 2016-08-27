/*
 This source file is part of the Swift.org open source project

 Copyright 2015 - 2016 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

#if os(Linux) || CYGWIN
@_exported import Glibc
#else
@_exported import Darwin.C
#endif

#if CYGWIN
public var stdout : UnsafeMutablePointer<__FILE>! {
    get {
		if let reent = __getreent() {
		    return reent.pointee._stdout
		}
		return nil
	}
}
public var stderr : UnsafeMutablePointer<__FILE>! {
    get {
		if let reent = __getreent() {
		    return reent.pointee._stderr
		}
		return nil
	}
}
#endif
