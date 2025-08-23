# 🚀 GitHub公開手順 - IshimuraIyori

## ステップ1: GitHubでフォーク

1. https://github.com/espresso3389/pdfrx にアクセス
2. 右上の「Fork」ボタンをクリック
3. あなたのアカウント（IshimuraIyori）にフォークされる

## ステップ2: ローカル変更をプッシュ

```bash
# フォークをクローン
git clone https://github.com/IshimuraIyori/pdfrx.git
cd pdfrx

# progressive-loadingブランチを作成
git checkout -b progressive-loading

# 変更済みファイルをコピー
# (既に変更済みの /Users/iyori/pdfrx から以下のファイルをコピー)
cp /Users/iyori/pdfrx/packages/pdfrx/lib/src/widgets/pdf_widgets.dart packages/pdfrx/lib/src/widgets/pdf_widgets.dart

# READMEを追加
cp /Users/iyori/pdfrx/README_FOR_GITHUB.md README.md

# コミット
git add .
git commit -m "Add progressive loading support with aspect ratio pre-loading

- useProgressiveLoading parameter for two-pass rendering
- loadOnlyTargetPage for memory optimization
- Pre-loads page dimensions before rendering
- Shows correct aspect ratio immediately"

# GitHubにプッシュ
git push -u origin progressive-loading
```

## ステップ3: リリースタグを作成（オプション）

```bash
git tag v1.0.0-progressive
git push origin v1.0.0-progressive
```

## ✅ 公開完了！

これで誰でも以下の方法で使用可能：

### pubspec.yaml

```yaml
dependencies:
  pdfrx:
    git:
      url: https://github.com/IshimuraIyori/pdfrx.git
      ref: progressive-loading  # または v1.0.0-progressive
      path: packages/pdfrx
```

## 📢 共有用テキスト

```
PDFrxにプログレッシブローディング機能を追加しました！

✨ 特徴:
- 正しいアスペクト比で即座に表示
- 2段階レンダリング（低品質→高品質）
- メモリ効率的な単一ページ読み込み

📦 使い方:
dependencies:
  pdfrx:
    git:
      url: https://github.com/IshimuraIyori/pdfrx.git
      ref: progressive-loading
      path: packages/pdfrx

詳細: https://github.com/IshimuraIyori/pdfrx/tree/progressive-loading
```

## 📝 GitHubリポジトリの説明文

リポジトリのAboutセクションに追加：

```
Fork of pdfrx with progressive loading support - Display PDFs with correct aspect ratio immediately
```

Topics:
- flutter
- pdf
- pdf-viewer
- progressive-loading
- dart

## 🔄 更新の同期

オリジナルの更新を取り込む場合：

```bash
# オリジナルをupstreamとして追加（初回のみ）
git remote add upstream https://github.com/espresso3389/pdfrx.git

# 最新の変更を取得
git fetch upstream
git checkout progressive-loading
git merge upstream/master

# 競合を解決後、プッシュ
git push origin progressive-loading
```

## ⚡ クイックコピー用コマンド

全部まとめて実行：

```bash
git clone https://github.com/IshimuraIyori/pdfrx.git pdfrx-fork && \
cd pdfrx-fork && \
git checkout -b progressive-loading && \
cp /Users/iyori/pdfrx/packages/pdfrx/lib/src/widgets/pdf_widgets.dart packages/pdfrx/lib/src/widgets/pdf_widgets.dart && \
cp /Users/iyori/pdfrx/README_FOR_GITHUB.md README.md && \
git add . && \
git commit -m "Add progressive loading support" && \
git push -u origin progressive-loading
```

---

準備完了！ 🎉