# EyeDropLogger Web (PWA)

ブラウザ／ホーム画面から使えるシンプルな目薬ログアプリ。

## できること
* 3 種類の目薬を選択してワンタップ記録
* 直近 180 日の履歴をローカル保存 (`localStorage`)
* オフライン対応（Service Worker）
* ホーム画面追加でネイティブ風 UI

## ファイル構成
| ファイル | 役割 |
|--|--|
| `index.html` | 画面レイアウト |
| `main.js` | ロジック・保存・描画 |
| `manifest.json` | PWA 設定 |
| `service-worker.js` | オフラインキャッシュ |
| `icon.png` | アプリアイコン (任意) |

## ローカルで試す
```bash
# 任意の HTTP サーバで公開する例（Python 3）
cd EyeDropLoggerWeb
python -m http.server 8000
```
`http://localhost:8000` を開くと動きます。

## GitHub Pages で公開 (静的)
1. このフォルダをリポジトリのルートに push
2. GitHub ▸ Settings ▸ Pages ▸ Source で `main / (root)` を選択
3. 数十秒後に `https://<user>.github.io/<repo>/` でアクセス可能

## Netlify で公開
1. Netlify で New site ▸ Import from Git
2. ビルドコマンド不要、Publish directory=`/` のまま

どちらも HTTPS で配信されるため iOS でも PWA としてインストールできます。

---
初回アクセス後に「ホーム画面に追加」すれば、App Store インストール不要でいつでも起動できます。
