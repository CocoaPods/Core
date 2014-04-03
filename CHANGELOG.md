# CocoaPods Core Changelog

## Master

##### Enhancements

* Added a check to the linter to ensure that the `social_media_url` has 
  been changed from the example value.  
  [Richard Lee](https://github.com/dlackty)
  [#67](https://github.com/CocoaPods/Core/issues/67)
  [#85](https://github.com/CocoaPods/Core/pull/85)

* Partial refactor of `Pod::Linter` class.  
  [Joshua Kalpin][Kapin]
  [#50](https://github.com/CocoaPods/Core/pull/50)

* Added `deprecated` and `deprecated_in_favor_of` attributes to Specification
  DSL.  
  [Paul Young](https://github.com/paulyoung)
  [#87](https://github.com/CocoaPods/Core/pull/87)

##### Bug Fixes

* Added logic to handle subspecs and platform scopes to linter check of 
  the `requries_arc` attribute.  
  [Fabio Pelosin][irrationalfab]
  [CocoaPods#2005](https://github.com/CocoaPods/CocoaPods/issues/2005)

* A spec is no longer considered empty if it only contains a resource_bundle
  [Joshua Kalpin][Kapin]
  [#63](https://github.com/CocoaPods/Core/issues/63)
  [#95](https://github.com/CocoaPods/Core/pull/95)


## 0.31.1

##### Enhancements

* The specification now strips the indentation of the `prefix_header` and
  `prepare_command` to aide their declaration as a here document (similarly to
  what it already does with the description).  
  [Fabio Pelosin][irrationalfab]
  [#51](https://github.com/CocoaPods/Core/issues/51)

##### Bug Fixes

* Fix linting for Pods which declare a private repo as the source.  
  [Boris Bügling](https://github.com/neonichu)
  [#82](https://github.com/CocoaPods/Core/issues/82)

## 0.31.0

##### Enhancements

* Changed all references to the optimistic operator.  
  [Luis de la Rosa](https://github.com/luisdelarosa)

* Check requires_arc set explicitly in podspec.  
  [Richard Lee](https://github.com/dlackty)

##### Bug Fixes

* Fix crash related to the usage of `s.version` in the git tag.  
  [Joel Parsons](https://github.com/joelparsons)

## 0.30.0

Introduction of the Changelog.

[irrationalfab]: https://github.com/irrationalfab
[Kapin]: https://github.com/Kapin
