# CocoaPods Core Changelog

## Master
* Removed legacy deprecation warnings of the Specification DSL.  
  [Fabio Pelosin][irrationalfab]

## 0.33.1

This version only introduces changes in the CocoaPods gem.

## 0.33.0

##### Enhancements

* Extracted URL validation into its own module.  
  [Boris Bügling](https://github.com/neonichu)
  [#115](https://github.com/CocoaPods/Core/issues/115)
  [#116](https://github.com/CocoaPods/Core/pull/116)

* Gracefully handle unexpected source structure.  
  [Samuel E. Giddins](https://github.com/segiddins)
  [#110](https://github.com/CocoaPods/Core/issues/110)

* Linter warnings and errors are now prefixed with \[`ATTRIBUTE_NAME`\].
  This `ATTRIBUTE_NAME` specifies which property caused the error/warning.  
  [Joshua Kalpin][Kapin]
  [#122](https://github.com/CocoaPods/Core/pull/122)

* Add support for the specification of multiple `default_subspecs`.  
  [Kyle Fuller][kylef]
  [CocoaPods#2099](https://github.com/CocoaPods/CocoaPods/issues/2099)

## 0.32.1
## 0.32.0

##### Enhancements

* Make Platform instances usable as Hash keys.  
  [Eloy Durán](https://github.com/alloy)
  [#109](https://github.com/CocoaPods/Core/pull/109)

* Accept new sources for Pods when they are just redirects of the old one.  
  [Boris Bügling](https://github.com/neonichu)
  [#101](https://github.com/CocoaPods/Core/issues/101)
  [#102](https://github.com/CocoaPods/Core/pull/102)

* Show informative error message when a merge conflict is detected in a YAML
  file.  
  [Luis de la Rosa](https://github.com/luisdelarosa)
  [#69](https://github.com/CocoaPods/Core/issues/69)
  [#100](https://github.com/CocoaPods/Core/pull/100)

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

* The linter now checks `framework` and `library` attributes for invalid
  strings.  
  [Paul Williamson](https://github.com/squarefrog)
  [Fabio Pelosin](irrationalfab)
  [#66](https://github.com/CocoaPods/Core/issues/66)
  [#96](https://github.com/CocoaPods/Core/pull/96)
  [#105](https://github.com/CocoaPods/Core/issues/105)

* Ignore any pod that begins with a `.`.  
  [Dustin Clark](https://github.com/clarkda)
  [#97](https://github.com/CocoaPods/Core/pull/97)
  [#98](https://github.com/CocoaPods/Core/issues/98)

* The Linter will not check for comments anymore.  
  [Fabio Pelosin][irrationalfab]
  [#108](https://github.com/CocoaPods/Core/issues/108)

* Removed legacy checks from the linter.  
  [Fabio Pelosin][irrationalfab]
  [#108](https://github.com/CocoaPods/Core/issues/108)

##### Bug Fixes

* Fixed logic for default subspec attribute in nested subspecs.  
  [Fabio Pelosin][irrationalfab]
  [CocoaPods#1021](https://github.com/CocoaPods/CocoaPods/issues/1021)

* Added logic to handle subspecs and platform scopes to linter check of
  the `requries_arc` attribute.  
  [Fabio Pelosin][irrationalfab]
  [CocoaPods#2005](https://github.com/CocoaPods/CocoaPods/issues/2005)

* The linter no longer considers empty a Specification if it only specifies the
  `resource_bundle` attribute.  
  [Joshua Kalpin][Kapin]  
  [#63](https://github.com/CocoaPods/Core/issues/63)
  [#95](https://github.com/CocoaPods/Core/pull/95)

* Fix sorting of versions coming from data providers
  [Carson McDonald][carsonmcdonald]
  [CocoaPods#1936](https://github.com/CocoaPods/CocoaPods/issues/1936)


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
