# Mac ゲーミングツールボックス (Mac Gaming Toolbox)

[简体中文](README.md) | [English](README_EN.md) | [日本語](README_JA.md)

Mac ゲーミングツールボックスは、SwiftUI で構築された macOS ネイティブのゲーム環境最適化・支援ツールです。バージョン **3.1.0** では **Apple Silicon (ARM64)** に完全特化し、Apple Human Interface Guidelines (HIG) に準拠したサイドバーレイアウトへとフルリニューアルされました。

---

## 🌟 主な機能

### 1. 概要ダッシュボードとリアルタイム監視
- **ステータスハブ**: Metal HUD、Caffeinate ゲーム集中モード、SteamDeck 偽装、外部マウントディスクの状態を一目で確認。
- **競合プロセス診断**: HUD 有効化前に起動していたゲームランチャーや Wine プロセスを検出し、安全に再起動可能。

### 2. Metal HUD パフォーマンスチューナー・個別プロファイル
- **外観パラメータの完全制御**: 10%〜100% のスケール調整、0〜100% の不透明度、画面四隅の配置に対応。
- **23 項目の表示指標**: 単位と数値例付きのチェックボックスで、必要な情報だけを自在にカスタマイズ。
- **ゲーム個別プロファイル**: ゲームごとに専用の HUD 設定を紐付け、ワンクリックで起動可能。
- **性能診断スナップショット出力**: ハードウェア仕様や測定パラメータを Markdown 形式で出力し、コミュニティ共有や診断に活用。

### 3. ゲーム高速化・コントローラー低遅延化
- **Caffeinate ゲーム集中モード**: ネイティブの `caffeinate` デーモンを実行し、ゲーム中やシェーダーコンパイル時の画面消灯・スリープ・省電力スロットリングを徹底防止。
- **macOS ゲームモード解説**: フルスクリーン表示で DualSense/Xbox コントローラーや AirPods の Bluetooth サンプリングレートを倍増させ、遅延を最小化。
- **CrossOver / Wine プロセス優先度向上**: ゲームプロセスのスケジューリング優先度を最高（Renice -20）に引き上げ。

### 4. ストレージと Windows ゲームセーブデータ管理
- **Windows セーブデータファインダー**: CrossOver、Whisky、Heroic、Wine ボトル内の深いセーブデータ階層（`AppData/Local`、`Saved Games`、`My Games`）を自動スキャン。
- **Finder 表示・Zip バックアップ**: ワンクリックで Finder に表示、または `.zip` 形式で一括バックアップ。
- **カスタムディスクマウント**: 外部 SSD などをゲームデータパスにマウントし、内蔵ストレージの容量を節約。
- **安全なキャッシュ・ログ削除**: 保護対象ファイルを除外しながら、不要なキャッシュを安全にクリーンアップ。

### 5. システムツールとサービス健康診断
- **サービス・権限状態の診断**: 特権ヘルパー（XPC通信）、バックグラウンド実行権限、Metal HUD 環境をワンクリックで診断・自動修復。
- **多言語対応 (日本語・英語・簡体中文)**: システム言語の自動追従およびアプリ内での手動切り替えに対応。
- **SteamDeck ホスト名偽装**: ホスト名を `steamdeck` に一時偽装し、アンチチートのホワイトリスト要件をバイパス。

---

## 📋 更新履歴 (v3.1.0)

- **[UI 刷新]** macOS 標準の `NavigationSplitView` サイドバー構成と標準コントロールを採用。
- **[Metal HUD 進化]** 10%〜100% スケール、透明度、四隅配置、23項目の表示指標、アプリ個別プロファイルに対応。
- **[性能スナップショット]** Markdown 形式の性能診断レポート出力機能を追加。
- **[競合プロセス診断]** 常駐ランチャーを検出し、安全に再起動して HUD 表示を確実に適用。
- **[セーブデータ管理]** Wine/CrossOver/Whisky ボトルのセーブデータを自動スキャン・Zip 保存。
- **[ゲーム集中モード]** Caffeinate デーモンによるスリープ・消灯・性能制限の抑止。
- **[多言語対応]** 日本語・英語・簡体中文の三言語完全ローカライズおよびリアルタイム切替。
- **[サービス診断]** ヘルパーとシステム権限の状態診断、過去の残存ファイルのワンクリッククリーンアップ。
- **[ネイティブ ARM64]** Apple Silicon 専用の軽量高速ビルドに一本化し、Zip 形式で配布。

---

## 💻 動作環境

- macOS 14.0 (Sonoma) 以降
- Apple Silicon Mac (M1 / M2 / M3 / M4 ネイティブ対応)
- ビルド環境: Swift 6, Xcode 16+, Command Line Tools

---

## 📦 ビルドとパッケージング

### リリースビルドと Zip パッケージ作成 (ARM64 のみ)

```bash
git clone https://github.com/Souitou-iop/mac-gaming-toolbox.git
cd mac-gaming-toolbox
ARCHS=arm64 ./Scripts/build-release.sh && ./Scripts/package-zip.sh "build/DerivedData/Build/Products/Release/Mac 游戏工具箱.app" "build/Mac 游戏工具箱-arm64.zip"
```

---

## 📄 ライセンスと謝辞

- ライセンス: [GNU General Public License v3.0](LICENSE)
- オリジナルプロジェクト作者: **我是艾文喵**
  - 元リポジトリ: [aiwentongxue/mac-gaming-toolbox](https://github.com/aiwentongxue/mac-gaming-toolbox)
  - チャンネル: [Bilibili](https://b23.tv/dV7YBJQ) · [YouTube](https://youtube.com/channel/UC0TgypOLHt2fXboVw34SKVQ)
