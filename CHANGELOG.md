# CocoaPods Core Changelog

## Master

##### Bug Fixes

* Allow non-exact version matches to be equal while maintaining a sort order.  
  [Samuel Giddins](https://github.com/segiddins)
  [CocoaPods#4365](https://github.com/CocoaPods/CocoaPods/issues/4365)


## 0.39.0 (2015-10-09)

This version only introduces changes in the CocoaPods gem.


## 0.39.0.rc.1 (2015-10-05)

##### Enhancements

* Podfiles now have a `checksum` property that reflects the internal state of
  the Podfile.  
  [Samuel Giddins](https://github.com/segiddins)

* The Lockfile now contains the Podfile's checksum.  
  [Samuel Giddins](https://github.com/segiddins)


## 0.39.0.beta.5 (2015-10-01)

##### Breaking

* Activesupport 4 is now required, breaking compatibility with applications
  locked to `3.x.y`.  

##### Bug Fixes

* Fixes crash when using plugins where activesupport 4 was not installed.  
  [Delisa Mason](https://github.com/kattrali)
  [#266](https://github.com/CocoaPods/Core/pull/266)

##### Enhancements

* Add `tvos` as a new platform.  
  [Boris Bügling](https://github.com/neonichu)
  [Core#263](https://github.com/CocoaPods/Core/pull/263)


## 0.39.0.beta.4 (2015-09-02)

This version only introduces changes in the CocoaPods gem.


## 0.39.0.beta.3 (2015-08-28)

##### Bug Fixes

* This release fixes a file permissions error when using the RubyGem.  
  [Samuel Giddins](https://github.com/segiddins)


## 0.39.0.beta.2 (2015-08-27)

##### Bug Fixes

* Ensure all gem files are readable.  
  [Samuel Giddins](https://github.com/segiddins)
  [CocoaPods#4085](https://github.com/CocoaPods/CocoaPods/issues/4085)


## 0.39.0.beta.1 (2015-08-26)

##### Enhancements

* Gracefully handle missing root podspecs when auto-detecting.  
  [Hugo Tunius](https://github.com/k0nserv)
  [#3919](https://github.com/CocoaPods/CocoaPods/issues/3919)

* When comparing versions with unequal numbers of trailing zeros, the one with
  fewer zeros will only compare less than the other when they are otherwise
  equal.  
  [Gabriele Petronella](https://github.com/gabro)
  [cocoapods.org#185](https://github.com/CocoaPods/cocoapods.org/issues/185)

* Support converting objects of arbitrary classes to YAML.  
  [Samuel Giddins](https://github.com/segiddins)
  [CocoaPods#3907](https://github.com/CocoaPods/CocoaPods/issues/3907)

* Add a 'public_only' flag to linter results for warnings that are only
  appropriate for public specification.  
  [Samuel Giddins](https://github.com/segiddins)
  [#190](https://github.com/CocoaPods/Core/issues/190)
  [CocoaPods#2682](https://github.com/CocoaPods/CocoaPods/issues/2682)


## 0.38.2 (2015-07-25)

##### Bug Fixes

* The `major`, `minor`, and `patch` properties of versions will now always
  return a number.  
  [Samuel Giddins](https://github.com/segiddins)


## 0.38.1 (2015-07-23)

This version only introduces changes in the CocoaPods gem.


## 0.38.0 (2015-07-18)

This version only introduces changes in the CocoaPods gem.


## 0.38.0.beta.2 (2015-07-05)

##### Bug Fixes

* All string values written via the Podspec Ruby DSL will automatically have
  extraneous spaces stripped.  
  [Samuel Giddins](https://github.com/segiddins)
  [#239](https://github.com/CocoaPods/Core/issues/239)


## 0.38.0.beta.1 (2015-06-26)

##### Breaking

* Deprecate the `xcconfig` attribute in the Podspec DSL, which is replaced by
  the new attributes `pod_target_xcconfig` and `user_target_xcconfig`.  
  [Marius Rackwitz](https://github.com/mrackwitz)
  [CocoaPods#3465](https://github.com/CocoaPods/CocoaPods/issues/3465)

##### Enhancements

* Add support for specifying the CocoaPods version in the podspec.  
  [Daniel Tomlinson](https://github.com/DanielTomlinson)
  [Core#240](https://github.com/CocoaPods/Core/issues/240)

* Attempt to detect (and warn) when a podfile has smart quotes.  
  [Samuel Giddins](https://github.com/segiddins)

* Add `watchos` as a new platform.  
  [Boris Bügling](https://github.com/neonichu)
  [Core#249](https://github.com/CocoaPods/Core/pull/249)


## 0.37.2 (2015-05-27)

##### Enhancements

* A more useful DSLError will be shown when there are syntax errors in a Ruby
  Podfile or Podspec.  
  [Samuel Giddins](https://github.com/segiddins)
  [CocoaPods#2651](https://github.com/CocoaPods/CocoaPods/issues/2651)


## 0.37.1 (2015-05-06)

This version only introduces changes in the CocoaPods gem.


## 0.37.0 (2015-05-03)

This version only introduces changes in the CocoaPods gem.


## 0.37.0.rc.2 (2015-04-30)

This version only introduces changes in the CocoaPods gem.


## 0.37.0.rc.1 (2015-04-27)

##### Enhancements

* Only re-write lockfiles if they are changed, in an attempt to avoid exposing
  Psych serialization changes across Ruby versions.  
  [Samuel Giddins](https://github.com/segiddins)

##### Bug Fixes

* On case-insensitive HFS+ file systems, try to make queries for specs in
  spec repos to be case-preserved.  
  [Samuel Giddins](https://github.com/segiddins)
  [CocoaPods#2910](https://github.com/CocoaPods/CocoaPods/issues/2910)
  [CocoaPods#3024](https://github.com/CocoaPods/CocoaPods/issues/3024)


## 0.37.0.beta.1 (2015-04-18)

##### Enhancements

* Allow specifying multiple subspec pod dependencies inline in the Podfile,
  via `pod 'Pod', :subspecs => ['Subspec1', 'Subspec2']`.  
  [Samuel Giddins](https://github.com/segiddins)
  [#221](https://github.com/CocoaPods/Core/issues/221)

* Allow specifying a custom module map file.  
  [Samuel Giddins](https://github.com/segiddins)
  [Marius Rackwitz](https://github.com/mrackwitz)
  [#218](https://github.com/CocoaPods/Core/issues/218)

##### Bug Fixes

* The linter will now ensure that subspecs' names do not contain whitespace.  
  [Marius Rackwitz](https://github.com/mrackwitz)
  [Joshua Kalpin](https://github.com/Kapin)
  [Samuel Giddins](https://github.com/segiddins)
  [#177](https://github.com/CocoaPods/Core/issues/177)
  [#178](https://github.com/CocoaPods/Core/pull/178)
  [#202](https://github.com/CocoaPods/Core/pull/202)
  [#233](https://github.com/CocoaPods/Core/pull/233)

* The linter fails now if root attributes occur on subspec level.  
  [Marius Rackwitz](https://github.com/mrackwitz)
  [#233](https://github.com/CocoaPods/Core/pull/233)

* Inhibit warnings for pods that only have the `inhibit_warnings` option enabled
  on a subspec.  
  [Samuel Giddins](https://github.com/segiddins)
  [CocoaPods#2777](https://github.com/CocoaPods/CocoaPods/issues/2777)


## 0.36.4 (2015-04-16)

This version only introduces changes in the CocoaPods gem.


## 0.36.3 (2015-03-31)

This version only introduces changes in the CocoaPods gem.


## 0.36.2 (2015-03-31)

##### Enhancements

* DSL errors now show more context when errors such as `SyntaxError` are
  encountered.  
  [Samuel Giddins](https://github.com/segiddins)

##### Bug Fixes

* Allow a `Dependency` to be initialized with no non-nil external source
  key-value pairs and not be considered external.  
  [Samuel Giddins](https://github.com/segiddins)
  [CocoaPods#3320](https://github.com/CocoaPods/CocoaPods/issues/3320)


## 0.36.1 (2015-03-27)

##### Bug Fixes

* Ensure that strings that are serialized to YAML are escaped and quoted, if
  needed.  
  [Samuel Giddins](https://github.com/segiddins)
  [#213](https://github.com/CocoaPods/Core/issues/213)
  [CocoaPods/CocoaPods#2837](https://github.com/CocoaPods/CocoaPods/issues/2837)


## 0.36.0 (2015-03-11)

##### Bug Fixes

* The linter will no longer erroneously warn that a specification has been
  deprecated in favor of itself.  
  [Samuel Giddins](https://github.com/segiddins)
  [CocoaPods#3197](https://github.com/CocoaPods/CocoaPods/issues/3197)


## 0.36.0.rc.1 (2015-02-24)

##### Enhancements

* The linter now validates that every specification attribute is of the correct
  type.  
  [Samuel Giddins](https://github.com/segiddins)
  [#220](https://github.com/CocoaPods/Core/issues/220)
  [CocoaPods#2923](https://github.com/CocoaPods/CocoaPods/issues/2923)
  [CocoaPods#3134](https://github.com/CocoaPods/CocoaPods/issues/3134)

##### Bug Fixes

* Allow the `podspec` Podfile DSL flag to work with JSON podspecs.  
  [Samuel Giddins](https://github.com/segiddins)
  [#201](https://github.com/CocoaPods/Core/issues/201)
  [CocoaPods#2952](https://github.com/CocoaPods/CocoaPods/issues/2952)


## 0.36.0.beta.2 (2015-01-27)

This version only introduces changes in the CocoaPods gem.

## 0.36.0.beta.1 (2014-12-25)

##### Enhancements

* The Linter will now ensure against marking a spec as
  `deprecated_in_favor_of` itself.  
  [Keith Smiley](https://github.com/Keithbsmiley)
  [#212](https://github.com/CocoaPods/Core/pull/212)

* Added `module_name` attribute for use with frameworks.  
  [Boris Bügling](https://github.com/neonichu)
  [#205](https://github.com/CocoaPods/Core/issues/205)

* Evaluate a Specification in `.from_string` in the context of the directory
  the specification is in.  
  [Samuel Giddins](https://github.com/segiddins)
  [CocoaPods#2875](https://github.com/CocoaPods/CocoaPods/issues/2875)

* Added `use_frameworks!` flag to the Podfile DSL.  
  [Boris Bügling](https://github.com/neonichu)
  [Core#204](https://github.com/CocoaPods/Core/issues/204)

* Added `plugins` method to the Podfile DSL.  
  [Samuel Giddins](https://github.com/segiddins)

* Lint specifications authors, ensuring that they are neither empty nor the
  default.  
  [Samuel Giddins](https://github.com/segiddins)
  [#214](https://github.com/CocoaPods/Core/issues/214)

##### Bug Fixes

* Fixes the reading of dependencies that have spaces in their subspecs' name
  from Lockfiles.  
  [Samuel Giddins](https://github.com/segiddins)
  [CocoaPods#2850](https://github.com/CocoaPods/CocoaPods/issues/2850)

* The Linter will now give a warning if Github Gists begin with `www`  
  [Joshua Kalpin](https://github.com/Kapin)
  [Core#200](https://github.com/CocoaPods/Core/pull/200)

* Fixes handling of missing sub-subspecs in the resolver.  
  [Samuel Giddins](https://github.com/segiddins)
  [CocoaPods#2922](https://github.com/CocoaPods/CocoaPods/issues/2922)


## 0.35.0 (2014-11-19)

##### Enhancements

* Allow the specification of file patterns which require ARC with
  `requires_arc`.  
  [Kyle Fuller](https://github.com/kylef)
  [Samuel Giddins](https://github.com/segiddins)
  [CocoaPods#532](https://github.com/CocoaPods/CocoaPods/issues/532)

* Allow the specification of plugins and an optional hash of options
  for the plugin in the Podfile.  
  [Samuel Giddins](https://github.com/segiddins)


## 0.35.0.rc2 (2014-11-06)

This version only introduces changes in the CocoaPods gem.

## 0.35.0.rc1 (2014-11-02)

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


## 0.34.4 (2014-10-18)

##### Bug Fixes

* Fixes an issue linting options such as `type`, `sha1` for http sources in a
  podspec.
  [Kyle Fuller](https://github.com/kylef)
  [CocoaPods#2692](https://github.com/CocoaPods/CocoaPods/issues/2692)


## 0.34.2 (2014-10-08)

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


## 0.34.1 (2014-09-26)

##### Bug Fixes

* [Linter] Fix the license extension check.  
  [Fabio Pelosin](https://github.com/fabiopelosin)
  [CocoaPods#2525](https://github.com/CocoaPods/CocoaPods/issues/2525)


## 0.34.0 (2014-09-26)

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


## 0.34.0.rc2 (2014-09-16)

##### Bug Fixes

* Fixes an issue linting specifications with invalid HTTP source.  
  [Kyle Fuller](https://github.com/kylef)
  [CocoaPods#2463](https://github.com/CocoaPods/CocoaPods/issues/2463)

## 0.34.0.rc1 (2014-09-13)

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


## 0.33.1 (2014-05-20)

This version only introduces changes in the CocoaPods gem.

## 0.33.0 (2014-05-20)

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

## 0.32.1 (2014-04-15)
## 0.32.0 (2014-04-15)

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


## 0.31.1 (2014-04-01)

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

## 0.31.0 (2014-03-31)

##### Enhancements

* Changed all references to the optimistic operator.  
  [Luis de la Rosa](https://github.com/luisdelarosa)

* Check requires_arc set explicitly in podspec.  
  [Richard Lee](https://github.com/dlackty)

##### Bug Fixes

* Fix crash related to the usage of `s.version` in the git tag.  
  [Joel Parsons](https://github.com/joelparsons)

## 0.30.0 (2014-03-28)

Introduction of the Changelog.
