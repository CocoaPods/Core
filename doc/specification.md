
# Podspec attributes

## Overview

#### Root specification attributes

A ‘root’ specification is a specification that holds other
‘sub-specifications’.

These attributes can only be written to on the ‘root’ specification,
**not** on the ‘sub-specifications’.

<table>
  <tr>
    <td><a href='#name'>name</a></td>
    <td><a href='#version'>version</a></td>
    <td><a href='#authors'>authors</a></td>
  </tr>
  <tr>
    <td><a href='#license'>license</a></td>
    <td><a href='#homepage'>homepage</a></td>
    <td><a href='#source'>source</a></td>
  </tr>
  <tr>
    <td><a href='#summary'>summary</a></td>
    <td><a href='#description'>description</a></td>
    <td><a href='#documentation'>documentation</a></td>
  </tr>
  <tr>
  </tr>
</table>

#### Platform attributes

<table>
  <tr>
    <td><a href='#platform'>platform</a></td>
    <td><a href='#deployment_target'>deployment_target</a></td>
  </tr>
</table>

#### File pattern attributes

These should be specified relative to the root of the source root and
may contain [wildcard patterns](http://apidock.com/ruby/Dir/glob/class).

<table>
  <tr>
    <td><a href='#source_files'>source_files</a></td>
    <td><a href='#exclude_source_files'>exclude_source_files</a></td>
    <td><a href='#public_header_files'>public_header_files</a></td>
  </tr>
  <tr>
    <td><a href='#resources'>resources</a></td>
    <td><a href='#preserve_paths'>preserve_paths</a></td>
  </tr>
</table>

#### Dependencies & Subspecs

<table>
  <tr>
    <td><a href='#subspec'>subspec</a></td>
    <td><a href='#preferred_dependency'>preferred_dependency</a></td>
    <td><a href='#dependency'>dependency</a></td>
  </tr>
  <tr>
  </tr>
</table>

## Root specification attributes

A ‘root’ specification is a specification that holds other
‘sub-specifications’.

These attributes can only be written to on the ‘root’ specification,
**not** on the ‘sub-specifications’.
#### name
[Required] The name of the Pod.

###### Examples

```ruby
spec.name = 'AFNetworking'
```

#### version
[Required] The version of the Pod. CocoaPods follows
[semantic versioning](http://semver.org).

###### Examples

```ruby
spec.version = '0.0.1'
```

#### authors
[Required] The name and email address of each of the library’s the authors.

###### Examples

```ruby
spec.author = 'Darth Vader'
```

```ruby
spec.authors = 'Darth Vader', 'Wookiee'
```

```ruby
spec.authors = { 'Darth Vader' => 'darthvader@darkside.com',
                 'Wookiee'     => 'wookiee@aggrrttaaggrrt.com' }
```

#### license
[Required] The license of the Pod.

Unless the source contains a file named `LICENSE.*` or `LICENCE.*`, the
path of the license file _or_ license text must be specified.

This attribute supports the following keys: `type`, `file`, `text`.

###### Examples

```ruby
spec.license = 'MIT'
```

```ruby
spec.license = { :type => 'MIT', :file => 'MIT-LICENSE.txt' }
```

```ruby
spec.license = { :type => 'MIT', :text => <<-LICENSE
                   Copyright 2012
                   Permission is granted to...
                 LICENSE
               }
```

#### homepage
[Required] The URL of the homepage of the Pod.

###### Examples

```ruby
spec.homepage = 'www.example.com'
```

#### source
[Required] The location from where the library should be retrieved.

This attribute supports the following keys: 
- `git`: `tag`, `branch`, `commit`, `submodules`

- `svn`: `folder`, `tag`, `revision`

- `hg`: `revision`

- `http`
###### Examples

```ruby
spec.source = { :git => "git://github.com/AFNetworking/AFNetworking.git" }
```

```ruby
spec.source = { :git => "git://github.com/AFNetworking/AFNetworking.git",
                        :tag => 'v0.0.1' }
```

```ruby
spec.source = { :git => "git://github.com/AFNetworking/AFNetworking.git",
                :tag => "v#{spec.version}" }
```

#### summary
[Required] A short description of the Pod. It should have a maximum of 140
characters.

###### Examples

```ruby
spec.summary = 'A library that computes the meaning of life.'
```

#### description
 A (optional) longer description of the Pod.

###### Examples

```ruby
spec.description = <<-DESC
                     A library that computes the meaning of life. Features:
                     1. Is self aware
                     ...
                     42. Likes candies.
                   DESC
```

#### documentation
 Additional options to pass to the
[appledoc](http://gentlebytes.com/appledoc/) tool.

###### Examples

```ruby
spec.documentation = { :appledoc => ['--no-repeat-first-par',
                                     '--no-warn-invalid-crossref'] }
```


## Platform attributes
#### platform
 The platform on which this Pod is supported.

Leaving this blank means the Pod is supported on all platforms.

###### Examples

```ruby
spec.platform = :ios
```

```ruby
spec.platform = :osx
```

```ruby
spec.platform = :osx, "10.8"
```

#### deployment\_target
 The deployment targets of the supported platforms.

This attribute supports multi-platform values.

###### Examples

```ruby
spec.ios.deployment_target = "6.0"
```

```ruby
spec.osx.deployment_target = "10.8"
```


## File pattern attributes

These should be specified relative to the root of the source root and
may contain [wildcard patterns](http://apidock.com/ruby/Dir/glob/class).
#### source\_files
 The source files of the Pod.

This attribute supports multi-platform values.

###### Examples

```ruby
spec.source_files = "Classes/**/*.{h,m}"
```

```ruby
spec.source_files = "Classes/**/*.{h,m}", "More_Classes/**/*.{h,m}"
```

#### exclude\_source\_files
 A pattern of files that should be excluded from the source files.

This attribute supports multi-platform values.

###### Examples

```ruby
"Classes/osx"
```

```ruby
"Classes/**/unused.{h,m}"
```

#### public\_header\_files
 A pattern of files that should be used as public headers.

This attribute supports multi-platform values.

###### Examples

```ruby
"Resources/*.png"
```

#### resources
 A list of resources. These are copied into the target bundle with a
build phase script.

This attribute supports multi-platform values.

###### Examples

```ruby
"Resources/*.png"
```

#### preserve\_paths
 Any file that should not be cleaned (CocoaPods cleans all the unused
files by default).

This attribute supports multi-platform values.

###### Examples

```ruby
"IMPORTANT.txt"
```


## Dependencies & Subspecs
#### subspec
 Specification for a module of the Pod. A specification automaically
iherits as a dependency all it children subspecs.

Subspec also inherits values from their parents so common values for
attributes can be specified in the ancestors.

This attribute supports multi-platform values.

###### Examples

```ruby
subspec "core" do |sp|
  sp.source_files = "Classes/Core"
end

subspec "optional" do |sp|
  sp.source_files = "Classes/BloatedClassesThatNobodyUses"
end
```

```ruby
subspec "Subspec" do |sp|
  sp.subspec "resources" do |ssp|
  end
end
```

#### preferred\_dependency
 The name of the subspec that should be used as preferred dependency.
This is useful in case there are incompatible subspecs or a subspec
provides components that are rarely used.

This attribute supports multi-platform values.

###### Examples

```ruby
'Pod/default_subspec'
```

#### dependency
 

This attribute supports multi-platform values.

###### Examples
