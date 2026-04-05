---
name: ue5-build
description: >
  UE5（Unreal Engine 5）をWindowsソース環境でビルドするための支援スキル。
  ユーザーが「UE5をビルドしたい」「Unreal Editorをコンパイルしたい」「DebugGameビルドを走らせたい」
  「UBTのエラーが出た」「GenerateProjectFilesを実行したい」「ビルドプロセスが競合していないか確認したい」
  などと言ったとき、または UnrealBuildTool / Build.bat / UE5ビルドに関するエラーメッセージを貼り付けたときに
  必ずこのスキルを使うこと。Perforce環境を前提とし、GitHub取得ステップは含まない。
---

# UE5 ソースビルド支援スキル

このスキルはWindows上でUE5ソースをビルドするフローを支援する。
**基本ターゲット**: `UnrealEditor` / `Win64` / `DebugGame`

---

## Step 1: UE5ルートディレクトリの確認

まずユーザーにUE5ソースのルートパスを確認する（例: `D:\UE5\Engine` があるなら `D:\UE5` がルート）。

ルート直下に以下が存在することを確認:
- `Engine\Build\BatchFiles\Build.bat`
- `Engine\Source\`
- `UE5.sln` または `.uproject` に対応するプロジェクトファイル

---

## Step 2: 排他的ビルドチェック（重要）

UE5のビルドは**排他的**である。複数のビルドプロセスが同時に動くと失敗または破損する。
ビルド前に必ず以下のプロセスが動いていないことを確認するようユーザーに指示する:

```powershell
# 競合するプロセスを確認するコマンド
tasklist /FI "IMAGENAME eq MSBuild.exe"
tasklist /FI "IMAGENAME eq UnrealBuildTool.exe"
tasklist /FI "IMAGENAME eq cl.exe"
tasklist /FI "IMAGENAME eq xgConsole.exe"
tasklist /FI "IMAGENAME eq xge.exe"
```

競合プロセスがある場合:
- Visual Studioのビルドを停止
- 他のClaudeセッションやCIのビルドが動いていないか確認
- Incredibuildが動いている場合はジョブの完了を待つか停止する

プロセスが何も見つからなければ次のステップへ。

---

## Step 3: ビルドコマンドの実行

### 通常ビルド（推奨）

UE5ルートで以下を実行:

```batch
Engine\Build\BatchFiles\Build.bat UnrealEditor Win64 DebugGame -WaitMutex
```

**引数の意味**:
- `UnrealEditor` — ビルドターゲット（エディタ本体）
- `Win64` — プラットフォーム
- `DebugGame` — コンフィギュレーション（エンジンはリリース最適化、ゲームコードはデバッグ）
- `-WaitMutex` — 他のUBTプロセスが終わるまで待機（排他制御の補助）

### オプション: クリーンビルド

キャッシュや中間ファイルが原因と思われるときは先にCleanを実行:

```batch
Engine\Build\BatchFiles\Clean.bat UnrealEditor Win64 DebugGame
Engine\Build\BatchFiles\Build.bat UnrealEditor Win64 DebugGame -WaitMutex
```

### オプション: GenerateProjectFiles

`.sln` が壊れている、または初回セットアップ時:

```batch
Engine\Build\BatchFiles\GenerateProjectFiles.bat
```

---

## Step 4: ビルド結果の確認

**成功時**: ログ末尾に `BUILD SUCCESSFUL` または `Build successful.` が表示される。

生成されるバイナリ:
```
Engine\Binaries\Win64\UnrealEditor.exe         (実行ファイル)
Engine\Binaries\Win64\UnrealEditor-Win64-DebugGame.dll  (ゲームコードDLL)
```

---

## よくあるエラーと対処法

### `ERROR: Couldn't find target rules file`
- UE5ルートが間違っている可能性が高い
- `Build.bat` をUE5ルートから実行しているか確認
- プロジェクト固有のターゲットをビルドしようとしている場合は `.uproject` のパスを指定

### `error C1083: Cannot open include file` / ヘッダが見つからない
- Intermediateフォルダのキャッシュ破損の可能性
- `Engine\Intermediate\` と `Engine\Saved\` を削除してリビルド
- `GenerateProjectFiles.bat` を再実行してから再ビルド

### リンクエラー (`LNK2001`, `LNK1120`)
- Binariesフォルダを削除してClean → ビルド
- PCH（プリコンパイル済みヘッダ）の不整合が原因のことが多い

### `MSVC version` / `Windows SDK version` エラー
- Visual StudioのインストールでC++デスクトップ開発ワークロードが入っているか確認
- UE5が要求するMSVCバージョンは `Engine\Build\BuildConfiguration.xml` または公式ドキュメントで確認
- 複数のVSバージョンが入っている場合、UE5が想定するバージョンを優先させる

### `The process cannot access the file because it is being used by another process`
- Step 2の排他的ビルドチェックに戻る
- アンチウイルスが `Engine\Intermediate\` を掴んでいるケースもあるので除外設定を確認

### `Mutex` 待機が長い / タイムアウト
- `-WaitMutex` を外して強制実行するか、`UnrealBuildTool.exe` プロセスを手動で終了して再試行

---

## 関連スキル

- **ue5-game-build** (予定): GameターゲットやShippingビルドのチェック支援
