
# gcloud SSH での NumPy 警告を `uv` で解決する手順

macOS (Homebrew) 等の環境で、システム Python を汚さずに `gcloud` コマンドのパフォーマンスを向上させるための設定ガイドです。

## 1. 専用の仮想環境 (venv) を作成

`uv` を使って、`gcloud` が参照するための独立した Python 環境を作成します。

```bash
uv venv ~/.gcloud-env

```

## 2. NumPy のインストール

作成した仮想環境の Python インタープリタを指定して、`numpy` をインストールします。

```bash
uv pip install numpy --python ~/.gcloud-env/bin/python

```

## 3. 環境変数の設定

`gcloud` が実行時に上記で作成した Python を使用するように、シェルの設定ファイル（`~/.zshrc` または `~/.bashrc`）に環境変数を追記します。

```bash
# ~/.zshrc の末尾に追記
export CLOUDSDK_PYTHON="$HOME/.gcloud-env/bin/python"

```

## 4. 設定の反映

記述した内容を現在のシェルセッションに反映させます。

```bash
source ~/.zshrc

```

## 5. 動作確認

`gcloud` が正しく仮想環境の Python を認識しているか確認します。

```bash
gcloud info --format="value(basic.python_location)"

```

**出力例:** `/Users/あなたのユーザー名/.gcloud-env/bin/python`
