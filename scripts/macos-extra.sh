#!/bin/bash
# mise の [bootstrap.macos.defaults] で扱えない macOS 設定を適用する。
# (array / dict / -currentHost / sudo が必要なもの / killall)
# mise bootstrap の post-defaults hook から実行される。冪等に保つこと。
set -euo pipefail

# Terminal の文字エンコーディング (array 型のため mise 非対応)
defaults write com.apple.terminal StringEncodings -array 4

# ByHost 領域 (-currentHost) は mise 非対応
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults -currentHost write NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior -int 1
defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true

# Spotlight の ⌘Space ショートカットを無効化し、Raycast に譲る (dict 型のため mise 非対応)
# symbolichotkeys ID 64 = Show Spotlight search, ID 65 = Show Finder search
# NeXT 形式 '{ enabled = 0; }' は数値が文字列で書き込まれ Tahoe 以降の Spotlight に
# 無視されるため、型が明示できる XML plist 形式で書き込むこと
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 \
  '<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>1048576</integer></array><key>type</key><string>standard</string></dict></dict>'
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 65 \
  '<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>1572864</integer></array><key>type</key><string>standard</string></dict></dict>'

# symbolichotkeys の配送は WindowServer 側が担うため、plist を書くだけでは
# 実行中のセッションに反映されない。activateSettings で再読込を通知する
# (私有フレームワーク内のツールのため、将来の macOS で消えても止まらないようガード)
activateSettings="/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings"
[ -x "$activateSettings" ] && "$activateSettings" -u || true

# sudo を Touch ID で認証可能にする (macOS ネイティブの sudo_local 機構)
if ! sudo grep -qs '^auth.*pam_tid\.so' /etc/pam.d/sudo_local 2>/dev/null; then
  printf 'auth       sufficient     pam_tid.so\n' | sudo tee /etc/pam.d/sudo_local >/dev/null
fi

# 電源管理: ディスプレイは常時 ON、システムスリープは AC 接続時はしない、
# バッテリー使用時のみ 5 分でスリープ
sudo /usr/bin/pmset -c displaysleep 0 sleep 0
sudo /usr/bin/pmset -b displaysleep 0 sleep 5

# DNS (Wi-Fi): IPv6 / IPv4 の Google Public DNS を併用
sudo /usr/sbin/networksetup -setdnsservers Wi-Fi \
  2001:4860:4860::8844 2001:4860:4860::8888 8.8.4.4 8.8.8.8 || true

# Spotlight を完全停止して Raycast に完全移行。
# system ドメインの無効化だけではユーザーセッション側の Spotlight.app が
# ログイン毎に起動して ⌘Space を掴むため、gui ドメインの無効化が必須
sudo /usr/sbin/mdutil -a -i off || true
sudo /bin/launchctl disable "system/com.apple.Spotlight" || true
/bin/launchctl disable "gui/$(id -u)/com.apple.Spotlight" || true

# 全ての defaults を書き終えた最後に、影響アプリをまとめて 1 回だけ再起動。
# Spotlight は起動時にしかホットキー設定を読まないため、再起動させないと
# symbolichotkeys の無効化が実行中のプロセスに反映されない
/usr/bin/killall cfprefsd >/dev/null 2>&1 || true
/usr/bin/killall Spotlight >/dev/null 2>&1 || true
/usr/bin/killall Dock Finder SystemUIServer >/dev/null 2>&1 || true
