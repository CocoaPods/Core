require 'cocoapods-core/podfile/dsl'
require 'cocoapods-core/podfile/target_definition'

module Pod

  # The {Podfile} is a specification that describes the dependencies of the
  # targets of an Xcode project.
  #
  # It supports its own DSL and generally is stored in files named
  # `CocoaPods.podfile` or `Podfile`.
  #
  # The Podfile creates a hierarchy of target definitions that that store the
  # information of necessary to generate the CocoaPods libraries.
  #
  class Podfile

    # @return [Pathname] the path where the podfile was loaded from. It is nil
    #         if the podfile was generated programmatically.
    #
    attr_accessor :defined_in_file

    # @param    [Pathname] defined_in_file
    #           the path of the podfile.
    #
    # @param    [Proc] block
    #           a block that configures the podfile through its DSL.
    #
    # @example  Creating a Podfile.
    #
    #           platform :ios, "6.0"
    #           target :my_app do
    #             pod "AFNetworking", "~> 1.0"
    #           end
    #
    def initialize(defined_in_file = nil, &block)
      self.defined_in_file = defined_in_file
      @target_definition = TargetDefinition.new(:default, nil, self, :exclusive => true)
      @target_definitions = { :default => @target_definition }
      instance_eval(&block)
    end

    # Initializes a podfile from the file with the given path.
    #
    # @param  [Pathname] path
    #         the path from where the podfile should be loaded.
    #
    # @return [Podfile] the generated podfile.
    #
    def self.from_file(path)
      podfile = Podfile.new(path) do
        string = File.open(path, 'r:utf-8')  { |f| f.read }
        # Work around for Rubinius incomplete encoding in 1.9 mode
        string.encode!('UTF-8') if string.respond_to?(:encoding) && string.encoding.name != "UTF-8"
        eval(string, nil, path.to_s)
      end
      podfile.validate!
      podfile
    end

    class Pod::Podfile::StandardError < StandardError; end

    # Raises a {Podfile::StandardError} exception with the given message. If
    # the Podfile is defined in a file, the line that caused the exception is
    # included in the message.
    #
    # @param    [String] message
    #           the message of the exception.
    #
    # @example  Output example
    #
    #           Pod::Podfile::StandardError: Inline specifications are deprecated.
    #           Please store the specification in a `podspec` file.
    #
    #               from CocoaPods/tmp/Podfile:2
    #
    #               pod do |s|
    #            >    s.name = 'mypod'
    #               end
    #
    # @return   [void]
    #
    def raise(message)
      if defined_in_file
        podfile_file_trace_line = caller.find { |l| l =~ /#{defined_in_file.basename}/ }
        line_numer    = podfile_file_trace_line.split(':')[1].to_i - 1
        podfile_lines = File.readlines(defined_in_file.to_s)
        indent        = "    "
        indicator     = indent.dup.insert(1, ">")[0..-2]

        message << "\n\n#{indent}from #{podfile_file_trace_line.gsub(/:in.*$/,'')}\n\n"
        (message << indent    << podfile_lines[line_numer - 1 ]) unless line_numer == 0
        (message << indicator << podfile_lines[line_numer])
        (message << indent    << podfile_lines[line_numer + 1 ]) unless line_numer == (podfile_lines.count - 1)
        message << "\n"
      end
      super StandardError, message
    end

    #---------------------------------------------------------------------------#

    # @!group DSL support

    include Pod::Podfile::DSL

    # @deprecated Deprecated in favour of the more succinct {#pod}
    #
    # @see        pod
    #
    # @todo       Remove for CocoaPods 1.0.
    #
    # @return     [void]
    #
    def dependency(name = nil, *requirements, &block)
      warn "[DEPRECATED] `dependency' is deprecated (use `pod')"
      pod(name, *requirements, &block)
    end


    #---------------------------------------------------------------------------#

    # @!group Working with a podfile

    # @return [Hash{Symbol,String => TargetDefinition}] the target definitions
    #         of the podfile stored by their name.
    #
    attr_reader :target_definitions


    # @return [Array<Dependency>] the dependencies of the all the target
    #         definitions.
    #
    def dependencies
      @target_definitions.values.map(&:target_dependencies).flatten.uniq
    end

    # Validates the podfile.
    #
    # @note   Currently this method does nothing.
    #
    # @return [void]
    #
    def validate!
      # TODO: raise if not platform is specified for the target definition ?
    end

    # @return [String] a string useful to represent the Podfile in a message
    #         presented to the user.
    #
    def to_s
      "Podfile"
    end

    # @return [String] the path of the workspace if specified by the user.
    #
    attr_reader :workspace_path

    # @return [Bool] whether the podfile should generate a BridgeSupport
    #         metadata document.
    #
    def generate_bridge_support?
      @generate_bridge_support
    end

    # @return [Bool] whether the -fobjc-arc flag should be added to the
    #         OTHER_LD_FLAGS.
    #
    def set_arc_compatibility_flag?
      @set_arc_compatibility_flag
    end

    # Calls the pre install callback if defined.
    #
    # @param  [Pod::Installer] installer
    #         the installer that is performing the installation.
    #
    # @return [Bool] whether a pre install callback was specified and it was
    #         called.
    #
    def pre_install!(installer)
      if @pre_install_callback
        @pre_install_callback.call(installer)
        true
      else
        false
      end
    end

    # Calls the post install callback if defined.
    #
    # @param  [Pod::Installer] installer
    #         the installer that is performing the installation.
    #
    # @return [Bool] whether a post install callback was specified and it was
    #         called.
    #
    def post_install!(installer)
      if @post_install_callback
        @post_install_callback.call(installer)
        true
      else
        false
      end
    end
  end
end
