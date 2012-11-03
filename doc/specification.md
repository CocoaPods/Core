
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

```
s.name = 'MyPod'
```

#### version
[Required] The version of the Pod (see [Semver](http://semver.org)).

###### Examples

```
s.version = '0.0.1'
```

#### authors
[Required] The email and the name of the authors of the library.

###### Examples

```
s.authors = 'Darth Vader'
```

```
s.authors = 'Darth Vader', 'Wookiee'
```

```
s.authors = { 'Darth Vader' => 'darthvader@darkside.com',
              'Wookiee' => 'wookiee@aggrrttaaggrrt.com' }
```

#### license
[Required] The license of the Pod, unless the source contains a file named
`LICENSE.*` or `LICENCE.*` the path of the file containing the license
or the text of the license should be specified.

This attribute supports the following keys: `type`, `file`, `text`.

###### Examples

```
s.license = 'MIT'
```

```
s.license = { :type => 'MIT', :file => 'MIT-LICENSE.txt' }
```

```
s.license = { :type => 'MIT', :text => <<-LICENSE
                Copyright 2012
                Permission is granted to...
              LICENSE
            }
```

#### homepage
[Required] The URL of the homepage of the Pod.

###### Examples

```
s.homepage = 'www.example.com'
```

#### source
[Required] The location from where the library should be retrieved.

This attribute supports the following keys: 
- `git`: `tag`, `branch`, `commit`, `submodules`

- `svn`: `folder`, `tag`, `revision`

- `hg`: `revision`

- `http`
###### Examples

```
s.source = :git => www.example.com/repo.git
```

```
s.source = :git => www.example.com/repo.git, :tag => 'v0.0.1'
```

```
s.source = :git => www.example.com/repo.git, :tag => "v#{s.version}"
```

#### summary
[Required] A short description (max 140 characters).

###### Examples

```
s.summary = 'A library that computes the meaning of life.'
```

#### description
 An optional longer description that can be used in place of the summary.

###### Examples

```
s.description = <<-DESC
                  A library that computes the meaning of life. Features:
                  1. Is self aware
                  ...
                  42. Likes candies.
                DESC
```

#### documentation
 Any additional option to pass to the
[appledoc](http://gentlebytes.com/appledoc/) tool.

###### Examples

```
s.documentation = :appledoc => ['--no-repeat-first-par',
                                '--no-warn-invalid-crossref']
```


## Platform attributes
#### platform
 The platform where this specification is supported.

###### Examples

```
s.platform = :ios
```

```
s.platform = :osx
```

```
s.platform = :osx, "10.8"
```

#### deployment\_target
 The deployment targets for the platforms of the specification.

This attribute supports multi-platform values.

###### Examples

```
s.ios.deployment_target = "6.0"
```

```
s.osx.deployment_target = "10.8"
```


## File pattern attributes
#### source\_files
 The source files of the specification.

This attribute supports multi-platform values.

###### Examples

```
s.source_files = "Classes/**/*.{h,m}"
```

```
s.source_files = "Classes/**/*.{h,m}", "More_Classes/**/*.{h,m}"
```

#### exclude\_source\_files
 A pattern of files that should be excluded from the source files.

This attribute supports multi-platform values.

###### Examples

```
s.ios.exclude_source_files = "Classes/osx"
```

```
s.exclude_source_files = "Classes/**/unused.{h,m}"
```

#### public\_header\_files
 A pattern of files that should be used as public headers.

This attribute supports multi-platform values.

###### Examples

```
s.public_header_files = "Resources/*.png"
```

#### resources
 A list of resources. These are copied into the target bundle with a
build phase script.

This attribute supports multi-platform values.

###### Examples

```
s.resources = "Resources/*.png"
```

#### preserve\_paths
 Any file that should not be cleaned (CocoaPods cleans all the unused
files by default).

This attribute supports multi-platform values.

###### Examples

```
s.preserve_paths = "IMPORTANT.txt"
```


## Dependencies & Subspecs
#### subspec
 Specification for a module of the Pod. A specification automaically
iherits as a dependency all it children subspecs.

Subspec also inherits values from their parents so common values for
attributes can be specified in the ancestors.

This attribute supports multi-platform values.

###### Examples

```
s.subspec 
           subspec "core" do |sp|
             sp.source_files = "Classes/Core"
           end
           
           subspec "optional" do |sp|
             sp.source_files = "Classes/BloatedClassesThatNobodyUses"
           end
```

```
s.subspec 
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

```
s.preferred_dependency = 'Pod/default_subspec'
```

#### dependency
 

This attribute supports multi-platform values.

###### Examples
