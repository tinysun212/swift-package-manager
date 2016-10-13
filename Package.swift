/*
 This source file is part of the Swift.org open source project

 Copyright 2015 - 2016 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import PackageDescription

let package = Package(
    name: "SwiftPM",
    
    /**
     The following is parsed by our bootstrap script, so
     if you make changes here please check the bootstrap still
     succeeds! Thanks.
    */
    targets: [
        // The `PackageDescription` module is special, it defines the API which
        // is available to the `Package.swift` manifest files.
        Target( name: "PackageDescription",
                dependencies: []),

        // MARK: Support libraries
        
        Target( name: "libc",
                dependencies: []),
        Target( name: "POSIX",
                dependencies: ["libc"]),
        Target( name: "Basic", dependencies: ["libc", "POSIX"]),
        Target( name: "Utility", dependencies: ["POSIX", "Basic", "PackageDescription"]),
            // FIXME: We should be kill the PackageDescription dependency above.
        Target( name: "SourceControl", dependencies: ["Basic", "Utility"]),

        // MARK: Project Model
        
        Target( name: "PackageModel", dependencies: ["Basic", "PackageDescription", "Utility"]),
        Target( name: "PackageLoading", dependencies: ["Basic", "PackageDescription", "PackageModel"]),

        // MARK: Package Dependency Resolution
        
        Target( name: "Get", dependencies: ["Basic", "PackageDescription", "PackageModel", "PackageLoading"]),
        Target( name: "PackageGraph", dependencies: ["Basic", "PackageLoading", "PackageModel", "SourceControl", "Utility"]),
        
        // MARK: Package Manager Functionality
        
        Target( name: "Build", dependencies: ["Basic", "PackageGraph"]),
        Target( name: "Xcodeproj", dependencies: ["Basic", "PackageGraph"]),

        // MARK: Commands
        
        Target( name: "Commands", dependencies: ["Basic", "Build", "Get", "PackageGraph", "SourceControl", "Xcodeproj"]),
        Target( name: "swift-package", dependencies: ["Commands"]),
        Target( name: "swift-build", dependencies: ["Commands"]),
        Target( name: "swift-test", dependencies: ["Commands"]),
        Target( name: "swiftpm-xctest-helper", dependencies: []),

        // MARK: Additional Test Dependencies

        Target( name: "TestSupport", dependencies: ["Basic", "POSIX", "PackageGraph", "PackageLoading", "SourceControl", "Utility"]),
        
        Target( name: "BasicTests", dependencies: ["TestSupport"]),
        Target( name: "BuildTests", dependencies: ["Build", "TestSupport"]),
        Target( name: "CommandsTests", dependencies: ["Commands", "TestSupport"]),
        Target( name: "FunctionalTests", dependencies: ["Basic", "Utility", "PackageModel", "TestSupport"]),
        Target( name: "GetTests", dependencies: ["Get", "TestSupport"]),
        Target( name: "PackageLoadingTests", dependencies: ["PackageLoading", "TestSupport"]),
        Target( name: "PackageGraphTests", dependencies: ["PackageGraph", "TestSupport"]),
        Target( name: "SourceControlTests", dependencies: ["SourceControl", "TestSupport"]),
        Target( name: "UtilityTests", dependencies: ["Utility", "TestSupport"]),
        Target( name: "XcodeprojTests", dependencies: ["Xcodeproj", "TestSupport"]),
    ])


// otherwise executables are auto-determined you could
// prevent this by asking for the auto-determined list
// here and editing it.

let dylib = Product(name: "PackageDescription", type: .Library(.Dynamic), modules: "PackageDescription")

products.append(dylib)
