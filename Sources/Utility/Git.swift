/*
 This source file is part of the Swift.org open source project

 Copyright 2015 - 2016 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Basic
import func POSIX.realpath
import func POSIX.getenv
import libc
import class Foundation.ProcessInfo

import struct PackageDescription.Version

extension Version {
    static func vprefix(_ string: String) -> Version? {
        if string.characters.first == "v" {
            return Version(string.characters.dropFirst())
        } else {
            return nil
        }
    }
}

public class Git {
    public class Repo {
        public let path: AbsolutePath

        public init?(path: AbsolutePath) {
            self.path = resolveSymlinks(path)
            guard isDirectory(path.appending(component: ".git")) else { return nil }
        }

        public lazy var origin: String? = { repo in
            do {
                guard let url = try Git.runPopen([Git.tool, "-C", repo.path.asString, "config", "--get", "remote.origin.url"]).chuzzle() else {
                    return nil
                }
                if URL.scheme(url) == nil {
                    return try realpath(url)
                } else {
                    return url
                }

            } catch {
                //TODO better
                print("Bad git repository: \(repo.path.asString)", to: &stderr)
                return nil
            }
        }(self)

        /// The set of known versions and their tags.
        public lazy var knownVersions: [Version: String] = { repo in
            // Get the list of tags.
            let out = (try? Git.runPopen([Git.tool, "-C", repo.path.asString, "tag", "-l"])) ?? ""
            let tags = out.characters.split(separator: "\n").map{ String($0) }

            // First try the plain init.
            var knownVersions: [Version: String] = [:]
            for tag in tags {
                if let version = Version(tag) {
                    knownVersions[version] = tag
                }
            }
            // If we didn't find any versions, look for 'v'-prefixed ones.
            if knownVersions.isEmpty {
                for tag in tags {
                    if let version = Version.vprefix(tag) {
                        knownVersions[version] = tag
                    }
                }
            }
            return knownVersions
        }(self)

        /// The set of versions in the repository.
        public var versions: [Version] {
            return [Version](knownVersions.keys)
        }

        /// Check if repo contains a version tag
        public var hasVersion: Bool {
            return !versions.isEmpty
        }
        
        public var branch: String! {
            return try? Git.runPopen([Git.tool, "-C", path.asString, "rev-parse", "--abbrev-ref", "HEAD"]).chomp()
        }

        public var sha: String! {
            return try? Git.runPopen([Git.tool, "-C", path.asString, "rev-parse", "--verify", "HEAD"]).chomp()
        }
        public func versionSha(tag: String) throws -> String {
            return try Git.runPopen([Git.tool, "-C", path.asString, "rev-parse", "--verify", "\(tag)"]).chomp()
        }
        public var hasLocalChanges: Bool {
            let changes = try? Git.runPopen([Git.tool, "-C", path.asString, "status", "--porcelain"]).chomp()
            return !(changes?.isEmpty ?? true)
        }

        public func fetch() throws {
#if os(Linux) || CYGWIN
            try system(Git.tool, "-C", path.asString, "fetch", "--tags", "origin", environment: ProcessInfo.processInfo().environment, message: nil)
#else
            try system(Git.tool, "-C", path.asString, "fetch", "--tags", "origin", environment: ProcessInfo.processInfo.environment, message: nil)
#endif
        }
    }

    public class var tool: String {
        return getenv("SWIFT_GIT") ?? "git"
    }

    public class var version: String! {
        return try? Git.runPopen([Git.tool, "version"])
    }

    public class var majorVersionNumber: Int? {
        let prefix = "git version"
        var version = self.version!
        if version.hasPrefix(prefix) {
            let prefixRange = version.startIndex...version.index(version.startIndex, offsetBy: prefix.characters.count)
            version.removeSubrange(prefixRange)
        }
        guard let first = version.characters.first else {
            return nil
        }
        return Int(String(first))
    }

    /// Execute a git command while suppressing output.
    //
    // FIXME: Move clients of this to using real structured APIs.
    public class func runCommandQuietly(_ arguments: [String]) throws {
        try system(arguments)
    }

    /// Execute a git command and capture the output.
    //
    // FIXME: Move clients of this to using real structured APIs.
    public class func runPopen(_ arguments: [String]) throws -> String {
        return try popen(arguments)
    }
}
