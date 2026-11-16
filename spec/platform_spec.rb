require File.expand_path('../spec_helper', __FILE__)

module Pod
  describe Platform do
    describe 'In general' do
      it 'returns a new Platform instance' do
        expect(Platform.ios).to eq(Platform.new(:ios))
        expect(Platform.osx).to eq(Platform.new(:osx))
        expect(Platform.tvos).to eq(Platform.new(:tvos))
        expect(Platform.visionos).to eq(Platform.new(:visionos))
        expect(Platform.watchos).to eq(Platform.new(:watchos))
        expect(Platform.all).to include(Platform.new(:ios))
        expect(Platform.all).to include(Platform.new(:osx))
        expect(Platform.all).to include(Platform.new(:tvos))
        expect(Platform.all).to include(Platform.new(:visionos))
        expect(Platform.all).to include(Platform.new(:watchos))
      end

      it 'can be initialized from another platform' do
        platform = Platform.new(:ios)
        new = Platform.new(platform)
        expect(new).to eq(platform)
      end

      before do
        @platform = Platform.ios
      end

      it 'exposes its symbolic name' do
        expect(@platform.name).to eq(:ios)
      end

      it 'can be initialized with a string' do
        expect(Platform.new('MACOS')).to eq(Platform.macos)
        expect(Platform.new('macOS')).to eq(Platform.macos)
        expect(Platform.new('macos')).to eq(Platform.macos)

        expect(Platform.new('iOS')).to eq(Platform.ios)
        expect(Platform.new('IOS')).to eq(Platform.ios)
        expect(Platform.new('ios')).to eq(Platform.ios)

        expect(Platform.new('tvos')).to eq(Platform.tvos)
        expect(Platform.new('tvOS')).to eq(Platform.tvos)
        expect(Platform.new('TVOS')).to eq(Platform.tvos)

        expect(Platform.new('watchOS')).to eq(Platform.watchos)
        expect(Platform.new('WATCHOS')).to eq(Platform.watchos)
        expect(Platform.new('watchos')).to eq(Platform.watchos)

        expect(Platform.new('visionos')).to eq(Platform.visionos)
        expect(Platform.new('VISIONOS')).to eq(Platform.visionos)
        expect(Platform.new('visionOS')).to eq(Platform.visionos)
        # Recognizes xrOS
        expect(Platform.new('xros')).to eq(Platform.visionos)
        expect(Platform.new('XROS')).to eq(Platform.visionos)
        expect(Platform.new('xrOS')).to eq(Platform.visionos)
      end

      it 'exposes its name as string' do
        expect(Platform.ios.string_name).to eq('iOS')
        expect(Platform.osx.string_name).to eq('macOS')
        expect(Platform.tvos.string_name).to eq('tvOS')
        expect(Platform.visionos.string_name).to eq('visionOS')
        expect(Platform.watchos.string_name).to eq('watchOS')
      end

      it 'exposes a safe variant of its name as string' do
        expect(Platform.ios.safe_string_name).to eq('iOS')
        expect(Platform.osx.safe_string_name).to eq('macOS')
        expect(Platform.tvos.safe_string_name).to eq('tvOS')
        expect(Platform.visionos.safe_string_name).to eq('visionOS')
        expect(Platform.watchos.safe_string_name).to eq('watchOS')
      end

      it 'can be compared for equality with another platform with the same symbolic name' do
        expect(@platform).to eq(Platform.new(:ios))
      end

      it 'can be compared for equality with another platform with the same symbolic name and the same deployment target' do
        expect(@platform).not_to eq(Platform.new(:ios, '4.0'))
        expect(Platform.new(:ios, '4.0')).to eq(Platform.new(:ios, '4.0'))
      end

      it 'can be compared for equality with a matching symbolic name (backwards compatibility reasons)' do
        expect(@platform).to eq(:ios)
      end

      it 'presents an accurate string representation' do
        expect(@platform.to_s).to eq('iOS')
        expect(Platform.new(:osx).to_s).to eq('macOS')
        expect(Platform.new(:visionos).to_s).to eq('visionOS')
        expect(Platform.new(:watchos).to_s).to eq('watchOS')
        expect(Platform.new(:tvos).to_s).to eq('tvOS')
        expect(Platform.new(:ios, '5.0.0').to_s).to eq('iOS 5.0.0')
        expect(Platform.new(:osx, '10.7').to_s).to eq('macOS 10.7')
        expect(Platform.new(:visionos, '1.0').to_s).to eq('visionOS 1.0')
        expect(Platform.new(:watchos, '2.0').to_s).to eq('watchOS 2.0')
        expect(Platform.new(:tvos, '9.0').to_s).to eq('tvOS 9.0')
      end

      it 'uses its name as its symbol version' do
        expect(@platform.to_sym).to eq(:ios)
      end

      it 'allows to specify the deployment target on initialization' do
        p = Platform.new(:ios, '4.0.0')
        expect(p.deployment_target).to eq(Version.new('4.0.0'))
      end

      it 'allows to specify the deployment target in a hash on initialization (backwards compatibility from 0.6)' do
        p = Platform.new(:ios,  :deployment_target => '4.0.0')
        expect(p.deployment_target).to eq(Version.new('4.0.0'))
      end

      it 'can be sorted by name' do
        p_1 = Platform.new(:ios, '4.0')
        p_2 = Platform.new(:osx, '10.6')
        expect(p_1 <=> p_2).to eq(-1)
        expect(p_1 <=> p_1).to eq(0)
        expect(p_2 <=> p_1).to eq(1)
      end

      it 'can be sorted by deployment_target' do
        p_1 = Platform.new(:ios, '4.0')
        p_2 = Platform.new(:ios, '6.0')
        expect(p_1 <=> p_2).to eq(-1)
        expect(p_1 <=> p_1).to eq(0)
        expect(p_2 <=> p_1).to eq(1)
      end

      it 'returns whether it requires legacy iOS architectures' do
        expect(Platform.new(:ios, '4.0').requires_legacy_ios_archs?).to be(true)
        expect(Platform.new(:ios, '5.0').requires_legacy_ios_archs?).to be(false)
        expect(Platform.new(:visionos, '1.0').requires_legacy_ios_archs?).to be(false)
        expect(Platform.new(:watchos, '2.0').requires_legacy_ios_archs?).to be(false)
        expect(Platform.new(:tvos, '9.0').requires_legacy_ios_archs?).to be(false)
      end

      it 'is usable as hash keys' do
        ios   = Platform.new(:ios)
        osx   = Platform.new(:osx)
        ios6  = Platform.new(:ios, '6.0')
        ios61 = Platform.new(:ios, '6.1')
        hash  = { ios => ios, osx => osx, ios6 => ios6, ios61 => ios61 }
        expect(hash[Platform.new(:ios)]).to eql(ios)
        expect(hash[Platform.new(:osx)]).to eql(osx)
        expect(hash[Platform.new(:ios, '6.0')]).to eql(ios6)
        expect(hash[Platform.new(:ios, '6.1')]).to eql(ios61)
      end

      describe '#supports_dynamic_frameworks?' do
        it 'supports dynamic frameworks on OSX' do
          expect(Platform.osx.supports_dynamic_frameworks?).to be_truthy
          expect(Platform.new(:osx, '10.7').supports_dynamic_frameworks?).to be_truthy
          expect(Platform.new(:osx, '10.10').supports_dynamic_frameworks?).to be_truthy
        end

        it 'supports dynamic frameworks on iOS since version 8.0' do
          expect(Platform.ios.supports_dynamic_frameworks?).to be_falsey
          expect(Platform.new(:ios, '7.0').supports_dynamic_frameworks?).to be_falsey
          expect(Platform.new(:ios, '8.0').supports_dynamic_frameworks?).to be_truthy
          expect(Platform.new(:ios, '8.1').supports_dynamic_frameworks?).to be_truthy
        end

        it 'supports dynamic frameworks on visionOS' do
          expect(Platform.visionos.supports_dynamic_frameworks?).to be_truthy
          expect(Platform.new(:visionos, '1.0').supports_dynamic_frameworks?).to be_truthy
        end

        it 'supports dynamic frameworks on watchOS' do
          expect(Platform.watchos.supports_dynamic_frameworks?).to be_truthy
          expect(Platform.new(:watchos, '2.0').supports_dynamic_frameworks?).to be_truthy
        end

        it 'supports dynamic frameworks on tvOS' do
          expect(Platform.tvos.supports_dynamic_frameworks?).to be_truthy
          expect(Platform.new(:tvos, '9.0').supports_dynamic_frameworks?).to be_truthy
        end
      end
    end

    describe 'Supporting other platforms' do
      it 'supports platforms with the same operating system' do
        p1 = Platform.new(:ios)
        p2 = Platform.new(:ios)
        expect(p1.supports?(p2)).to be_truthy

        p1 = Platform.new(:osx)
        p2 = Platform.new(:osx)
        expect(p1.supports?(p2)).to be_truthy
      end

      it 'supports a platform with a lower or equal deployment_target' do
        p1 = Platform.new(:ios, '5.0')
        p2 = Platform.new(:ios, '4.0')
        expect(p1.supports?(p1)).to be_truthy
        expect(p1.supports?(p2)).to be_truthy
        expect(p2.supports?(p1)).to be_falsey
      end

      it "doesn't supports a platform with a different operating system" do
        p1 = Platform.new(:ios)
        p2 = Platform.new(:osx)
        expect(p1.supports?(p2)).to be_falsey
      end

      it 'returns the string name of a given symbolic name' do
        expect(Platform.string_name(:ios)).to eq('iOS')
        expect(Platform.string_name(:osx)).to eq('macOS')
        expect(Platform.string_name(:win)).to eq('win')
      end
    end
  end
end
