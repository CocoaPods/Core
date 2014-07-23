module SamplePodfiles
    # String representations of sample YAML  
  def self.yaml_string
    <<-LOCKFILE.strip_heredoc
        PODS:
          - BananaLib (1.0):
            - monkey (< 1.0.9, ~> 1.0.1)
          - JSONKit (1.4)
          - monkey (1.0.8)

        DEPENDENCIES:
          - BananaLib (~> 1.0)
          - JSONKit (from `path/JSONKit.podspec`)

        EXTERNAL SOURCES:
          JSONKit:
            podspec: path/JSONKit.podspec

        SPEC CHECKSUMS:
          BananaLib: 439d9f683377ecf4a27de43e8cf3bce6be4df97b
          JSONKit: 92ae5f71b77c8dec0cd8d0744adab79d38560949

        COCOAPODS: 1.0.0
    LOCKFILE
  end

  def self.yaml_string_with_merge_conflict
    <<-LOCKFILE.strip_heredoc
      PODS:
      - MBProgressHUD (0.8)
          - Mixpanel (2.3.6)
        <<<<<<< HEAD
          - pop (1.0.5)
        =======
          - pop (1.0.6)
          - Reveal-iOS-SDK (1.0.4)
        >>>>>>> da804112d3187fa622124027f24ae233262b2df0
          - SBJson (3.2)
          - TestFlightSDK (3.0.2)

        DEPENDENCIES:
          - AFNetworking (~> 2.0.1)
          - AGPhotoBrowser (~> 1.0.2)
          - BButton (~> 3.2.3)
          - Facebook-iOS-SDK (~> 3.14)
          - FXBlurView (~> 1.4.4)
          
        SPEC CHECKSUMS:
          AFNetworking: a4d0e9a64de9242986620dafd1b3cee3b413ac5c
          AGPhotoBrowser: 04ae5368da3ab003e2c27ac1058bd01d64858893
          BButton: 3aa14643d262a5ca62012462d3e27c6bbe843c85
          Bolts: 91c2af8eae1d44e1dd75946a5b0ae04a43ea43e4
          Facebook-iOS-SDK: d67a9aa373f28b581e00cefdfd5a1ab8f883ac14
          FXBlurView: 74d89486a2c93dbfed58f8e06ce5ae8b4c2ff92b
          HPGrowingTextView: 58b5caa61ff7f3d53b197d9da0361b1c7e09b110
          MBProgressHUD: c356980b0cd097f19acec959b49dca5eb8ec31be
          Mixpanel: 9aba38257fc4d2777ab5db1afc55e22bdfd57a4a
        <<<<<<< HEAD
          pop: 75fa2b33934200a8a68abb449ac1726fcf7e43b9
        =======
          pop: e518794da38942c05255eb64b36d894e70cb4f00
          Reveal-iOS-SDK: d3c8e109d42219daaa7a6e1ad2de34f0bdbb7a88
        >>>>>>> da804112d3187fa622124027f24ae233262b2df0
          SBJson: 72d7da8a5bf6c236e87194abb10ac573a8bccbef
          SDWebImage: 571295c8acbb699505a0f68e54506147c3de9ea7
          SVProgressHUD: 5034c6e22b8c2ca3e09402e48d41ed0340aa1c50
          SVPullToRefresh: d5161ebc833a38b465364412e5e307ca80bbb190
          TestFlightSDK: 0c24c533748d0d84bfe7a3cb6036fa79124d84ee
      COCOAPODS: 0.33.1
    LOCKFILE
  end

  def self.bad_yaml_string
    <<-LOCKFILE.strip_heredoc
      PODS:
        - Kiwi (2.2)
        SOME BAD TEXT

      DEPENDENCIES:
        - Kiwi
        - ObjectiveSugar (from `../`)

      COCOAPODS: 0.29.0
    LOCKFILE
  end

  # File Representations of the above sample YAML
  def self.yaml_file
    return File.new('Podfile.lock', 'w') do |f|
      f.write(sample_yaml_string)
    end
  end

  def self.yaml_file_with_merge_conflict
    return File.new('Podfile.lock', 'w') do |f|
      f.write(yaml_string_with_merge_conflict)
    end
  end

  def self.bad_yaml_file
    return File.new('Podfile.lock', 'w') do |f|
      f.write(bad_yaml_string)
    end
  end
end
