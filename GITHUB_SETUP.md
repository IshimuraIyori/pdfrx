# GitHub Setup Instructions / GitHubセットアップ手順

## 🚀 誰でも使えるようにする手順

### Step 1: GitHub でフォーク
1. https://github.com/espresso3389/pdfrx にアクセス
2. 右上の「Fork」ボタンをクリック
3. あなたのGitHubアカウントにフォーク

### Step 2: フォークしたリポジトリをクローン
```bash
git clone https://github.com/YOUR_USERNAME/pdfrx.git
cd pdfrx
```

### Step 3: このブランチを追加
```bash
# このリポジトリをリモートとして追加
git remote add progressive /Users/iyori/pdfrx

# progressive-loadingブランチを取得
git fetch progressive
git checkout -b progressive-loading progressive/progressive-loading

# あなたのフォークにプッシュ
git push -u origin progressive-loading
```

### Step 4: デフォルトブランチを設定（オプション）
GitHubのリポジトリ設定で：
1. Settings → General → Default branch
2. `progressive-loading`を選択

## 📦 他の人が使う方法

### 方法1: Git URL で直接使用

誰でも以下をpubspec.yamlに追加するだけ：

```yaml
dependencies:
  pdfrx:
    git:
      url: https://github.com/YOUR_USERNAME/pdfrx.git
      path: packages/pdfrx
      ref: progressive-loading
```

### 方法2: 特定のコミットを使用（安定版）

```yaml
dependencies:
  pdfrx:
    git:
      url: https://github.com/YOUR_USERNAME/pdfrx.git
      path: packages/pdfrx
      ref: 85dc986  # 特定のコミットハッシュ
```

## 📝 使用例

```dart
import 'package:pdfrx/pdfrx.dart';

// プログレッシブローディング有効
PdfPageView(
  document: document,
  pageNumber: 1,
  useProgressiveLoading: true,  // 新機能！
)
```

## 🔄 最新版への更新

フォークを最新に保つ：

```bash
# オリジナルを追加（初回のみ）
git remote add upstream https://github.com/espresso3389/pdfrx.git

# 最新を取得
git fetch upstream
git checkout progressive-loading
git merge upstream/master

# 競合解決後、プッシュ
git push origin progressive-loading
```

## 📊 メリット

- ✅ **誰でも使える**: GitHubのURLを指定するだけ
- ✅ **バージョン管理**: コミットハッシュで固定可能
- ✅ **更新可能**: 上流の変更を取り込める
- ✅ **公開**: 世界中から利用可能

## 🌍 共有用テンプレート

以下をコピーして共有：

```markdown
# Progressive Loading PDFrx

高速なPDF表示を実現するpdfrxのフォーク版です。

## インストール
\`\`\`yaml
dependencies:
  pdfrx:
    git:
      url: https://github.com/YOUR_USERNAME/pdfrx.git
      path: packages/pdfrx
      ref: progressive-loading
\`\`\`

## 特徴
- プログレッシブローディング対応
- 正しいアスペクト比で即座に表示
- メモリ効率的な単一ページ読み込み
```

## ⚠️ 注意事項

- フォークのURLを`YOUR_USERNAME`から実際のユーザー名に変更
- プライベートリポジトリの場合は認証が必要
- パブリックリポジトリなら誰でも使用可能

---

これで世界中の誰でもあなたのフォークを使えるようになります！🎉