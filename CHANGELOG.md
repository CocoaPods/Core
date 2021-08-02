# CocoaPods Core Changelog

## Master

##### Enhancements

* Add `project_header_files` DSL to specifications.  
  [Dimitris Koutsogiorgas](https://github.com/dnkoutso)
  [#692](https://github.com/CocoaPods/Core/pull/692)

* Add support for `on_demand_resources` DSL.  
  [JunyiXie](https://github.com/JunyiXie)
  [Dimitris Koutsogiorgas](https://github.com/dnkoutso)
  [#690](https://github.com/CocoaPods/Core/pull/690)

* Add `before_headers` and `after_headers` execution position DSL.  
  [Dimitris Koutsogiorgas](https://github.com/dnkoutso)
  [#686](https://github.com/CocoaPods/Core/pull/686)

* Add a pre_integrate_hook API  
  [David Chavez](https://github.com/dcvz)
  [#643](https://github.com/CocoaPods/Core/pull/643)

* Allow version `0` to be used.  
  [Eloy Durán](https://github.com/alloy)
  [#657](https://github.com/CocoaPods/Core/pull/657)

* Update comments/docs to indicate `module_map=false` will skip `modulemap` file generation.  
  [Sergey Erokhin](https://github.com/till0xff)
  [#664](https://github.com/CocoaPods/Core/pull/664)

##### Bug Fixes

* Bump addressable dependency to 2.8.  
  [Dimitris Koutsogiorgas](https://github.com/dnkoutso)
  [#688](https://github.com/CocoaPods/Core/pull/688)


## 1.10.2 (2021-07-28)

##### Enhancements

* None.  

##### Bug Fixes

* None.  


## 1.10.1 (2021-01-07)

##### Enhancements

* None.  

##### Bug Fixes

* None.  


## 1.10.0 (2020-10-20)

##### Enhancements

* None.  

##### Bug Fixes

* None.  


## 1.10.0.rc.1 (2020-09-15)

##### Enhancements

* None.  

##### Bug Fixes

* None.  


## 1.10.0.beta.2 (2020-08-12)

##### Enhancements

* None.  

##### Bug Fixes

* None.  


## 1.10.0.beta.1 (2020-07-17)

##### Breaking

* Drop support for Ruby 2.0 and 2.2. Minimum required Ruby version is now 2.3.3 (included on macOS High Sierra)  
  [Eric Amorde](https://github.com/amorde)
  [CocoaPods#9821](https://github.com/CocoaPods/CocoaPods/issues/9821)

##### Enhancements

* Added `ensure_bundler!` flag to the Podfile DSL.  
  [Sean Reinhardt](https://github.com/seanreinhardtapps)
  [#9325](https://github.com/CocoaPods/CocoaPods/issues/9325)
  
* Add a post_integrate_hook API  
  [lucasmpaim](https://github.com/lucasmpaim)
  [#7432](https://github.com/CocoaPods/CocoaPods/issues/7432)

##### Bug Fixes

* None.  


## 1.9.3 (2020-05-29)

##### Enhancements

* None.  

##### Bug Fixes

* CDNSource - Run a rudimentary local check to help with CDN client robustness.  
  [Igor Makarov](https://github.com/igor-makarov)
  [#632](https://github.com/CocoaPods/Core/pull/632)
  [CocoaPods#9814](https://github.com/CocoaPods/CocoaPods/issues/9814)

## 1.9.2 (2020-05-22)

##### Enhancements

* None.  

##### Bug Fixes

* Fix a crash when JSON Podspec encoding is guessed incorrectly  
  [Jason Schroeder](https://github.com/jasonschroeder-sfdc)
  [#629](https://github.com/CocoaPods/Core/pull/629)

## 1.9.1 (2020-03-09)

##### Enhancements

* None.  

##### Bug Fixes

* None.  


## 1.9.0 (2020-02-25)

##### Enhancements

* None.  

##### Bug Fixes

* None.  


## 1.9.0.beta.3 (2020-02-04)

##### Enhancements

* None.  

##### Bug Fixes

* Fix a crash when an HTTP(S) response has no headers  
  [Eric Amorde](https://github.com/amorde)
  [#607](https://github.com/CocoaPods/Core/pull/607)


## 1.9.0.beta.2 (2019-12-17)

##### Enhancements

* None.  

##### Bug Fixes

* None.  


## 1.9.0.beta.1 (2019-12-16)

##### Enhancements

* Allow specifying no default subspec.  
  [Dimitris Koutsogiorgas](https://github.com/dnkoutso)
  [#584](https://github.com/CocoaPods/Core/issues/584)
  
* Add `code_coverage` support for scheme DSL.  
  [Dimitris Koutsogiorgas](https://github.com/dnkoutso)
  [#603](https://github.com/CocoaPods/Core/pull/603)
  [CocoaPods/CocoaPods#8921](https://github.com/CocoaPods/CocoaPods/issues/8921)

* Add `:configurations` DSL for podspec dependencies.  
  [Samuel Giddins](https://github.com/segiddins)
  [Dimitris Koutsogiorgas](https://github.com/dnkoutso)
  [#586](https://github.com/CocoaPods/Core/pull/586)

* Expand `use_frameworks!` DSL to accept linkage style.  
  [Dimitris Koutsogiorgas](https://github.com/dnkoutso)
  [#581](https://github.com/CocoaPods/Core/pull/581)

* Extend `script_phase` DSL to support dependency file.  
  [Dimitris Koutsogiorgas](https://github.com/dnkoutso)
  [#579](https://github.com/CocoaPods/Core/pull/579)
  
* Make initializing `Platform` with the string 'macos' equivalent to calling `Platform.macos`  
  [Eric Amorde](https://github.com/amorde)
  [#602](https://github.com/CocoaPods/Core/pull/602) 

##### Bug Fixes

* None.  


## 1.8.4 (2019-10-16)

##### Enhancements

* None.  

##### Bug Fixes

* None.  


## 1.8.3 (2019-10-04)

##### Enhancements

* None.  

##### Bug Fixes

* Follow up fix to [#595](https://github.com/CocoaPods/Core/pull/595) not to delete other hashes during serialization.  
  [Dimitris Koutsogiorgas](https://github.com/dnkoutso)
  [#598](https://github.com/CocoaPods/Core/pull/598)


## 1.8.2 (2019-10-03)

##### Enhancements

* None.  

##### Bug Fixes

* Ensure that specs can round-trip to JSON byte-for-byte identical.  
  [Samuel Giddins](https://github.com/segiddins)
  [#595](https://github.com/CocoaPods/Core/pull/595)


## 1.8.1 (2019-09-27)

##### Enhancements

* None.  

##### Bug Fixes

* Do not alter `swift_versions` attribute when calculating Swift versions.  
  [Dimitris Koutsogiorgas](https://github.com/dnkoutso)
  [#592](https://github.com/CocoaPods/Core/pull/592)

* Update `concurrent-ruby` gem dependency to '\~> 1.1'.  
  [Igor Makarov](https://github.com/igor-makarov)
  [#591](https://github.com/CocoaPods/Core/pull/591)


## 1.8.0 (2019-09-23)

##### Enhancements

* None.  

##### Bug Fixes

* None.  


## 1.8.0.beta.2 (2019-08-27)

##### Enhancements

* None.  

##### Bug Fixes

* None.  


## 1.8.0.beta.1 (2019-08-02)

##### Enhancements

* Add support for UI test specs with `test_type` value `:ui`  
  [Yavuz Nuzumlali](https://github.com/manuyavuz)
  [#562](https://github.com/CocoaPods/Core/pull/562)

* Don't `Dir.chdir` when loading `Pod::Specification` from JSON  
  [Igor Makarov](https://github.com/igor-makarov)
  [#565](https://github.com/CocoaPods/Core/pull/565)

* Replace git-based `MasterSource` with CDN-based `TrunkSource`  
  [Igor Makarov](https://github.com/igor-makarov)
  [#552](https://github.com/CocoaPods/Core/pull/552)

* Add Info.plist DSL to Specifications  
  [Eric Amorde](https://github.com/amorde)
  [CocoaPods/CocoaPods#8753](https://github.com/CocoaPods/CocoaPods/issues/8753)

* Add `project_name` DSL to allow grouping pods into projects.  
  [Dimitris Koutsogiorgas](https://github.com/dnkoutso)
  [#547](https://github.com/CocoaPods/Core/pull/547)

* Allow test specs to specify an `app_host_name` to point to an app spec whose
  application is used as the test's app host.  
  [jkap](https://github.com/jkap)
  [Samuel Giddins](https://github.com/segiddins)
  [#520](https://github.com/CocoaPods/Core/pull/520)

* Add `:headers` option to allow passing in custom headers to `cURL` when downloading source via the `:http` download strategy.  
  [Wilmar van Heerden](https://github.com/wilmarvh)
  [cocoapods-downloader#89](https://github.com/CocoaPods/cocoapods-downloader/issues/89)
  [#557](https://github.com/CocoaPods/Core/pull/557)

##### Bug Fixes

* Emit an error when a Podspec has an incorrect type for the `source` attribute  
  [Eric Amorde](https://github.com/amorde)
  [CocoaPods/CocoaPods#5420](https://github.com/CocoaPods/CocoaPods/issues/5420)

* Gracefully handle invalid version values during linting.  
  [Eric Amorde](https://github.com/amorde)
  [CocoaPods/CocoaPods#8785](https://github.com/CocoaPods/CocoaPods/issues/8785)

* Pass a non-browser user agent for social media validation  
  [Dov Frankel](https://github.com/abbeycode)
  [#571](https://github.com/CocoaPods/Core/pull/571)
  [CocoaPods#9053](https://github.com/CocoaPods/Cocoapods/pull/9053)
  [CocoaPods#9049](https://github.com/CocoaPods/CocoaPods/issues/9049)

## 1.7.5 (2019-07-19)

##### Enhancements

* None.  

##### Bug Fixes

* None.  


## 1.7.4 (2019-07-09)

##### Enhancements

* None.  

##### Bug Fixes

* Use URI escaping in `CDNSource`.  
  [Igor Makarov](https://github.com/igor-makarov)
  [#554](https://github.com/CocoaPods/Core/pull/554)
  [CocoaPods#8951](https://github.com/CocoaPods/CocoaPods/issues/8951)


## 1.7.3 (2019-06-28)

##### Enhancements

* CDNSource: Lower the thread pool limit to 50 and add an environment variable to override it.  
  [Igor Makarov](https://github.com/igor-makarov)
  [#551](https://github.com/CocoaPods/Core/pull/551)

* CDNSource: Improve the error messaging from multi-threaded code.  
  [Igor Makarov](https://github.com/igor-makarov)
  [#551](https://github.com/CocoaPods/Core/pull/551)

* CDNSource: Retry connection errors.  
  [Igor Makarov](https://github.com/igor-makarov)
  [#551](https://github.com/CocoaPods/Core/pull/551)

##### Bug Fixes

* None.  


## 1.7.2 (2019-06-13)

##### Enhancements

* CDNSource: Use a more compact, sharded index retrieving for the pod versions  
  [Igor Makarov](https://github.com/igor-makarov)
  [#541](https://github.com/CocoaPods/Core/pull/541)

##### Bug Fixes

* None.  


## 1.7.1 (2019-05-30)

##### Enhancements

* None.  

##### Bug Fixes

* None.  


## 1.7.0 (2019-05-22)

##### Enhancements

* None.  

##### Bug Fixes

* None.  


## 1.7.0.rc.2 (2019-05-15)

##### Enhancements

* None.  

##### Bug Fixes

* Ensure `swift_version` singular version is included in JSON representation.  
  [Dimitris Koutsogiorgas](https://github.com/dnkoutso)
  [#8635](https://github.com/CocoaPods/CocoaPods/issues/8635)


## 1.7.0.rc.1 (2019-05-02)

##### Enhancements

* None.  

##### Bug Fixes

* Fix a crash when searching for a compatible version of a Source that has a higher version requirement  
  [Eric Amorde](https://github.com/amorde)
  [#482](https://github.com/CocoaPods/Core/issues/482)


## 1.7.0.beta.3 (2019-03-27)

##### Enhancements

* None.  

##### Bug Fixes

* Fix linting a JSON podspec that contains test or app subspecs.
  This allows affected specs to be pushed to trunk.  
  [Samuel Giddins](https://github.com/segiddins)


## 1.7.0.beta.2 (2019-03-08)

##### Enhancements

* Add support for `xcfilelist` in `script_phase` DSL.  
  [Dimitris Koutsogiorgas](https://github.com/dnkoutso)
  [#517](https://github.com/CocoaPods/Core/pull/517)

##### Bug Fixes

* None.  


## 1.7.0.beta.1 (2019-02-22)

##### Enhancements

* Add documentation for the `:testspecs` option on the `pod` Podfile DSL  
  [Eric Amorde](https://github.com/amorde)
  [#506](https://github.com/CocoaPods/Core/issues/506)

* Better error messages, if unallowed version requirement is specified in Podspec.  
  [Wolfgang Lutz](https://github.com/lutzifer)
  [#466](https://github.com/CocoaPods/Core/pull/474)

* DSL for `scheme` support.  
  [Dimitris Koutsogiorgas](https://github.com/dnkoutso)
  [#7577](https://github.com/CocoaPods/CocoaPods/issues/7577)
  [#479](https://github.com/CocoaPods/Core/pull/479)

* Replace `test_only` attribute option with `spec_types`.  
  [Dimitris Koutsogiorgas](https://github.com/dnkoutso)
  [#470](https://github.com/CocoaPods/Core/pull/470)

* Windows support - do not use fork when updating the index  
  [David Airapetyan](https://github.com/davidair)
  [#466](https://github.com/CocoaPods/Core/pull/466)

##### Bug Fixes

* Fix several array sorting inconsistencies when generating a Lockfile.  
  When a Lockfile is being written to disk, `YAMLHelper` sorts arrays by `&:downcase`.  
  When a new Lockfile is generated, the sort order is plain lexicographical.  
  This causes pods like `GoogleSignIn` and `GTMSessionFetcher` being in a different order in each case, causing `--deployment` to report an error when in fact the Lockfile wouldn't be changed.  
  [Igor Makarov](https://github.com/igor-makarov)

* Fix a crash when using `inhibit_all_warnings!` in parent and child scopes  
  [Eric Amorde](https://github.com/amorde)
  [#472](https://github.com/CocoaPods/Core/issues/472)


## 1.6.2 (2019-05-15)

##### Enhancements

* None.  

##### Bug Fixes

* Ensure `test_type` value is converted to a symbol from consumers of JSON podspecs.  
  [Dimitris Koutsogiorgas](https://github.com/dnkoutso)
  [#504](https://github.com/CocoaPods/Core/pull/504)


## 1.6.1 (2019-02-21)

##### Enhancements

* None.  

##### Bug Fixes

* None.  


## 1.6.0 (2019-02-07)

##### Enhancements

* None.  

##### Bug Fixes

* None.  

## 1.6.0.rc.2 (2019-01-29)

##### Enhancements

* None.  

##### Bug Fixes

* None.  


## 1.6.0.rc.1 (2019-01-25)

##### Enhancements

* None.  

##### Bug Fixes

* None.  


## 1.6.0.beta.2 (2018-10-17)

##### Enhancements

* Add support for specifying subspecs when using the `podspec` Podfile attribute  
  [Whirlwind](https://github.com/whirlwind)
  [#456](https://github.com/CocoaPods/Core/pull/456)

##### Bug Fixes

* Fix docstring for Pod::Podfile.from_yaml  
  [Jenn Kaplan](https://github.com/jkap)
  [#459](https://github.com/CocoaPods/Core/pull/459)


## 1.6.0.beta.1 (2018-08-16)

##### Enhancements

* None.  

##### Bug Fixes

* Cache result of `Specification#checksum` and `Podfile#checksum` methods  
  [Dimitris Koutsogiorgas](https://github.com/dnkoutso)
  [CocoaPods#7854](https://github.com/CocoaPods/CocoaPods/issues/7854)


## 1.5.3 (2018-05-25)

##### Enhancements

* Update docs to include per-pod `:modular_headers` option.  
  [Eric Amorde](https://github.com/amorde)

##### Bug Fixes

* None.  


## 1.5.2 (2018-05-09)

##### Enhancements

* None.  

##### Bug Fixes

* Fix using `TargetDefinition` objects as hash keys.  
  [Samuel Giddins](https://github.com/segiddins)


## 1.5.1 (2018-05-07)

##### Enhancements

* None.  

##### Bug Fixes

* Always lower case spec repo URL for 'SPEC REPOS'  
  [Dimitris Koutsogiorgas](https://github.com/dnkoutso)
  [CocoaPods#7586](https://github.com/CocoaPods/CocoaPods/issues/7586)

* Calling `Specification#dup` will set the parent for subspecs to be 
  the new object.  
  [Samuel Giddins](https://github.com/segiddins)

* Podfile objects are equatable.  
  [Samuel Giddins](https://github.com/segiddins)

* Stably sort arrays being serialized into YAML.
  [Samuel Giddins](https://github.com/segiddins)


## 1.5.0 (2018-04-04)

##### Enhancements

* None.  

##### Bug Fixes

* None.  

## 1.5.0.beta.1 (2018-03-23)

##### Enhancements

* Add ability to lockfile to retrieve spec repo for pod name  
  [Dimitris Koutsogiorgas](https://github.com/dnkoutso)
  [#434](https://github.com/CocoaPods/Core/pull/434)

* `HTTP::perform_head_request` now includes a 1-byte `Range` header in the fallback GET
  request.
  [Kyle Fleming](https://github.com/kylefleming)
  [#425](https://github.com/CocoaPods/Core/pull/425)

* Update Podfile Reference Guide to include `:source` parameter for the `pod` statement  
  [Mark Woollard](https://github.com/mwoollard)
  [#7359](https://github.com/CocoaPods/CocoaPods/issues/7359)

* Allow enabling modular headers for pods in the Podfile.  
  [Samuel Giddins](https://github.com/segiddins)
  
##### Bug Fixes

* Fix crash when there's an empty source spec directory  
  [Paul Beusterien](https://github.com/paulb777)
  [CocoaPods#6381](https://github.com/CocoaPods/CocoaPods/issues/6381)

* The `Dependency#merge` method takes into account any `podspec_repo`s the dependencies
  may have set.  
  [Samuel Giddins](https://github.com/segiddins)

* When evaluating `.podspec` files, ensure that `__FILE__` refers to the correct file.  
  [Samuel Giddins](https://github.com/segiddins)

* Serialize lockfiles that contain Pods with non-alphanumeric characters 
  (such as `!`) properly.  
  [Samuel Giddins](https://github.com/segiddins)
  [CocoaPods#7302](https://github.com/CocoaPods/CocoaPods/issues/7302)


## 1.4.0 (2018-01-18)

##### Enhancements

* None.  

##### Bug Fixes

* None.  


## 1.4.0.rc.1 (2017-12-16)

##### Enhancements

* Add `swift_version` DSL  
  [Danielle Tomlinson](https://github.com/dantoml)
  [Dimitris Koutsogiorgas](https://github.com/dnkoutso)
  [#417](https://github.com/CocoaPods/Core/pull/417)

##### Bug Fixes

* None.  


## 1.4.0.beta.2 (2017-10-24)

##### Enhancements

* Add podspec `script_phases` DSL
  [Dimitris Koutsogiorgas](https://github.com/dnkoutso)
  [#413](https://github.com/CocoaPods/Core/pull/413)

* Update commments/docs to indicate prefix_header=false will skip pch generation  
  [Paul Beusterien](https://github.com/paulb777)
  [#412](https://github.com/CocoaPods/Core/pull/412)

##### Bug Fixes

* Fix typo when validating cocoapods version  
  [Dimitris Koutsogiorgas](https://github.com/dnkoutso)
  [#418](https://github.com/CocoaPods/Core/pull/418)

* Improve performance of `Pod::Source#search`  
  [Dimitris Koutsogiorgas](https://github.com/dnkoutso)
  [#416](https://github.com/CocoaPods/Core/pull/416)

## 1.4.0.beta.1 (2017-09-24)

##### Enhancements

* Fix requirements cloning for `:testspecs`  
  [Justin Martin](https://github.com/justinseanmartin)
  [#401](https://github.com/CocoaPods/Core/pull/401)

* Add Podfile DSL for `script_phase`  
  [Dimitris Koutsogiorgas](https://github.com/dnkoutso)
  [#389](https://github.com/CocoaPods/Core/pull/389)

* Add `requires_app_host` DSL attribute  
  [Dimitris Koutsogiorgas](https://github.com/dnkoutso)
  [#399](https://github.com/CocoaPods/Core/pull/399)

* Introduce `static_framework` podspec attribute
  [Paul Beusterien](https://github.com/paulb777)
  [#386](https://github.com/CocoaPods/Core/pull/386)

##### Bug Fixes

* Provide a better error message when encountering empty spec directories  
  [David Airapetyan](https://github.com/davidair)
  [#5184](https://github.com/CocoaPods/CocoaPods/issues/5184)


## 1.3.1 (2017-08-06)

##### Enhancements

* Introduce `static_framework` podspec attribute
  [Paul Beusterien](https://github.com/paulb777)
  [#386](https://github.com/CocoaPods/Core/pull/386)

##### Bug Fixes

* Split testspecs from subspecs during JSON serialization  
  [Dimitris Koutsogiorgas](https://github.com/dnkoutso)
  [#398](https://github.com/CocoaPods/Core/pull/398)

* Fix JSON deserialization for test specs  
  [Dimitris Koutsogiorgas](https://github.com/dnkoutso)
  [#396](https://github.com/CocoaPods/Core/pull/396)


## 1.3.0 (2017-08-02)

##### Enhancements

* None.  

##### Bug Fixes

* None.  


## 1.3.0.rc.1 (2017-07-27)

##### Enhancements

* None.  

##### Bug Fixes

* None.  


## 1.3.0.beta.3 (2017-07-19)

##### Enhancements

* None.  

##### Bug Fixes

* Check requires_arc for true/false strings
  [Vinay Guthal](https://github.com/VinayGuthal)
  [#393](https://github.com/CocoaPods/Core/pull/393)

## 1.3.0.beta.2 (2017-06-22)

##### Enhancements

* None.  

##### Bug Fixes

* Cleanup DSL for `spec.source` - remove mentioning of `:path`.  
  [Maksym Komarychev](https://github.com/maxkomarychev)
  [#388](https://github.com/CocoaPods/Core/pull/388)


## 1.3.0.beta.1 (2017-06-06)

##### Enhancements

* Introduce `test_specification` DSL  
  [Dimitris Koutsogiorgas](https://github.com/dnkoutso)
  [Kyle Fuller](https://github.com/kylef)
  [#369](https://github.com/CocoaPods/Core/pull/369)

* Allow the use of `macos` in place of `osx` as a platform name.  
  [Samuel Giddins](https://github.com/segiddins)

##### Bug Fixes

* Cache target definition label value  
  [Dimitris Koutsogiorgas](https://github.com/dnkoutso)
  [#387](https://github.com/CocoaPods/Core/pull/387)

* Cache version result for each pod and segments  
  [Dimitris Koutsogiorgas](https://github.com/dnkoutso)
  [#385](https://github.com/CocoaPods/Core/pull/385)

* Correctly include parent dependencies when parsing testspecs  
  [Dimitris Koutsogiorgas](https://github.com/dnkoutso)
  [#384](https://github.com/CocoaPods/Core/pull/384)

* Fix typo in `specification.rb`  
  [Dimitris Koutsogiorgas](https://github.com/dnkoutso)
  [#376](https://github.com/CocoaPods/Core/pull/376)
  
* Fix Strange quotation marks in `lockfile.rb`  
  [Dacaiguoguo](https://github.com/dacaiguoguogmail)
  [#381](https://github.com/CocoaPods/Core/pull/381) 

## 1.2.1 (2017-04-11)

##### Enhancements

* None.  

##### Bug Fixes

* None.  


## 1.2.1.rc.1 (2017-04-05)

##### Enhancements

* None.  

##### Bug Fixes

* None.  


## 1.2.1.beta.1 (2017-03-08)

##### Enhancements

* None.  

##### Bug Fixes

* None.  


## 1.2.0 (2017-01-28)

##### Enhancements

* None.  

##### Bug Fixes

* None.  


## 1.2.0.rc.1 (2017-01-13)

##### Enhancements

* None.  

##### Bug Fixes

* Prevent crashing When a `Specification` has a `description` but no `summary`.  
  [Danielle Tomlinson](https://github.com/dantoml)
  [#6360](https://github.com/CocoaPods/CocoaPods/issues/6360)


## 1.2.0.beta.3 (2016-12-28)

##### Enhancements

* None.  

##### Bug Fixes

* Fix handling of version numbers in specifications.  
  [Danielle Tomlinson](https://github.com/dantoml)
  [#363](https://github.com/CocoaPods/Core/pull/363)

## 1.2.0.beta.2 (2016-12-17)

##### Enhancements

* Improve dependency resolution performance by caching specification hashes.  
  [Dimitris Koutsogiorgas](https://github.com/dnkoutso)
  [#5180](https://github.com/CocoaPods/CocoaPods/issues/5180)

* Add support for version metadata as specified by http://semver.org/#spec-item-10.  
  [Danielle Tomlinson](https://github.com/dantoml)
  [#6224](https://github.com/CocoaPods/CocoaPods/issues/6224)

##### Bug Fixes

* Raise an error if `inherit!` is used on an abstract target.  
  [Dimitris Koutsogiorgas](https://github.com/dnkoutso)
  [#5342](https://github.com/CocoaPods/CocoaPods/issues/5342)


## 1.2.0.beta.1 (2016-10-28)

##### Enhancements

* None.  

##### Bug Fixes

* None.  


## 1.1.1 (2016-10-20)

##### Enhancements

* None.  

##### Bug Fixes

* None.  


## 1.1.0 (2016-10-19)

##### Enhancements

* None.  

##### Bug Fixes

* None.  


## 1.1.0.rc.3 (2016-10-10)

##### Enhancements

* None.  

##### Bug Fixes

* None.  


## 1.1.0.rc.2 (2016-09-13)

##### Enhancements

* None.  

##### Bug Fixes

* None.  


## 1.1.0.rc.1 (2016-09-10)

##### Enhancements

* None.  

##### Bug Fixes

* Use `git -C` rather than `Dir.chdir`.  
  [Ben Asher](https://github.com/benasher44)
  [#352](https://github.com/CocoaPods/Core/pull/352)


## 1.1.0.beta.2 (2016-08-30)

##### Enhancements

* Improved comparison between Semver pre-release versions.  
  [Ben Asher](https://github.com/benasher44)
  [#350](https://github.com/CocoaPods/Core/pull/350)

##### Bug Fixes

* None.  


## 1.1.0.beta.1 (2016-07-11)

##### Enhancements

* Improved warning message for the renaming of `xcodeproj` to `project` in the `Podfile` DSL.  
  [Olivier Halligon](https://github.com/AliSoftware)
  [#327](https://github.com/CocoaPods/Core/pull/327)

* Improved documentation of the `deployment_target` attribute in the `Podspec` DSL.  
  [Olivier Halligon](https://github.com/AliSoftware)
  [#329](https://github.com/CocoaPods/Core/pull/329)

* Add missing space to not-found message.  
  [Boris Bügling](https://github.com/neonichu)
  [#330](https://github.com/CocoaPods/Core/pull/330)

* Specifying a `platform` twice for the same target in a Podfile raises a
  helpful error.  
  [Samuel Giddins](https://github.com/segiddins)
  [#328](https://github.com/CocoaPods/Core/issues/328)

* Specifying multiple `post_install` hooks in a Podfile raises an error.  
  [Daniel Tomlinson](https://github.com/dantoml)
  [#334](https://github.com/CocoaPods/Core/pull/334)

##### Bug Fixes

* None.  


## 1.0.1 (2016-06-01)

##### Enhancements

* None.  

##### Bug Fixes

* Fixed path checking for case-insensitive filesystems.  
  [Coder-256](https://github.com/Coder-256)
  [CocoaPods#5039](https://github.com/CocoaPods/CocoaPods/issues/5039)

* Fail more gracefully when a Podfile includes `pod pod 'Dependency'`.  
  [Samuel Giddins](https://github.com/segiddins)
  [CocoaPods#5379](https://github.com/CocoaPods/CocoaPods/issues/5379)


## 1.0.0 (2016-05-10)

##### Enhancements

* None.  

##### Bug Fixes

* None.  


## 1.0.0.rc.2 (2016-05-04)

##### Enhancements

* None.  

##### Bug Fixes

* Allow inheriting from a parent target definition that is abstract without a
  platform set.  
  [Samuel Giddins](https://github.com/segiddins)
  [CocoaPods#5242](https://github.com/CocoaPods/CocoaPods/issues/5242)


## 1.0.0.rc.1 (2016-04-30)

##### Enhancements

* Improve error message on MasterSource networking errors.  
  [Daniel Tomlinson](https://github.com/DanielTomlinson)
  [CocoaPods#5175](https://github.com/CocoaPods/CocoaPods/issues/5175)

##### Bug Fixes

* Root attributes are inherited by default.  
  [Samuel Giddins](https://github.com/segiddins)
  [CocoaPods#5177](https://github.com/CocoaPods/CocoaPods/issues/5177)


## 1.0.0.beta.8 (2016-04-15)

##### Enhancements

* None.  

##### Bug Fixes

* None.  


## 1.0.0.beta.7 (2016-04-15)

##### Enhancements

* Add support for sharded `Specs` directories in a source.  
  [Samuel Giddins](https://github.com/segiddins)
  [CocoaPods#5002](https://github.com/CocoaPods/CocoaPods/issues/5002)

* Migrate the `Pod::SourcesManager` singleton to be the `Pod::Source::Manager`
  class.  
  [Samuel Giddins](https://github.com/segiddins)

* Add support for specifying a list of tags in a source for breaking backwards
  compatibility with old CocoaPods versions.  
  [Samuel Giddins](https://github.com/segiddins)
  [CocoaPods#5002](https://github.com/CocoaPods/CocoaPods/issues/5002)

##### Bug Fixes

* Allow the master specs repo to be cloned using a `git://` URL.  
  [Samuel Giddins](https://github.com/segiddins)
  [CocoaPods#5062](https://github.com/CocoaPods/CocoaPods/issues/5062)

* Appending to an existing search index will now make new pods visible via
  search.  
  [Muhammed Yavuz Nuzumlalı](https://github.com/manuyavuz)
  [CocoaPods#5031](https://github.com/CocoaPods/CocoaPods/issues/5031)


## 1.0.0.beta.6 (2016-03-15)

##### Enhancements

* Add `MasterSource` and refactor `Source::Aggregate` to be setup with
  `Array<Source>`.  
  [Daniel Tomlinson](https://github.com/DanielTomlinson)
  [CocoaPods#5005](https://github.com/CocoaPods/CocoaPods/issues/5005)

##### Bug Fixes

* None.  


## 1.0.0.beta.5 (2016-03-08)

##### Enhancements

* Allow a specification's root attributes to be accessible from a `consumer`.  
  [Samuel Giddins](https://github.com/segiddins)

##### Bug Fixes

* Allow search paths target inheritance when the parent is the target definition
  with `inherit! :search_paths`.  
  [Samuel Giddins](https://github.com/segiddins)
  [#4943](https://github.com/CocoaPods/CocoaPods/issues/4943)

* Ensure `Podfile.lock`s won't be generated with extraneous `>-` tokens in
  their YAML.  
  [Samuel Giddins](https://github.com/segiddins)
  [CocoaPods#4740](https://github.com/CocoaPods/CocoaPods/issues/4740)

* Make a spec's custom `module_map` accessible from a `consumer` in a
  multi-platform compatible manner.  
  [Samuel Giddins](https://github.com/segiddins)


## 1.0.0.beta.4 (2016-02-24)

##### Enhancements

* The linter rejects `default_subspecs` defined in subspecs of podspecs.
  They were never taken into account for subspecs.  
  [Marius Rackwitz](https://github.com/mrackwitz)
  [Core#305](https://github.com/CocoaPods/Core/pull/305)

##### Bug Fixes

* Specification platform proxies (e.g. `spec.ios` or `spec.osx`) will raise more
  informative errors when trying to set non-multiplatform attributes.  
  [Samuel Giddins](https://github.com/segiddins)


## 1.0.0.beta.3 (2016-02-03)

##### Breaking

* The `xcodeproj` Podfile DSL method has been renamed to `project`.  
  [Marius Rackwitz](https://github.com/mrackwitz)
  [Core#298](https://github.com/CocoaPods/Core/issues/298)

##### Enhancements

* Add the ability to disable inhibiting warnings per pod.  
  Now `:inhibit_warnings => false` option can be used in podfile to disable
  inhibition for specific pods.  
  [Muhammed Yavuz Nuzumlalı](https://github.com/manuyavuz)

##### Bug Fixes

* Fix accessing `use_frameworks?` without accidentally clearing the value when
  it was explicitly set to `false`, so that it would be evaluated as `true` on
  the next access.  
  [Marius Rackwitz](https://github.com/mrackwitz)
  [Core#301](https://github.com/CocoaPods/Core/pull/301)

* Fix parsing of dependencies created from a string that includes the `HEAD`
  specifier and version information.  
  [Muhammed Yavuz Nuzumlalı](https://github.com/manuyavuz)
  [CocoaPods#4710](https://github.com/CocoaPods/CocoaPods/issues/4710)


## 1.0.0.beta.2 (2016-01-05)

##### Enhancements

* Dependencies created from a string that use the `HEAD` specifier are properly
  parsed, ignoring the obsolete specifier.  
  [Samuel Giddins](https://github.com/segiddins)
  [CocoaPods#4710](https://github.com/CocoaPods/CocoaPods/issues/4710)

##### Bug Fixes

* Fix specifying `configuration(s)` for a pod inside a target block.   
  [Samuel Giddins](https://github.com/segiddins)
  [CocoaPods#4707](https://github.com/CocoaPods/CocoaPods/issues/4707)


## 1.0.0.beta.1 (2015-12-30)

##### Breaking

* The `link_with` Podfile DSL method has been removed in favor of target
  inheritance.  
  [Samuel Giddins](https://github.com/segiddins)

* The `:exclusive => true` Podfile DSL target option has been removed in favor
  of the `inherit! :search_paths` directive.  
  [Samuel Giddins](https://github.com/segiddins)

* The specification of `:head` dependencies has been removed.  
  [Samuel Giddins](https://github.com/segiddins)

* The deprecated `:local` dependency option has been removed in favor of the
  equivalent `:path` option.  
  [Samuel Giddins](https://github.com/segiddins)

* The deprecated `dependency` method in the Podfile DSL has been removed in
  favor of the equivalent `pod` method.  
  [Samuel Giddins](https://github.com/segiddins)

* The deprecated `preferred_dependency` method in the Specification DSL has been
  removed in favor of the equivalent `default_subspecs` method.  
  [Samuel Giddins](https://github.com/segiddins)

* The `docset_url` Specification attribute has been removed.  
  [Samuel Giddins](https://github.com/segiddins)
  [#284](https://github.com/CocoaPods/Core/issues/284)

##### Enhancements

* Add support for specifying :source with a pod dependency.  
  [Eric Firestone](https://github.com/efirestone)
  [#278](https://github.com/CocoaPods/Core/pull/278)

* Add ability to get all platforms.  
  [Muhammed Yavuz Nuzumlalı](https://github.com/manuyavuz)
  [cocoapods-search#11](https://github.com/CocoaPods/cocoapods-search/issues/11)

* Improve `pod search` performance while using _`--full`_ flag.  
  [Muhammed Yavuz Nuzumlalı](https://github.com/manuyavuz)
  [cocoapods-search#8](https://github.com/CocoaPods/cocoapods-search/issues/8)

* The Lockfile now contains the Podfile's checksum.  
  [Samuel Giddins](https://github.com/segiddins)

* The serialized version of podspecs now includes the default platforms a pod
  supports for improved forwards compatibility.  
  [Samuel Giddins](https://github.com/segiddins)
  [#267](https://github.com/CocoaPods/Core/issues/267)

* The Podfile now allows specifying installation options via the `install!`
  directive.  
  [Samuel Giddins](https://github.com/segiddins)
  [#151](https://github.com/CocoaPods/Core/issues/151)

* The Podfile now allows marking targets as `abstract` and specifying the pod
  inheritance mode via the `inherit!` directive.  
  [Samuel Giddins](https://github.com/segiddins)

##### Bug Fixes

* Allow non-exact version matches to be equal while maintaining a sort order.  
  [Samuel Giddins](https://github.com/segiddins)
  [CocoaPods#4365](https://github.com/CocoaPods/CocoaPods/issues/4365)

* Target definitions now inherit configuration whitelist settings.  
  [Samuel Giddins](https://github.com/segiddins)
  [CocoaPods#3605](https://github.com/CocoaPods/CocoaPods/issues/3605)

* Ensure that YAML serialization doesn't incorrectly break long strings.  
  [Christopher Vollick](https://github.com/psycotica0)


## 0.39.0 (2015-10-09)

This version only introduces changes in the CocoaPods gem.


## 0.39.0.rc.1 (2015-10-05)

##### Enhancements

* Podfiles now have a `checksum` property that reflects the internal state of
  the Podfile.  
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
