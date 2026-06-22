{ config, ... }:
{
  # 値は基本的に現在の Mac の `defaults read` から取得したものを反映。
  # nix-darwin の `system.defaults` でカバーできない項目は activationScripts で実行する。

  # CapsLock を Control にリマップ (内蔵キーボード・接続中の外付け含め全デバイス対象)
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };

  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      AppleShowAllExtensions = true;
      AppleShowScrollBars = "Always";
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      ApplePressAndHoldEnabled = false;
      "com.apple.mouse.tapBehavior" = 1;
      "com.apple.trackpad.scaling" = 2.0;
    };

    dock = {
      autohide = false;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.0;
      orientation = "left";
      show-recents = false;
      mru-spaces = false;
      mineffect = "scale";
      tilesize = 64;
    };

    finder = {
      _FXShowPosixPathInTitle = true;
      _FXSortFoldersFirst = true;
      AppleShowAllExtensions = true;
      ShowPathbar = true;
      ShowStatusBar = true;
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "Nlsv";
    };

    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = false;
    };

    screencapture.type = "jpg";

    menuExtraClock.ShowSeconds = true;

    LaunchServices.LSQuarantine = false;

    # nix-darwin の専用 attribute が無い項目はここで書く
    CustomUserPreferences = {
      NSGlobalDomain = {
        AppleEnableSwipeNavigateWithScrolls = true;
        "com.apple.mouse.scaling" = 1.5;
        "com.apple.swipescrolldirection" = true;
        "com.apple.trackpad.forceClick" = true;
      };
      "com.apple.finder" = {
        WarnOnEmptyTrash = false;
      };
      "com.apple.AppleMultitouchTrackpad" = {
        ActuateDetents = 1;
        DragLock = 0;
        Dragging = 0;
        FirstClickThreshold = 1;
        ForceSuppressed = 0;
        SecondClickThreshold = 1;
        TrackpadCornerSecondaryClick = 2;
        TrackpadFiveFingerPinchGesture = 2;
        TrackpadFourFingerHorizSwipeGesture = 2;
        TrackpadFourFingerPinchGesture = 2;
        TrackpadFourFingerVertSwipeGesture = 2;
        TrackpadHandResting = 1;
        TrackpadHorizScroll = 1;
        TrackpadMomentumScroll = 1;
        TrackpadPinch = 1;
        TrackpadRotate = 1;
        TrackpadScroll = 1;
        TrackpadThreeFingerHorizSwipeGesture = 1;
        TrackpadThreeFingerTapGesture = 0;
        TrackpadThreeFingerVertSwipeGesture = 1;
        TrackpadTwoFingerDoubleTapGesture = 1;
        TrackpadTwoFingerFromRightEdgeSwipeGesture = 3;
        USBMouseStopsTrackpad = 0;
      };
      "com.apple.driver.AppleBluetoothMultitouch.trackpad" = {
        DragLock = 0;
        Dragging = 0;
        TrackpadCornerSecondaryClick = 2;
        TrackpadFiveFingerPinchGesture = 2;
        TrackpadFourFingerHorizSwipeGesture = 2;
        TrackpadFourFingerPinchGesture = 2;
        TrackpadFourFingerVertSwipeGesture = 2;
        TrackpadHandResting = 1;
        TrackpadHorizScroll = 1;
        TrackpadMomentumScroll = 1;
        TrackpadPinch = 1;
        TrackpadRotate = 1;
        TrackpadScroll = 1;
        TrackpadThreeFingerHorizSwipeGesture = 1;
        TrackpadThreeFingerTapGesture = 0;
        TrackpadThreeFingerVertSwipeGesture = 1;
        TrackpadTwoFingerDoubleTapGesture = 1;
        TrackpadTwoFingerFromRightEdgeSwipeGesture = 3;
        USBMouseStopsTrackpad = 0;
      };
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
      };
      "com.apple.terminal" = {
        StringEncodings = [ 4 ];
      };
      "com.apple.CrashReporter" = {
        DialogType = "none";
      };
      "com.apple.menuextra.battery" = {
        ShowPercent = "YES";
      };
    };
  };

  # nix-darwin の activation は root で動くため、ユーザー権限が必要なものは
  # `sudo -u <primaryUser>` で wrap する
  system.activationScripts.postActivation.text = ''
    primaryUser="${config.system.primaryUser}"

    # 電源管理: ディスプレイは常時 ON、システムスリープは AC 接続時はしない、
    # バッテリー使用時のみ 5 分でスリープ (現在の Mac の実値に合わせる)
    /usr/bin/pmset -c displaysleep 0 sleep 0
    /usr/bin/pmset -b displaysleep 0 sleep 5

    # DNS (Wi-Fi): IPv6 / IPv4 の Google Public DNS を併用
    /usr/sbin/networksetup -setdnsservers Wi-Fi \
      2001:4860:4860::8844 2001:4860:4860::8888 8.8.4.4 8.8.8.8 || true

    # ByHost 領域は system.defaults では届かないのでユーザー権限で個別に書き込む
    /usr/bin/sudo -u "$primaryUser" /usr/bin/defaults -currentHost write \
      NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    /usr/bin/sudo -u "$primaryUser" /usr/bin/defaults -currentHost write \
      NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior -int 1
    /usr/bin/sudo -u "$primaryUser" /usr/bin/defaults -currentHost write \
      NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true

    # Spotlight を完全停止して Raycast に完全移行
    # 1) 全ボリュームのメタデータインデックスを OFF (mds/mdworker の負荷ゼロ化)
    /usr/sbin/mdutil -a -i off || true
    # 2) Spotlight UI (⌘Space) のサービス自体を無効化
    /bin/launchctl disable "system/com.apple.Spotlight" || true
    # 3) ⌘Space のシステムショートカットを無効化し、Raycast に譲る
    #    symbolichotkeys ID 64 = Show Spotlight search, ID 65 = Show Finder search
    /usr/bin/sudo -u "$primaryUser" /usr/bin/defaults write \
      com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 \
      '{ enabled = 0; value = { parameters = (32, 49, 1048576); type = standard; }; }'
    /usr/bin/sudo -u "$primaryUser" /usr/bin/defaults write \
      com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 65 \
      '{ enabled = 0; value = { parameters = (32, 49, 1572864); type = standard; }; }'
    # symbolichotkeys の変更を OS に再読込させる
    /usr/bin/sudo -u "$primaryUser" /usr/bin/killall cfprefsd >/dev/null 2>&1 || true

    # 全ての defaults を書き終えた最後に、影響アプリをまとめて 1 回だけ再起動
    /usr/bin/sudo -u "$primaryUser" /usr/bin/killall Dock Finder SystemUIServer \
      >/dev/null 2>&1 || true
  '';
}
