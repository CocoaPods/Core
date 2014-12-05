# CocoaPods Core Changelog

## Master

##### Bug Fixes

* Added `use_frameworks!` flag to DSL.  
  [Boris Bügling](https://github.com/neonichu)
  [Core#204](https://github.com/CocoaPods/Core/issues/204)

* Fixes the reading of dependencies that have spaces in their subspecs' name
  from Lockfiles.  
  [Samuel Giddins](https://github.com/segiddins)
  [CocoaPods#2850](https://github.com/CocoaPods/CocoaPods/issues/2850)

* The Linter will now give a warning if Github Gists begin with `www`  
  [Joshua Kalpin](https://github.com/Kapin)
  [Core#200](https://github.com/CocoaPods/Core/pull/200)


## 0.35.0

##### Enhancements

* Allow the specification of file patterns which require ARC with
  `requires_arc`.  
  [Kyle Fuller](https://github.com/kylef)
  [Samuel Giddins](https://github.com/segiddins)
  [CocoaPods#532](https://github.com/CocoaPods/CocoaPods/issues/532)

* Allow the specification of plugins and an optional hash of options
  for the plugin in the Podfile.  
  [Samuel Giddins](https://github.com/segiddins)


## 0.35.0.rc2

This version only introduces changes in the CocoaPods gem.

## 0.35.0.rc1

##### Breaking

* Support for Ruby < 2.0.0 has been dropped. CocoaPods now depends on
  Ruby 2.0.0 or greater.  
  [Eloy Durán](https://github.com/alloy)

##### Enhancements

* Remove `Specification::Set` attributes related to dependency resolution.
  Removed because the new, enhanced resolver no longer uses them to keep track
  of the source for requirements.  
  [Samuel Giddins](https://github.com/segiddins)
  [CocoaPods#2637](https://github.com/CocoaPods/CocoaPods/pull/2637)

##### Bug Fixes

* Fixes an issue when finding a `Source` based on the spec-repo's `git` URL
  when `git` is configured to rewrite URLs with the `url.<base>.insteadOf`
  option.  
  [Eloy Durán](https://github.com/alloy)
  [CocoaPods#2724](https://github.com/CocoaPods/CocoaPods/issues/2724)
  [CocoaPods#2696](https://github.com/CocoaPods/CocoaPods/issues/2696)
  [CocoaPods#2625](https://github.com/CocoaPods/CocoaPods/issues/2625)

* Fixes an issue linting the `flatten` for http sources in a podspec.  
  [Eloy Durán](https://github.com/alloy)
  [Core#193](https://github.com/CocoaPods/Core/issues/193)


## 0.34.4

##### Bug Fixes

* Fixes an issue linting options such as `type`, `sha1` for http sources in a
  podspec.
  [Kyle Fuller](https://github.com/kylef)
  [CocoaPods#2692](https://github.com/CocoaPods/CocoaPods/issues/2692)


## 0.34.2

##### Breaking

* Remove the notion of a `DataProvider` and move the handling of `Source` data
  from the file system into the `Source` class itself.  
  [Samuel Giddins](https://github.com/segiddins)
  [#183](https://github.com/CocoaPods/Core/issues/183)

##### Enhancements

* Optimize `Source#search` to avoid iterating through all available sets.  
  [Samuel Giddins](https://github.com/segiddins)
  [#182](https://github.com/CocoaPods/Core/issues/182)

* Set Sources are used in the order in which they are provided.  
  [Thomas Visser](https://github.com/Thomvis)
  [CocoaPods#2556](https://github.com/CocoaPods/CocoaPods/issues/2556)

##### Bug Fixes

* Fixes the reading of subspecs with spaces from Lockfiles.  
  [Samuel Giddins](https://github.com/segiddins)
  [#176](https://github.com/CocoaPods/Core/issues/176)

* Fixes an issue with local git spec repositories without git remotes.  
  [Kyle Fuller](https://github.com/kylef)
  [CocoaPods#2590](https://github.com/CocoaPods/CocoaPods/issues/2590)


## 0.34.1

##### Bug Fixes

* [Linter] Fix the license extension check.  
  [Fabio Pelosin](https://github.com/fabiopelosin)
  [CocoaPods#2525](https://github.com/CocoaPods/CocoaPods/issues/2525)


## 0.34.0

##### Enhancements

* Drop policy to not require a git commit for `0.0.1` versions.  
  [Fabio Pelosin](https://github.com/fabiopelosin)
  [CocoaPods#2335](https://github.com/CocoaPods/CocoaPods/issues/2335)

* Removes the unused `Source::GitHubDataProvider` class.  
  [Samuel Giddins](https://github.com/segiddins)
  [#174](https://github.com/CocoaPods/Core/pull/174)

* Adds a `url` attribute to `Source`.
  Note that this attribute is currently only gathered from `git`.  
  [Samuel Giddins](https://github.com/segiddins)


## 0.34.0.rc2

##### Bug Fixes

* Fixes an issue linting specifications with invalid HTTP source.  
  [Kyle Fuller](https://github.com/kylef)
  [CocoaPods#2463](https://github.com/CocoaPods/CocoaPods/issues/2463)

## 0.34.0.rc1

* Add support to specify dependencies per build configuration.
  This can be done using the following syntax in a Podfile:

      pod 'Lookback', :configurations => ['Debug']

  Currently configurations can only be specified per single Pod.
  [Joachim Bengtsson](https://github.com/nevyn)
  [Eloy Durán](https://github.com/alloy)
  [Fabio Pelosin](https://github.com/fabiopelosin)
  [#52](https://github.com/CocoaPods/Core/pull/52)
  [#154](https://github.com/CocoaPods/Core/pull/154)

* Added methods `deprecated?` and `deprecation_description` to
  `RootAttributesAccessors`.  
  [Hugo Tunius](https://github.com/k0nserv)
  [#157](https://github.com/CocoaPods/Core/pull/157)
  [CocoaPods#2180](https://github.com/CocoaPods/CocoaPods/issues/2180)

* The specification `requires_arc` attribute now defaults to true.  
  [Fabio Pelosin](https://github.com/fabiopelosin)
  [CocoaPods#267](https://github.com/CocoaPods/CocoaPods/issues/267)

* Now the specification linter warns if git sources use SSH URLs.  
  [Fabio Pelosin](https://github.com/fabiopelosin)
  [CocoaPods#118](https://github.com/CocoaPods/Core/issues/118)

* Removed legacy deprecation warnings of the Specification DSL.  
  [Fabio Pelosin](https://github.com/fabiopelosin)

* Improved error messages for merge conflicts of the Podfile.  
  [Taylor Halliday](https://github.com/tayhalla)
  [#147](https://github.com/CocoaPods/Core/pull/147)

* Only allow certain extensions for license files.  
  [Samuel Giddins](https://github.com/segiddins)
  [CocoaPods#2407](https://github.com/CocoaPods/CocoaPods/issues/2407)

* The linter now checks a JSON specification for unknown keys.  
  [Fabio Pelosin](https://github.com/fabiopelosin)
  [#88](https://github.com/CocoaPods/Core/issues/88)

* Exported JSON files have a trailing newline
  [Fabio Pelosin](https://github.com/fabiopelosin)
  [#139](https://github.com/CocoaPods/Core/issues/139)


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
  [Joshua Kalpin](https://github.com/Kapin)
  [#122](https://github.com/CocoaPods/Core/pull/122)

* Add support for the specification of multiple `default_subspecs`.  
  [Kyle Fuller](https://github.com/kylef)
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
  [Joshua Kalpin](https://github.com/Kapin)
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
  [Fabio Pelosin](https://github.com/fabiopelosin)
  [#108](https://github.com/CocoaPods/Core/issues/108)

* Removed legacy checks from the linter.  
  [Fabio Pelosin](https://github.com/fabiopelosin)
  [#108](https://github.com/CocoaPods/Core/issues/108)

##### Bug Fixes

* Fixed logic for default subspec attribute in nested subspecs.  
  [Fabio Pelosin](https://github.com/fabiopelosin)
  [CocoaPods#1021](https://github.com/CocoaPods/CocoaPods/issues/1021)

* Added logic to handle subspecs and platform scopes to linter check of
  the `requries_arc` attribute.  
  [Fabio Pelosin](https://github.com/fabiopelosin)
  [CocoaPods#2005](https://github.com/CocoaPods/CocoaPods/issues/2005)

* The linter no longer considers empty a Specification if it only specifies the
  `resource_bundle` attribute.  
  [Joshua Kalpin](https://github.com/Kapin)
  [#63](https://github.com/CocoaPods/Core/issues/63)
  [#95](https://github.com/CocoaPods/Core/pull/95)

* Fix sorting of versions coming from data providers
  [Carson McDonald](https://github.com/carsonmcdonald)
  [CocoaPods#1936](https://github.com/CocoaPods/CocoaPods/issues/1936)


## 0.31.1

##### Enhancements

* The specification now strips the indentation of the `prefix_header` and
  `prepare_command` to aide their declaration as a here document (similarly to
  what it already does with the description).  
  [Fabio Pelosin](https://github.com/fabiopelosin)
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
