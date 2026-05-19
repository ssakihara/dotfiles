{ lib, username, ... }:
{
  # SSH 関連の初期化を activation 時に実行する。
  # - ~/.ssh ディレクトリと鍵の権限を正規化
  # - id_ed25519 が未生成ならパスフレーズなしで作成
  system.activationScripts.postActivation.text = lib.mkAfter ''
    sshDir="/Users/${username}/.ssh"
    /usr/bin/sudo -u "${username}" /bin/mkdir -p "$sshDir"
    /usr/sbin/chown ${username} "$sshDir"
    /bin/chmod 700 "$sshDir"

    key="$sshDir/id_ed25519"
    if [ ! -e "$key" ]; then
      /usr/bin/sudo -u "${username}" /usr/bin/ssh-keygen \
        -t ed25519 -N "" -C "${username}@$(/bin/hostname -s)" -f "$key"
    fi

    # 既存鍵を含めて権限を正規化 (秘密鍵 600 / 公開鍵 644 / config 600)
    /bin/chmod 600 "$sshDir"/id_* 2>/dev/null || true
    /bin/chmod 600 "$sshDir"/*_rsa 2>/dev/null || true
    /bin/chmod 644 "$sshDir"/*.pub 2>/dev/null || true
    [ -f "$sshDir/config" ] && /bin/chmod 600 "$sshDir/config" || true
  '';
}
