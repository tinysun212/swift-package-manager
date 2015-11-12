# Swift Package Manager

The Swift Package Manager provides a set of tools for building and distributing Swift code.

* * *

## Getting Started

(Link to "User Guide" on Swift.org)

With Swift 2.1 execute: `swift build`.
If you are developing the package manager then please
run the bootstrap script (`Utilities/bootstrap`) instead.

Swift development is iterative and rapid,
thus the package manager may require the latest Swift to compile.
If your compile fails please build the latest Swift and try again.
If you are trying to compile with the (optional) Xcode project you will need to
download a Swift xctoolchain (Link).

## Contributing

(Link to "Contributor Guide" on Swift.org)

* * *

## Overview

Swift organizes code into _modules_.
Each module specifies a namespace
and enforces access controls on which parts of that code
can be used outside of the module.

A program may have all of its code in a single module,
or it may import other modules as _dependencies_.
Aside from the handful of system-provided modules,
such as Darwin on OS X
or GLibc on Linux,
most dependencies require code to be downloaded and built in order to be used.

Extracting code that solves a particular problem into a separate module
allows for that code to be reused in other situations.
For example, a module that provides functionality for making network requests
could be shared between a photo sharing app
and a program that displays the weather forecast.
And if a new module comes along that does a better job,
it can be swapped in easily, with minimal change.
By embracing modularity, you can focus on the interesting aspects of the problem at hand,
rather than getting bogged down by solved problems you encounter along the way.

Adding dependencies to a project, however, has an associated coordination cost.
In addition to downloading and building the source code for a dependency,
that dependency's own dependencies must be downloaded and built as well,
and so on, until the entire dependency graph is satisfied.
To complicate matters further,
a dependency may specify version requirements,
which may have to be reconciled with the version requirements of another module with the same dependency.

The role of the package manager is to automate the process
of downloading and building all of dependencies for a project.

(...)

A _package_ consists of Swift source files
and a manifest file, called `Package.swift`,
which defines the package name and contents.
The `Package.swift` file defines a package in a declarative manner
with Swift code using the `PackageDescription` module.

// TODO: "You can find API documentation for the `PackageDescription` module here: ..."

A package has one or more _targets_.
Each target specifies a _product_
and may declare one or more _dependencies_.

// TODO: Should this instead say that products are modules, and not make the same distinction?
A target may build either a _library_ or an _executable_ as its product.
A library contains a module that can be imported by other Swift code.
An executable is a program that can be run by the operating system.

A target's dependencies are any modules that are required by code in the package.
A dependency consists of a relative or absolute URL
that points to the source of the package to be used,
as well as a set of requirements for what version of that code can be used.

### Convention Based Target Determination

Targets are determined automatically based on how you layout your sources.

For example if you created a directory with the following layout:

```
foo/
foo/src/bar.swift
foo/src/baz.swift
foo/Package.swift
```

Running `swift build` within directory `foo` would produce a single library target: `foo/.build/debug/foo.a`

The file `Package.swift` is the manifest file, and is discussed in the next section.

To create multiple targets create multiple subdirectories:

```
example/
example/src/foo/foo.swift
example/src/bar/bar.swift
example/Package.swift
```

Running `swift build` would produce two library targets:

* `foo/.build/debug/foo.a`
* `foo/.build/debug/bar.a`

To generate executables create a main.swift in a target directory:

```
example/
example/src/foo/main.swift
example/src/bar/bar.swift
example/Package.swift
```

Running `swift build` would now produce:

* `foo/.build/debug/foo`
* `foo/.build/debug/bar.a`

Where `foo` is an executable and `bar.a` a static library.

### Manifest File

Instructions for how to build a package are provided by
a manifest file, called `Package.swift`.
You can customize this file to
declare build targets or dependencies,
include or exclude source files,
and specify build configurations for the module or individual files.

Here's an example of a `Package.swift` file:

```swift
import PackageDescription

let package = Package(
    name: "Hello",
    dependencies: [
        .Package(url: "ssh://git@example.com/Greeter.git", versions: "1.0.0"),
    ]
)
```

A `Package.swift` file a Swift file
that declaratively configures a Package
using types defined in the `PackageDescription` module.
This manifest declares a dependency on an external package: `Greeter`.

If your package contains multiple targets that depend on each other you will
need to specify their interdependencies. Here is an example:

```swift
import PackageDescription

let package = Package(
    name: "Example",
    targets: [
        Target(
            name: "top",
            dependencies: [.Target(name: "bottom")]),
        Target(
            name: "bottom")
```

The targets are named how your subdirectories are named.

* * *

## Usage

You use the Swift Package Manager through subcommands of the `swift` command.

### `swift build`

The `swift build` command builds a package and its dependencies.
If you are developing packages, you will use `swift build`

### `swift get`

The `swift get` command downloads packages and any dependencies into a new container.
If you are deploying packages, you will use `swift get`.


# System Libraries

You can link against system libraries using the package manager.

To do so special packages must be published that contain a module map for that library.

Let’s use the example of JasPer. This is the code we want to compile:

```swift
import CJasPer

guard let version = String.fromCString(jas_getversion()) else {
    fatalError("Could not get JasPer version")
}

print("JasPer \(version)")
```

To `import CJasPer` the package manager requires
that `JasPer` has been installed by a system packager, the following files are of
interest:

    /usr/lib/libjasper.so      # .dylib on OS X
    /usr/include/jasper.h

Using our system packager we determine that JasPer depends on JPEG, and JPEG depends on libc.
We must provide or find packages that provide modules for `JasPer` and `JPEG`,
libc also has a module map, but it is
provided by Swift (`Darwin` and `Glibc` on OS X and Linux respectively).

We search but cannot find existing packages for JasPer or JPEG, so we must create them ourselves.

Packages that provide module maps for system libraries are handled differently to regular Swift packages.

In a directory called `CJasPer` we add the following single file named `module.map`:

    module CJasPer [system] {
        header "/usr/include/jasper/jasper.h"
        link "jasper"
        export *
    }

The convention we hope the community will adopt is to prefix such modules with `C` and to camelcase the modules
as per Swift module name conventions. Then the community is free to name another module simply `JasPer` which
contains more “Swifty” function wrappers around the raw C interface.

we must do the same for `JPEG`:

    module CJPEG [system] {
        header "/usr/include/jpeglib.h"
        link "jpeg"
        export *
    }


Note we do not call the module `CLibjpeg`. In general avoid the lib prefix unless the authors of the package
typically always refer to it that way. A good rule of thumb is to look at the header files, here we can
see the header is called simply "jpeg.h". Pay attention to capitalization, note that we provide `CPOSIX` and not
`CPosix`, this is because POSIX is an acronym and is typically spelled all-caps.

Back in our example app we need a `Package.swift` that depends on CJasPer:

```swift
import PackageDescription

let package = Package(
    dependencies: [
        .Package(url: "../CJasPer", majorVersion: 1),
    ]
)
```

While we are developing these packages we can refer to `CJasPer` using a relative file path, but once we publish
this package on the Internet we must also find homes for `CJPEG` and `CJasPer`.

Now if we type `swift build` in our example app directory we will create an executable:

    $ swift build
    …
    $ .build/debug/example
    JasPer 1.900.1
    $


**Take care** you must specify all the headers that a system package uses, ***BUT*** you must not specify headers that are included
from the headers you have already specified. For example with JasPer there are three headers but the other two are included from the
umbrella header `jasper.h`. If you get the includes wrong you will get intermittent and hard to debug compile issues.


## Crossplatform Module Maps

The package manager will mangle your module map when used to cater to both `/usr` and `/usr/local` installs of system packages.
However this may not be sufficient for all platforms.

Long term we hope that system libraries and system packagers will provide module maps and thus this component of the package
manager will become redundant.

However until then we will (in the near future)
provide a way for module map packages to provide modulemaps for multiple platforms in the same package.


## Module Map Versioning 

Version the module maps semantically. The meaning of semantic version is less clear here, so use your best judgement.
Do not follow the version of the system library the module map represents, version the module map(s) indepenently.


## Major Versions

Follow the conventions of system packagers, for example, the debian package for python3 is called python3, there is not a single
package for python and python is designed to be installed side-by-side. Where you to make a module map for python3 you should name
it `CPython3`.


## Packages That Provide Multiple Libraries

Some system packages provide multiple libraries (`.so` and `.dylib` files). In such cases you should add all the libraries to that Swift modulemap package’s `.modulemap` file:

    module CFoo [system] {
        header "/usr/local/include/foo/foo.h"
        link "foo"
        export *
    }
    
    module CFooBar [system] {
        header "/usr/include/foo/bar.h"
        link "foobar"
        export *
    }
    
    module CFooBaz [system] {
        header "/usr/include/foo/baz.h"
        link "foobaz"
        export *
    }

`foobar` and `foobaz` link to `foo`;
we don’t need to specify this information in the module-map because
the headers `foo/bar.h` and `foo/baz.h` both include `foo/foo.h`.
It is very important however that those headers do include their dependent headers,
otherwise when the modules are imported into Swift the dependent modules will not get
imported automatically and link errors will happen.
If these link errors occur to consumers of a package that consumes your
package the link errors can be especially difficult to debug.