# CocoaPods Core

[![Build Status](https://travis-ci.org/CocoaPods/Core.png?branch=master)](https://travis-ci.org/CocoaPods/Core)
[![Coverage Status](https://coveralls.io/repos/CocoaPods/Core/badge.png?branch=master)](https://coveralls.io/r/CocoaPods/Core)

The CocoaPods-Core gem provides support to work with the models of CocoaPods.
It is intended to be used in place of the CocoaPods when the installation
of the dependencies is not needed. Therefore, it is suitable for web services.

Provides support for working with the following models:

- `Pod::Specification` - [podspec files](http://cocoapods.github.com/specification.html).
- `Pod::Podfile` - [podfile specifications](http://cocoapods.github.com/podfile.html).
- `Pod::Source` - collections of podspec files like the [CocoaPods Spec repo](https://github.com/CocoaPods/Specs).

The gem also provides support for ancillary features like
`Pod::Specification::Set::Presenter` suitable for presetting descriptions of
Pods and the `Specification::Linter`, which ensures the validity of podspec
files.

## Installation

```
$ [sudo] gem install cocoapods-core
```

The `cocoapods-core` gem requires either:

- Ruby 1.8.7 (shipped with OS X 10.8).
- Ruby 1.9.3 (recommended).

## Collaborate

All CocoaPods development happens on GitHub, there is a repository for
[CocoaPods](https://github.com/CocoaPods/CocoaPods) and one for the [CocoaPods
specs](https://github.com/CocoaPods/Specs). Contributing patches or Pods is
really easy and gratifying.

Follow [@CocoaPodsOrg](http://twitter.com/CocoaPodsOrg) to get up to date
information about what's going on in the CocoaPods world.

## License

This gem and CocoaPods are available under the MIT license.
