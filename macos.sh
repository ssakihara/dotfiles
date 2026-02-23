# Trackpad: enable tap to click for this user and for the login screen
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Trackpad: map bottom right corner to right-click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
defaults -currentHost write NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior -int 1
defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true

# Disable Dashboard
defaults write com.apple.dashboard mcx-disabled -bool true
# Remove the auto-hiding Dock delay
defaults write com.apple.dock autohide-delay -float 0
# Remove the animation when hiding/showing the Dock
defaults write com.apple.dock autohide-time-modifier -float 0
# Automatically hide and show the Dock
defaults write com.apple.dock autohide -bool false
# Dockを左に
defaults write com.apple.dock "orientation" -string "left"

###############################################################################
# Display & Power                                                          #
###############################################################################

# ダークモードを有効化
defaults write -g AppleInterfaceStyle -string "Dark"

# ディスプレイ/スリープ設定（開発用に遅めに設定）
# 注意: これらの設定には管理者権限(sudo)が必要です
# -c: 電源接続時、-b: バッテリー使用時
# 画面は消えないようにする（システムスリープのみ10分）
sudo pmset -c displaysleep 0 sleep 10

# バッテリー使用時も画面は消えないようにする（システムスリープのみ10分）
# 注意: この設定はバッテリー消費を増加させます。開発時の生産性重視の設定です。
sudo pmset -b displaysleep 0 sleep 10

###############################################################################
# Speed up animations                                                        #
###############################################################################
defaults write -g com.apple.trackpad.scaling 2 && \
defaults write -g com.apple.mouse.scaling 1.5 && \
defaults write -g KeyRepeat -int 2 && \
defaults write -g InitialKeyRepeat -int 15

# タップしたときクリック
defaults write -g com.apple.mouse.tapBehavior -int 1

# 三本指でドラッグ (macOS Sequoia/Tahoe対応)
# NSGlobalDomainの設定はmacOS Ventura以降で必須
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true && \
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true && \
defaults write NSGlobalDomain com.apple.trackpad.threeFingerDragGesture -int 1

# スクロールバーを常時表示する
defaults write -g AppleShowScrollBars -string "Always"

# クラッシュレポートを無効化する
defaults write com.apple.CrashReporter DialogType -string "none"

# 未確認のアプリケーションを実行する際のダイアログを無効にする
defaults write com.apple.LaunchServices LSQuarantine -bool false

# ダウンロードしたファイルを開くときの警告ダイアログをなくしたい
defaults write com.apple.LaunchServices LSQuarantine -bool false

# ゴミ箱を空にする前の警告の無効化
defaults write com.apple.finder WarnOnEmptyTrash -bool false

# スペルの訂正を無効にする
defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false

# terminalでUTF-8のみを使用する
defaults write com.apple.terminal StringEncodings -array 4

# ネットを早くする
networksetup -setdnsservers Wi-Fi 2001:4860:4860::8844 2001:4860:4860::8888 8.8.4.4 8.8.8.8

# スクリーンショットをjpgで保存
defaults write com.apple.screencapture type jpg

# 全ての拡張子のファイルを表示する
defaults write -g AppleShowAllExtensions -bool true

# Finder のタイトルバーにフルパスを表示する
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# 名前で並べ替えを選択時にディレクトリを前に置くようにする
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# .DS_Storeファイルを作らせない
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool TRUE

# 時計を秒まで表示する
defaults write com.apple.menuextra.clock DateFormat -string "M\\U6708d\\U65e5(EEE)  H:mm:ss"
defaults write com.apple.menuextra.clock ShowSeconds -int 1

# 動かないかも
# バッテリーの割合（%）を表示
defaults write com.apple.menuextra.battery ShowPercent -string "YES"

###############################################################################
# Kill affected applications                                                  #
###############################################################################

for app in "Activity Monitor" \
	"Address Book" \
	"Calendar" \
	"cfprefsd" \
	"Contacts" \
	"Dock" \
	"Finder" \
	"Google Chrome Canary" \
	"Google Chrome" \
	"Mail" \
	"Messages" \
	"Opera" \
	"Photos" \
	"Safari" \
	"SizeUp" \
	"Spectacle" \
	"SystemUIServer" \
	"Terminal" \
	"Transmission" \
	"Tweetbot" \
	"Twitter" \
	"iCal"; do
	killall "${app}" &> /dev/null
done
