require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Podfile::TargetDefinition do
    before do
      @podfile = Podfile.new
      @root = Podfile::TargetDefinition.new('Pods', @podfile)
      @parent = Podfile::TargetDefinition.new('MyApp', @root)
      @child = Podfile::TargetDefinition.new('MyAppTests', @parent)
      @child.inheritance = :search_paths
      @abstract = Podfile::TargetDefinition.new('MyAbstractTarget', @root)
      @abstract.abstract = true
      @parent.set_platform(:ios, '6.0')
    end

    #-------------------------------------------------------------------------#

    describe 'In general' do
      it 'returns its name' do
        expect(@parent.name).to eq('MyApp')
      end

      it 'returns the parent' do
        expect(@root.parent).to eq(@podfile)
        expect(@parent.parent).to eq(@root)
        expect(@child.parent).to eq(@parent)
      end

      #--------------------------------------#

      it 'returns the children' do
        expect(@parent.children).to eq([@child])
        expect(@child.children).to eq([])
      end

      it 'returns the recursive children' do
        @grand_child = Podfile::TargetDefinition.new('MyAppTests', @child)
        expect(@parent.recursive_children).to eq([@child, @grand_child])
        expect(@child.recursive_children).to eq([@grand_child])
        expect(@grand_child.recursive_children).to eq([])
      end

      it 'returns whether it is root' do
        expect(@root).to be_root
        expect(@parent).not_to be_root
        expect(@child).not_to be_root
      end

      it 'returns the root target definition' do
        expect(@root.root).to eq(@root)
        expect(@parent.root).to eq(@root)
        expect(@child.root).to eq(@root)
      end

      it 'returns the podfile that specifies it' do
        expect(@parent.podfile.class).to eq(Podfile)
        expect(@child.podfile.class).to eq(Podfile)
      end

      it 'returns dependencies' do
        @root.store_pod('AFNetworking')
        @parent.store_pod('BlocksKit')
        @child.store_pod('OCMockito')
        @child.inheritance = :complete
        expect(@parent.dependencies.map(&:name)).to eq(%w(BlocksKit AFNetworking))
        expect(@child.dependencies.map(&:name)).to eq(%w(OCMockito BlocksKit AFNetworking))
      end

      it "doesn't inherit dependencies if it is exclusive" do
        @parent.store_pod('BlocksKit')
        @child.store_pod('OCMockito')
        @child.inheritance = :none
        expect(@child.dependencies.map(&:name)).to eq(%w(OCMockito))
      end

      it 'returns the targets to inherit search paths from' do
        @child.inheritance = :search_paths
        expect(@child.targets_to_inherit_search_paths).to eq([@parent])

        grandchild = Podfile::TargetDefinition.new('Grandchild', @child)
        expect(grandchild.targets_to_inherit_search_paths).to eq([@parent])
        grandchild.inheritance = :search_paths
        expect(grandchild.targets_to_inherit_search_paths).to eq([@parent, @child])
        @child.inheritance = :complete
        expect(grandchild.targets_to_inherit_search_paths).to eq([@child])
        @child.inheritance = :none
        expect(grandchild.targets_to_inherit_search_paths).to eq([@child])
      end

      it 'returns the non inherited dependencies' do
        @parent.store_pod('BlocksKit')
        @child.store_pod('OCMockito')
        expect(@parent.non_inherited_dependencies.map(&:name)).to eq(%w(BlocksKit))
        expect(@child.non_inherited_dependencies.map(&:name)).to eq(%w(OCMockito))
      end

      it 'returns whether it is empty' do
        @parent.store_pod('BlocksKit')
        expect(@parent).not_to be_empty
        expect(@child).to be_empty
      end

      it 'returns its label' do
        expect(@parent.label).to eq('Pods-MyApp')
      end

      it 'returns `Pods` as the label if its name is default' do
        target_def = Podfile::TargetDefinition.new('Pods', @podfile)
        expect(target_def.label).to eq('Pods')
      end

      it 'includes the name of the parent in the label if any' do
        @child.inheritance = :complete
        expect(@child.label).to eq('Pods-MyApp-MyAppTests')
      end

      it "doesn't include the name of the parent in the label if it is exclusive" do
        @child.inheritance = :none
        expect(@child.label).to eq('Pods-MyAppTests')
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Attributes accessors' do
      it 'is not abstract by default' do
        expect(@child).not_to be_abstract
      end

      it 'allows to set whether it is abstract' do
        @child.abstract = true
        expect(@child).to be_abstract
      end

      #--------------------------------------#

      it 'has complete inheritance by default' do
        expect(Podfile::TargetDefinition.new('App', nil).inheritance).to eq('complete')
      end

      it 'allows setting the inheritance' do
        @child.inheritance = :complete
        expect(@child.inheritance).to eq('complete')
        @child.inheritance = :none
        expect(@child.inheritance).to eq('none')
        @child.inheritance = :search_paths
        expect(@child.inheritance).to eq('search_paths')
      end

      it 'raises when setting an unknown inheritance mode' do
        expect { @child.inheritance = :unknown }.to raise_error(Informative, 'Unrecognized inheritance option `unknown` specified for target `MyAppTests`.')
      end

      it 'raises when setting an inheritance mode on a root target definition' do
        expect { @root.inheritance = :none }.to raise_error(Informative, 'Cannot set inheritance for the root target definition.')
      end

      it 'raises when setting an inheritance mode on a abstract target definition' do
        expect { @abstract.inheritance = :none }.to raise_error(Informative, 'Cannot set inheritance for abstract target definition.')
      end

      #--------------------------------------#

      it 'is exclusive by default by the default if the platform of the parent match' do
        expect(@child).to be_exclusive
      end

      it "is exclusive by the default if the platform of the parent doesn't match" do
        @parent.set_platform(:osx, '10.6')
        @child.set_platform(:ios, '6.0')
        expect(@child).to be_exclusive
      end

      it 'allows to set whether it is exclusive' do
        @child.inheritance = :complete
        expect(@child).not_to be_exclusive
        @child.inheritance = :none
        expect(@child).to be_exclusive
        @child.inheritance = :search_paths
        expect(@child).to be_exclusive
      end

      #--------------------------------------#

      it "doesn't specifies any user project by default" do
        expect(@parent.user_project_path).to be_nil
      end

      it 'allows to set the path of the user project' do
        @parent.user_project_path = 'some/path/project.xcodeproj'
        expect(@parent.user_project_path).to eq('some/path/project.xcodeproj')
      end

      it 'appends the extension to a specified user project if needed' do
        @parent.user_project_path = 'some/path/project'
        expect(@parent.user_project_path).to eq('some/path/project.xcodeproj')
      end

      it 'inherits the path of the user project from the parent' do
        @parent.user_project_path = 'some/path/project.xcodeproj'
        expect(@child.user_project_path).to eq('some/path/project.xcodeproj')
      end

      #--------------------------------------#

      it "doesn't specifies any project build configurations default" do
        expect(@parent.build_configurations).to be_nil
      end

      it 'allows to set the project build configurations' do
        @parent.build_configurations = { 'Debug' => :debug, 'Release' => :release }
        expect(@parent.build_configurations).to eq({ 'Debug' => :debug, 'Release' => :release })
      end

      it 'inherits the project build configurations from the parent' do
        @parent.build_configurations = { 'Debug' => :debug, 'Release' => :release }
        expect(@child.build_configurations).to eq({ 'Debug' => :debug, 'Release' => :release })
      end

      #--------------------------------------#

      it "doesn't add extra subspec dependencies by default" do
        @parent.store_pod('RestKit')
        expect(@parent.dependencies.map(&:name)).to eq(%w(RestKit))
      end

      it 'allows depending on subspecs' do
        @parent.store_pod('RestKit', :subspecs => %w(Networking))
        expect(@parent.dependencies.map(&:name).sort).to eq(%w(RestKit/Networking))
      end

      it 'allows depending on testspecs' do
        @parent.store_pod('RestKit', :testspecs => %w(Tests))
        expect(@parent.dependencies.map(&:name).sort).to eq(%w(RestKit RestKit/Tests))
      end

      it 'allows depending on appspecs' do
        @parent.store_pod('RestKit', :appspecs => %w(App))
        expect(@parent.dependencies.map(&:name).sort).to eq(%w(RestKit RestKit/App))
      end

      it 'allows depending on both subspecs and testspecs' do
        @parent.store_pod('RestKit', :subspecs => %w(Networking))
        @parent.store_pod('RestKit', :testspecs => %w(Tests))
        expect(@parent.dependencies.map(&:name).sort).to eq(%w(RestKit RestKit/Networking RestKit/Tests))
      end

      it 'allows depending on both subspecs and appspecs' do
        @parent.store_pod('RestKit', :subspecs => %w(Networking))
        @parent.store_pod('RestKit', :appspecs => %w(App))
        expect(@parent.dependencies.map(&:name).sort).to eq(%w(RestKit RestKit/App RestKit/Networking))
      end

      it 'allows depending on subspecs, testspecs, and appspecs' do
        @parent.store_pod('RestKit', :subspecs => %w(Networking))
        @parent.store_pod('RestKit', :testspecs => %w(Tests))
        @parent.store_pod('RestKit', :appspecs => %w(App))
        expect(@parent.dependencies.map(&:name).sort).to eq(%w(RestKit RestKit RestKit/App RestKit/Networking RestKit/Tests))
      end

      it 'allows depending on both subspecs and testspecs in chaining' do
        @parent.store_pod('RestKit', :subspecs => %w(Networking), :testspecs => %w(Tests))
        expect(@parent.dependencies.map(&:name).sort).to eq(%w(RestKit/Networking RestKit/Tests))
      end

      it 'allows depending on both subspecs and appspecs in chaining' do
        @parent.store_pod('RestKit', :subspecs => %w(Networking), :appspecs => %w(App))
        expect(@parent.dependencies.map(&:name).sort).to eq(%w(RestKit/App RestKit/Networking))
      end

      it 'allows depending on subspecs, testspecs, and appspecs in chaining' do
        @parent.store_pod('RestKit', :subspecs => %w(Networking), :testspecs => %w(Tests), :appspecs => %w(App))
        expect(@parent.dependencies.map(&:name).sort).to eq(%w(RestKit/App RestKit/Networking RestKit/Tests))
      end

      #--------------------------------------#

      it "doesn't inhibit warnings per pod by default" do
        @parent.store_pod('ObjectiveSugar')
        expect(@parent.inhibits_warnings_for_pod?('ObjectiveSugar')).to be_falsey
      end

      it 'inhibits warnings per pod if passed to store_pod' do
        @parent.store_pod('Objective-Record', :head, :inhibit_warnings => true)
        expect(@parent.inhibits_warnings_for_pod?('Objective-Record')).to be_truthy

        @parent.store_pod('RestKit/Networking', :head, :inhibit_warnings => true)
        expect(@parent.inhibits_warnings_for_pod?('RestKit')).to be_truthy
      end

      it 'does not inhibit warnings per pod if the option is false' do
        @parent.inhibit_all_warnings = true
        @parent.store_pod('ASIHTTPRequest', :inhibit_warnings => false)
        expect(@parent.inhibits_warnings_for_pod?('ASIHTTPRequest')).to be_falsey
      end

      it 'must delete the hash if it was empty. otherwise breaks Dependency' do
        reqs = [{ :inhibit_warnings => true }]
        @parent.send(:parse_inhibit_warnings, 'Objective-Record', reqs)
        expect(reqs).to be_empty
      end

      it 'returns if it should inhibit all warnings' do
        @parent.inhibit_all_warnings = true
        expect(@parent.inhibits_warnings_for_pod?('ObjectiveSugar')).to be_truthy
      end

      it 'inherits the option to inhibit all warnings' do
        @parent.inhibit_all_warnings = true
        @child.store_pod('ASIHTTPRequest')
        expect(@child.inhibits_warnings_for_pod?('ASIHTTPRequest')).to be_truthy
      end

      it 'inherits the option to inhibit warnings per pod' do
        @parent.store_pod('Objective-Record', :inhibit_warnings => true)
        expect(@child.inhibits_warnings_for_pod?('Objective-Record')).to be_truthy
      end

      it 'inherits the false option to inhibit warnings per pod' do
        @parent.inhibit_all_warnings = true
        @child.store_pod('ASIHTTPRequest', :inhibit_warnings => false)
        expect(@child.inhibits_warnings_for_pod?('ASIHTTPRequest')).to be_falsey
      end

      it 'overriding inhibition per pod in child should not affect parent' do
        @parent.store_pod('ASIHTTPRequest', :inhibit_warnings => true)
        @child.store_pod('ASIHTTPRequest', :inhibit_warnings => false)
        expect(@child.inhibits_warnings_for_pod?('ASIHTTPRequest')).to be_falsey
        expect(@parent.inhibits_warnings_for_pod?('ASIHTTPRequest')).to be_truthy
      end

      #--------------------------------------#

      it "doesn't use modular headers per pod by default" do
        @parent.store_pod('ObjectiveSugar')
        expect(@parent.build_pod_as_module?('ObjectiveSugar')).to be_falsey
      end

      it 'uses modular headers per pod if passed to store_pod' do
        @parent.store_pod('Objective-Record', :head, :modular_headers => true)
        expect(@parent.build_pod_as_module?('Objective-Record')).to be_truthy

        @parent.store_pod('RestKit/Networking', :head, :modular_headers => true)
        expect(@parent.build_pod_as_module?('RestKit')).to be_truthy
      end

      it 'does not use modular headers per pod if the option is false' do
        @parent.use_modular_headers_for_all_pods = true
        @parent.store_pod('ASIHTTPRequest', :modular_headers => false)
        expect(@parent.build_pod_as_module?('ASIHTTPRequest')).to be_falsey
      end

      it 'deletes the hash if empty' do
        reqs = [{ :modular_headers => true }]
        @parent.send(:parse_modular_headers, 'Objective-Record', reqs)
        expect(reqs).to be_empty
      end

      it 'returns if it should use modular headers for all pods' do
        @parent.use_modular_headers_for_all_pods = true
        expect(@parent.build_pod_as_module?('ObjectiveSugar')).to be_truthy
      end

      it 'inherits the option to use modular headers for all pods' do
        @parent.use_modular_headers_for_all_pods = true
        @child.store_pod('ASIHTTPRequest')
        expect(@child.build_pod_as_module?('ASIHTTPRequest')).to be_truthy
      end

      it 'inherits the option to use modular headers per pod' do
        @parent.store_pod('Objective-Record', :modular_headers => true)
        expect(@child.build_pod_as_module?('Objective-Record')).to be_truthy
      end

      it 'inherits the false option to use modular headers per pod' do
        @parent.use_modular_headers_for_all_pods = true
        @child.store_pod('ASIHTTPRequest', :modular_headers => false)
        expect(@child.build_pod_as_module?('ASIHTTPRequest')).to be_falsey
      end

      it 'overriding modular headers per pod in child should not affect parent' do
        @parent.store_pod('ASIHTTPRequest', :modular_headers => true)
        @child.store_pod('ASIHTTPRequest', :modular_headers => false)
        expect(@child.build_pod_as_module?('ASIHTTPRequest')).to be_falsey
        expect(@parent.build_pod_as_module?('ASIHTTPRequest')).to be_truthy
      end

      #--------------------------------------#

      it 'stores the project name for a given pod' do
        @parent.store_pod('ASIHTTPRequest', :project_name => 'SomeProject')
        expect(@parent.project_name_for_pod('ASIHTTPRequest')).to eq('SomeProject')
        expect(@parent.project_name_for_pod('UnknownPod')).to be_nil
      end

      it 'inherits the project name option to use for a pod' do
        @parent.store_pod('ASIHTTPRequest', :project_name => 'SomeProject')
        expect(@child.project_name_for_pod('ASIHTTPRequest')).to eq('SomeProject')
      end

      it 'honors the project name directly set from the target definition before delegating to parent' do
        @parent.store_pod('ASIHTTPRequest', :project_name => 'SomeProject')
        @child.store_pod('ASIHTTPRequest', :project_name => 'SomeOtherProject')
        expect(@child.project_name_for_pod('ASIHTTPRequest')).to eq('SomeOtherProject')
      end

      #--------------------------------------#

      it 'returns if it should use frameworks' do
        @parent.use_frameworks!
        expect(@parent.uses_frameworks?).to be_truthy
      end

      it 'returns it does not use frameworks if its explicitly specified' do
        @parent.use_frameworks!(false)
        expect(@parent.uses_frameworks?).to be_falsey
      end

      it 'returns if it should use frameworks by specifying static linkage' do
        @parent.use_frameworks!(:linkage => :static)
        expect(@parent.uses_frameworks?).to be_truthy
      end

      it 'returns if it should use frameworks by specifying dynamic linkage' do
        @parent.use_frameworks!(:linkage => :dynamic)
        expect(@parent.uses_frameworks?).to be_truthy
      end

      it 'raises when an invalid type is used' do
        expect { @parent.use_frameworks!(1) }.to raise_error(ArgumentError, 'Got `1`, should be a boolean or hash.')
      end

      it 'inherits the option to use frameworks' do
        @parent.use_frameworks!
        expect(@child.uses_frameworks?).to be_truthy
      end

      it 'allows children to opt-out of using frameworks' do
        @parent.use_frameworks!
        @child.use_frameworks!(false)
        expect(@child.uses_frameworks?).to be_falsey
        # make sure that the value is not accidentally overwritten on access
        expect(@child.uses_frameworks?).to be_falsey
      end

      it 'returns the default build type' do
        expect(@parent.build_type).to eq(BuildType.static_library)
      end

      it 'returns the default frameworks build type' do
        @parent.use_frameworks!
        expect(@parent.build_type).to eq(BuildType.dynamic_framework)
      end

      it 'returns the configured dynamic framework build type' do
        @parent.use_frameworks!(:linkage => :dynamic)
        expect(@parent.build_type).to eq(BuildType.dynamic_framework)
      end

      it 'returns the configured static framework build type' do
        @parent.use_frameworks!(:linkage => :static)
        expect(@parent.build_type).to eq(BuildType.static_framework)
      end

      it 'inherits the build type' do
        @parent.use_frameworks!
        expect(@child.build_type).to eq(BuildType.dynamic_framework)
      end

      #--------------------------------------#

      it 'raises if script phase is missing required key' do
        expect { @parent.store_script_phase(:name => 'PhaseName') }.to raise_error(Podfile::StandardError, 'Missing required shell script phase options `script`')
      end

      it 'raises if script phase includes an unrecognized key' do
        expect do
          @parent.store_script_phase(:name => 'PhaseName', :unknown => 'Unknown')
        end.to raise_error(Podfile::StandardError, 'Unrecognized options `[:unknown]` in shell script `PhaseName` within `MyApp` target. ' \
          'Available options are `[:name, :script, :shell_path, :input_files, :output_files, :input_file_lists, ' \
            ':output_file_lists, :show_env_vars_in_log, :execution_position, :dependency_file, :always_out_of_date]`.')
      end

      it 'raises if script phase includes an invalid execution position key' do
        expect do
          @parent.store_script_phase(:name => 'PhaseName', :script => 'echo "Hello World"', :execution_position => :unknown)
        end.to raise_error(Podfile::StandardError, 'Invalid execution position value `unknown` in shell script `PhaseName` within `MyApp` target. ' \
          'Available options are `[:before_compile, :after_compile, :before_headers, :after_headers, :any]`.')
      end

      it 'raises if the same script phase name already exists' do
        expect do
          @parent.store_script_phase(:name => 'PhaseName', :script => 'echo "Hello World"')
          @parent.store_script_phase(:name => 'PhaseName', :script => 'echo "Hello World"')
        end.to raise_error(Podfile::StandardError, 'Script phase with name `PhaseName` name already present for target `MyApp`.')
      end

      it 'stores a script phase if requirements are provided' do
        @parent.store_script_phase(:name => 'PhaseName', :script => 'echo "Hello World"')
        expect(@parent.script_phases).to eq([
          { :name => 'PhaseName', :script => 'echo "Hello World"', :execution_position => :any },
        ])
      end

      it 'stores a script phase with requirements and optional keys' do
        @parent.store_script_phase(:name => 'PhaseName', :script => 'echo "Hello World"', :shell_path => '/usr/bin/ruby')
        expect(@parent.script_phases).to eq([
          { :name => 'PhaseName', :script => 'echo "Hello World"', :shell_path => '/usr/bin/ruby', :execution_position => :any },
        ])
      end

      it 'stores a script phase with a specified execution position value' do
        @parent.store_script_phase(:name => 'PhaseName', :script => 'echo "Hello World"', :shell_path => '/usr/bin/ruby', :execution_position => :before_compile)
        expect(@parent.script_phases).to eq([
          { :name => 'PhaseName', :script => 'echo "Hello World"', :shell_path => '/usr/bin/ruby', :execution_position => :before_compile },
        ])
      end

      #--------------------------------------#

      it 'whitelists pods by default' do
        @parent.store_pod('ObjectiveSugar')
        expect(@parent.pod_whitelisted_for_configuration?('ObjectiveSugar', 'Release')).to be_truthy
        expect(@child.pod_whitelisted_for_configuration?('ObjectiveSugar', 'Release')).to be_truthy
      end

      it 'does not enable pods for un-whitelisted configurations if it is whitelisted for another' do
        @parent.store_pod('ObjectiveSugar')
        @parent.whitelist_pod_for_configuration('ObjectiveSugar', 'Release')
        expect(@parent.pod_whitelisted_for_configuration?('ObjectiveSugar', 'Debug')).to be_falsey
        expect(@child.pod_whitelisted_for_configuration?('ObjectiveSugar', 'Debug')).to be_falsey
      end

      it 'enables pods for configurations they are whitelisted for' do
        @parent.store_pod('ObjectiveSugar', :configuration => 'Release')
        expect(@parent.pod_whitelisted_for_configuration?('ObjectiveSugar', 'Release')).to be_truthy
        expect(@parent.pod_whitelisted_for_configuration?('ObjectiveSugar', 'Debug')).to be_falsey
        expect(@child.pod_whitelisted_for_configuration?('ObjectiveSugar', 'Release')).to be_truthy
        expect(@child.pod_whitelisted_for_configuration?('ObjectiveSugar', 'Debug')).to be_falsey
        @parent.store_pod('AFNetworking', :configurations => ['Debug'])
        expect(@parent.pod_whitelisted_for_configuration?('AFNetworking', 'Debug')).to be_truthy
        expect(@parent.pod_whitelisted_for_configuration?('AFNetworking', 'Release')).to be_falsey
        expect(@child.pod_whitelisted_for_configuration?('AFNetworking', 'Debug')).to be_truthy
        expect(@child.pod_whitelisted_for_configuration?('AFNetworking', 'Release')).to be_falsey
      end

      it 'child pods for configurations can merge from parent' do
        @parent.store_pod('ObjectiveSugar', :configuration => 'Release')
        @child.store_pod('AFNetworking', :configuration => 'Release')
        expect(@parent.pod_whitelisted_for_configuration?('ObjectiveSugar', 'Release')).to be_truthy
        expect(@parent.pod_whitelisted_for_configuration?('ObjectiveSugar', 'Debug')).to be_falsey
        expect(@child.pod_whitelisted_for_configuration?('ObjectiveSugar', 'Release')).to be_truthy
        expect(@child.pod_whitelisted_for_configuration?('ObjectiveSugar', 'Debug')).to be_falsey
        expect(@child.pod_whitelisted_for_configuration?('AFNetworking', 'Release')).to be_truthy
        expect(@child.pod_whitelisted_for_configuration?('AFNetworking', 'Debug')).to be_falsey
      end

      it 'coerces configuration names to strings' do
        @parent.store_pod('ObjectiveSugar', :configuration => :Release)
        expect(@parent.pod_whitelisted_for_configuration?('ObjectiveSugar', 'Release')).to be_truthy
        expect(@parent.pod_whitelisted_for_configuration?('ObjectiveSugar', 'Debug')).to be_falsey
      end

      it 'compares build configurations case-insensitively' do
        @parent.store_pod('ObjectiveSugar', :configuration => :Release)
        expect(@parent.pod_whitelisted_for_configuration?('ObjectiveSugar', 'Release')).to be_truthy
        expect(@parent.pod_whitelisted_for_configuration?('objectivesugar', 'Release')).to be_truthy
      end

      it 'returns a unique list of all whitelisted configurations' do
        expect(@root.all_whitelisted_configurations).to eq([])
        @root.whitelist_pod_for_configuration('ObjectiveSugar', 'Release')
        @root.whitelist_pod_for_configuration('AFNetworking', 'Release')
        expect(@root.all_whitelisted_configurations).to eq(['Release'])
        expect(@child.all_whitelisted_configurations).to eq(['Release'])
        @root.whitelist_pod_for_configuration('Objective-Record', 'Debug')
        expect(@root.all_whitelisted_configurations.sort).to eq(%w(Debug Release))
        expect(@child.all_whitelisted_configurations.sort).to eq(%w(Debug Release))
      end

      it 'whitelists pod configurations with testspecs' do
        @parent.build_configurations = { 'Debug' => :debug, 'Release' => :release }
        @parent.store_pod('RestKit', :testspecs => %w(Tests), :configuration => 'Debug')
        expect(@parent.pod_whitelisted_for_configuration?('RestKit', 'Debug')).to be_truthy
        expect(@parent.pod_whitelisted_for_configuration?('RestKit/Tests', 'Debug')).to be_truthy
        expect(@parent.pod_whitelisted_for_configuration?('RestKit', 'Release')).to be_falsey
        expect(@parent.pod_whitelisted_for_configuration?('RestKit/Tests', 'Release')).to be_falsey
      end

      it 'whitelists pod configurations with appspecs' do
        @parent.build_configurations = { 'Debug' => :debug, 'Release' => :release }
        @parent.store_pod('RestKit', :appspecs => %w(App), :configuration => 'Debug')
        expect(@parent.pod_whitelisted_for_configuration?('RestKit', 'Debug')).to be_truthy
        expect(@parent.pod_whitelisted_for_configuration?('RestKit/App', 'Debug')).to be_truthy
        expect(@parent.pod_whitelisted_for_configuration?('RestKit', 'Release')).to be_falsey
        expect(@parent.pod_whitelisted_for_configuration?('RestKit/App', 'Release')).to be_falsey
      end

      it 'whitelists pod configurations with appspecs and testspecs' do
        @parent.build_configurations = { 'Debug' => :debug, 'Release' => :release }
        @parent.store_pod('RestKit', :testspecs => %w(Tests), :configuration => 'Debug')
        @parent.store_pod('RestKit', :appspecs => %w(App), :configuration => 'Debug')
        expect(@parent.pod_whitelisted_for_configuration?('RestKit', 'Debug')).to be_truthy
        expect(@parent.pod_whitelisted_for_configuration?('RestKit/App', 'Debug')).to be_truthy
        expect(@parent.pod_whitelisted_for_configuration?('RestKit/Tests', 'Debug')).to be_truthy
        expect(@parent.pod_whitelisted_for_configuration?('RestKit', 'Release')).to be_falsey
        expect(@parent.pod_whitelisted_for_configuration?('RestKit/App', 'Release')).to be_falsey
        expect(@parent.pod_whitelisted_for_configuration?('RestKit/Tests', 'Release')).to be_falsey
      end

      #--------------------------------------#

      it 'returns its platform' do
        expect(@parent.platform).to eq(Pod::Platform.new(:ios, '6.0'))
      end

      it 'inherits the platform form the parent' do
        expect(@parent.platform).to eq(Pod::Platform.new(:ios, '6.0'))
      end

      it 'provides a default deployment target if not specified' do
        @parent.set_platform(:ios)
        expect(@parent.platform).to eq(Pod::Platform.new(:ios, '4.3'))

        @parent.set_platform(:osx)
        expect(@parent.platform).to eq(Pod::Platform.new(:osx, '10.6'))
      end

      it 'raises if the specified platform is unsupported' do
        expect { @parent.set_platform(:win) }.to raise_error(Podfile::StandardError, /Unsupported platform/)
      end

      #--------------------------------------#

      it 'returns nil for swift_version by default' do
        expect(@parent.swift_version).to be_nil
      end

      it 'allows you to set the swift_version' do
        @parent.swift_version = '2.3'
        expect(@parent.swift_version).to eq('2.3')
      end

      it 'stores a single swift version requirement' do
        @parent.store_swift_version_requirements('3.0')
        expect(@parent.send(:get_hash_value, 'swift_version_requirements')).to eq([
          '3.0',
        ])
      end

      it 'stores swift version requirements as strings' do
        @parent.store_swift_version_requirements('>= 3.0', '< 4.0')
        expect(@parent.send(:get_hash_value, 'swift_version_requirements')).to eq([
          '>= 3.0',
          '< 4.0',
        ])
      end

      it 'stores swift version requirements as an array of strings' do
        @parent.store_swift_version_requirements(['>= 3.0', '< 4.0'])
        expect(@parent.send(:get_hash_value, 'swift_version_requirements')).to eq([
          '>= 3.0',
          '< 4.0',
        ])
      end

      it 'stores swift version requirements as versions' do
        @parent.store_swift_version_requirements(Version.new('3.0'), Version.new('4.0'))
        expect(@parent.send(:get_hash_value, 'swift_version_requirements')).to eq([
          '3.0',
          '4.0',
        ])
      end

      it 'correctly returns whether a version of Swift is supported based on requirements' do
        @parent.store_swift_version_requirements('>= 3.0', '< 4.0')
        expect(@parent.supports_swift_version?(Version.new('1.0'))).to be(false)
        expect(@parent.supports_swift_version?(Version.new('2.0'))).to be(false)
        expect(@parent.supports_swift_version?(Version.new('3.0'))).to be(true)
        expect(@parent.supports_swift_version?(Version.new('3.2'))).to be(true)
        expect(@parent.supports_swift_version?(Version.new('4.0'))).to be(false)
      end

      it 'correclty returns whether a version of Swift is supported based on Version requirements' do
        @parent.store_swift_version_requirements(Version.new('3.0'))
        expect(@parent.supports_swift_version?(Version.new('1.0'))).to be(false)
        expect(@parent.supports_swift_version?(Version.new('2.0'))).to be(false)
        expect(@parent.supports_swift_version?(Version.new('3.0'))).to be(true)
        expect(@parent.supports_swift_version?(Version.new('3.2'))).to be(false)
        expect(@parent.supports_swift_version?(Version.new('4.0'))).to be(false)
      end

      it 'delegates to the parent for Swift version support if current target does not specify requirements' do
        @parent.store_swift_version_requirements('>= 3.0', '< 4.0')
        expect(@child.supports_swift_version?(Version.new('1.0'))).to be(false)
        expect(@child.supports_swift_version?(Version.new('2.0'))).to be(false)
        expect(@child.supports_swift_version?(Version.new('3.0'))).to be(true)
        expect(@child.supports_swift_version?(Version.new('3.2'))).to be(true)
        expect(@child.supports_swift_version?(Version.new('4.0'))).to be(false)
      end

      it 'returns the Swift version supported of the current target definition if specified' do
        @child.store_swift_version_requirements('>= 4.0')
        @parent.store_swift_version_requirements('>= 3.0', '< 4.0')
        expect(@child.supports_swift_version?(Version.new('1.0'))).to be(false)
        expect(@child.supports_swift_version?(Version.new('2.0'))).to be(false)
        expect(@child.supports_swift_version?(Version.new('3.0'))).to be(false)
        expect(@child.supports_swift_version?(Version.new('3.2'))).to be(false)
        expect(@child.supports_swift_version?(Version.new('4.0'))).to be(true)
        expect(@child.supports_swift_version?(Version.new('4.2'))).to be(true)
      end

      it 'accepts all Swift versions if no requirements are specified' do
        expect(@parent.supports_swift_version?(Version.new('1.0'))).to be(true)
        expect(@parent.supports_swift_version?(Version.new('2.0'))).to be(true)
        expect(@parent.supports_swift_version?(Version.new('3.0'))).to be(true)
        expect(@parent.supports_swift_version?(Version.new('3.2'))).to be(true)
        expect(@parent.supports_swift_version?(Version.new('4.0'))).to be(true)
      end

      #--------------------------------------#

      it 'stores a dependency on a pod as a sting if no requirements are provided' do
        @parent.store_pod('BlocksKit')
        expect(@parent.send(:get_hash_value, 'dependencies')).to eq([
          'BlocksKit',
        ])
      end

      it 'stores a dependency on a pod as a hash if requirements provided' do
        @parent.store_pod('Reachability', '1.0')
        expect(@parent.send(:get_hash_value, 'dependencies')).to eq([
          { 'Reachability' => ['1.0'] },
        ])
      end

      #--------------------------------------#

      it 'stores a dependency on a podspec' do
        @parent.store_podspec(:name => 'BlocksKit')
        expect(@parent.send(:get_hash_value, 'podspecs')).to eq([
          { :name => 'BlocksKit' },
        ])
      end

      it 'stores a dependency on a podspec and sets is as auto-detect if no options are provided' do
        @parent.store_podspec
        expect(@parent.send(:get_hash_value, 'podspecs')).to eq([
          { :autodetect => true },
        ])
      end

      it 'stores a dependency on a podspec\'s subspec' do
        @parent.store_podspec(:subspec => 'Subspec')
        expect(@parent.send(:get_hash_value, 'podspecs')).to eq([
          { :autodetect => true,
            :subspec => 'Subspec',
           },
        ])
      end

      it 'stores a dependency on a podspec\'s subspecs' do
        @parent.store_podspec(:subspecs => ['Subspec'])
        expect(@parent.send(:get_hash_value, 'podspecs')).to eq([
          { :autodetect => true,
            :subspecs => ['Subspec'],
           },
        ])
      end

      it 'raises if the provided podspec option type is error' do
        expect { @parent.store_podspec(:subspec => 123) }.to raise_error(Podfile::StandardError, /should be a String/)

        expect { @parent.store_podspec(:subspecs => 123) }.to raise_error(Podfile::StandardError, /should be an Array of Strings/)

        expect { @parent.store_podspec(:subspecs => ['a', 123]) }.to raise_error(Podfile::StandardError, /should be an Array of Strings/)
      end

      it 'raises if the provided podspec options are unsupported' do
        expect { @parent.store_podspec(:invent => 'BlocksKit') }.to raise_error(Podfile::StandardError, /Unrecognized options/)
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Hash representation' do
      it 'returns the hash representation' do
        @child.store_pod('BlocksKit')
        @child.set_platform(:ios)
        expect(@child.to_hash).to eq({
          'name' => 'MyAppTests',
          'abstract' => false,
          'inheritance' => 'search_paths',
          'dependencies' => ['BlocksKit'],
          'platform' => 'ios',
        })
      end

      it 'stores the children in the hash representation' do
        Podfile::TargetDefinition.new('MoarTests', @parent)
        @parent.store_pod('BlocksKit')
        @child.store_pod('RestKit')
        expect(@parent.to_hash).to eq({
          'name' => 'MyApp',
          'platform' => { 'ios' => '6.0' },
          'dependencies' => ['BlocksKit'],
          'children' => [
            {
              'name' => 'MyAppTests',
              'abstract' => false,
              'inheritance' => 'search_paths',
              'dependencies' => ['RestKit'],
            },
            {
              'name' => 'MoarTests',
            },
          ],
        })
      end

      it 'can be initialized from a hash' do
        @parent.store_pod('BlocksKit')
        @child.store_pod('RestKit')
        converted = Podfile::TargetDefinition.from_hash(@parent.to_hash, @podfile)
        expect(converted.to_hash).to eq(@parent.to_hash)
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Private helpers' do
      before do
        @parent.podfile.defined_in_file = SpecHelper::Fixture.fixture('Podfile')
      end

      #--------------------------------------#

      it 'sets and retrieves a value in the internal hash' do
        @parent.send(:set_hash_value, 'name', 'Fabio')
        expect(@parent.send(:get_hash_value, 'name')).to eq('Fabio')
      end

      it 'raises if there is an attempt to access or set an unknown key in the internal hash' do
        expect { @parent.send(:set_hash_value, 'unknown', true) }.to raise_error(Pod::Podfile::StandardError)
        expect { @parent.send(:get_hash_value, 'unknown') }.to raise_error(Pod::Podfile::StandardError)
      end

      it 'returns the dependencies specified by the user' do
        @parent.store_pod('BlocksKit')
        @parent.store_pod('AFNetworking', '1.0')
        dependencies = @parent.send(:pod_dependencies)
        expect(dependencies.map(&:to_s)).to eq(['BlocksKit', 'AFNetworking (= 1.0)'])
      end

      #--------------------------------------#

      describe '#pod_dependencies' do
        it 'handles dependencies which only indicate the name of the Pod' do
          @parent.store_pod('BlocksKit')
          expect(@parent.send(:pod_dependencies)).to eq([
            Dependency.new('BlocksKit'),
          ])
        end

        it 'handles requirements' do
          @parent.store_pod('BlocksKit', '> 1.0', '< 2.5')
          expect(@parent.send(:pod_dependencies)).to eq([
            Dependency.new('BlocksKit', ['> 1.0', '< 2.5']),
          ])
        end

        it 'handles subspecs' do
          @parent.store_pod('Spec/Subspec')
          expect(@parent.send(:pod_dependencies)).to eq([
            Dependency.new('Spec/Subspec'),
          ])
        end

        it 'handles dependencies options' do
          @parent.store_pod('BlocksKit', :git => 'GIT-URL', :commit => '1234')
          expect(@parent.send(:pod_dependencies)).to eq([
            Dependency.new('BlocksKit', :git => 'GIT-URL', :commit => '1234'),
          ])
        end
      end

      #--------------------------------------#

      describe '#podspec_dependencies' do
        it 'returns the dependencies of podspecs' do
          path = SpecHelper::Fixture.fixture('BananaLib.podspec').to_s
          @parent.store_podspec(:path => path)
          expect(@parent.send(:podspec_dependencies)).to eq([
            Dependency.new('monkey', '< 1.0.9', '~> 1.0.1'),
            Dependency.new('AFNetworking'),
            Dependency.new('SDWebImage'),
          ])
        end

        it 'returns the dependencies of a subspec' do
          path = SpecHelper::Fixture.fixture('BananaLib.podspec').to_s
          @parent.store_podspec(:path => path, :subspec => 'GreenBanana')
          expect(@parent.send(:podspec_dependencies)).to eq([
            Dependency.new('monkey', '< 1.0.9', '~> 1.0.1'),
            Dependency.new('AFNetworking'),
          ])
        end

        it 'reject the dependencies on subspecs' do
          path = SpecHelper::Fixture.fixture('BananaLib.podspec').to_s
          @parent.store_podspec(:path => path)
          external_dep = Dependency.new('monkey', '< 1.0.9', '~> 1.0.1')
          internal_dep = Dependency.new('BananaLib/subspec')
          deps = [external_dep, internal_dep]
          Specification.any_instance.stubs(:dependencies).returns([deps])
          expect(@parent.send(:podspec_dependencies)).to eq([
            Dependency.new('monkey', '< 1.0.9', '~> 1.0.1'),
          ])
        end
      end

      #--------------------------------------#

      describe '#podspec_path_from_options' do
        it 'resolves a podspec given the absolute path' do
          options = { :path => SpecHelper::Fixture.fixture('BananaLib') }
          file = @parent.send(:podspec_path_from_options, options)
          expect(file).to eq(SpecHelper::Fixture.fixture('BananaLib.podspec'))
        end

        it 'resolves a podspec given the relative path' do
          options = { :path => 'BananaLib.podspec' }
          file = @parent.send(:podspec_path_from_options, options)
          expect(file).to eq(SpecHelper::Fixture.fixture('BananaLib.podspec'))
        end

        it 'add the extension if needed' do
          options = { :path => 'BananaLib' }
          file = @parent.send(:podspec_path_from_options, options)
          expect(file).to eq(SpecHelper::Fixture.fixture('BananaLib.podspec'))
        end

        it "doesn't add an extension for json podspecs" do
          options = { :path => 'BananaLib.podspec.json' }
          file = @parent.send(:podspec_path_from_options, options)
          expect(file).to eq(SpecHelper::Fixture.fixture('BananaLib.podspec.json'))
        end

        it 'it expands the tilde in the provided path' do
          home_dir = File.expand_path('~')
          options = { :path => '~/BananaLib.podspec' }
          file = @parent.send(:podspec_path_from_options, options)
          expect(file).to eq(Pathname.new("#{home_dir}/BananaLib.podspec"))
        end

        it 'resolves a podspec given its name' do
          options = { :name => 'BananaLib' }
          file = @parent.send(:podspec_path_from_options, options)
          expect(file).to eq(SpecHelper::Fixture.fixture('BananaLib.podspec'))
        end

        it "doesn't add an extension for json podspecs" do
          options = { :name => 'BananaLib.podspec.json' }
          file = @parent.send(:podspec_path_from_options, options)
          expect(file).to eq(SpecHelper::Fixture.fixture('BananaLib.podspec.json'))
        end

        it 'auto-detects the podspec' do
          options = { :autodetect => true }
          file = @parent.send(:podspec_path_from_options, options)
          expect(file).to eq(SpecHelper::Fixture.fixture('BananaLib.podspec'))
        end

        it 'raise an Informative error if the podspec cannot be auto-detected' do
          @parent.podfile.defined_in_file = SpecHelper::Fixture.fixture('podfile_without_root_podspec/Podfile')
          options = { :autodetect => true }
          expect { @parent.send(:podspec_path_from_options, options) }.to raise_error(Pod::Informative, /Could not locate a podspec in the/)
        end
      end
    end

    #-------------------------------------------------------------------------#
  end
end
