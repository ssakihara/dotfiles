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
        "com.apple.mouse.scaling" = 1.5;
      };
      "com.apple.finder" = {
        WarnOnEmptyTrash = false;
      };
      "com.apple.driver.AppleBluetoothMultitouch.trackpad" = {
        TrackpadCornerSecondaryClick = 2;
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

    # 全ての defaults を書き終えた最後に、影響アプリをまとめて 1 回だけ再起動
    /usr/bin/sudo -u "$primaryUser" /usr/bin/killall Dock Finder SystemUIServer \
      >/dev/null 2>&1 || true
  '';
}
