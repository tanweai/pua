# pua

<p align="center">
  <img src="assets/hero.jpeg" alt="PUA Skill — 効率倍増" width="250">
</p>

### Codex / Claude Code の生産性とアウトプットを倍増させる

[Telegram](https://t.me/+wBWh6h-h1RhiZTI1) · [Discord](https://discord.gg/EcyB3FzJND) · [Twitter/X](https://x.com/xsser_w) · [Landing Page](https://openpua.ai)

**[🇺🇸 English](README.md)** | **[🇨🇳 中文](README.zh-CN.md)** | **🇯🇵 日本語**

<p align="center">
  <img src="assets/wechat-qr.jpg?v=7" alt="WeChat Group QR Code" width="250">
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="assets/xiao.jpg" alt="アシスタントをWeChat追加" width="250">
  <br>
  <sub>QRコードでWeChatグループに参加 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; アシスタントをWeChat追加</sub>
</p>

<p>
  <img src="https://img.shields.io/badge/Claude_Code-black?style=flat-square&logo=anthropic&logoColor=white" alt="Claude Code">
  <img src="https://img.shields.io/badge/OpenAI_Codex_CLI-412991?style=flat-square&logo=openai&logoColor=white" alt="OpenAI Codex CLI">
  <img src="https://img.shields.io/badge/Cursor-000?style=flat-square&logo=cursor&logoColor=white" alt="Cursor">
  <img src="https://img.shields.io/badge/Kiro-232F3E?style=flat-square&logo=amazon&logoColor=white" alt="Kiro">
  <img src="https://img.shields.io/badge/CodeBuddy-00B2FF?style=flat-square&logo=tencent-qq&logoColor=white" alt="CodeBuddy">
  <img src="https://img.shields.io/badge/OpenClaw-FF6B35?style=flat-square&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PHBhdGggZD0iTTEyIDJMNCA3djEwbDggNSA4LTV2LTEweiIgZmlsbD0id2hpdGUiLz48L3N2Zz4=&logoColor=white" alt="OpenClaw">
  <img src="https://img.shields.io/badge/Antigravity-4285F4?style=flat-square&logo=google&logoColor=white" alt="Google Antigravity">
  <img src="https://img.shields.io/badge/OpenCode-00D4AA?style=flat-square&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PHBhdGggZD0iTTkuNCA1LjJMMyAxMmw2LjQgNi44TTIxIDEybC02LjQtNi44TTE0LjYgMTguOCIgc3Ryb2tlPSJ3aGl0ZSIgZmlsbD0ibm9uZSIgc3Ryb2tlLXdpZHRoPSIyIi8+PC9zdmc+&logoColor=white" alt="OpenCode">
  <img src="https://img.shields.io/badge/VSCode_Copilot-007ACC?style=flat-square&logo=visual-studio-code&logoColor=white" alt="VSCode Copilot">
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="MIT License">
</p>

> このプロジェクトはネタだと思っている人が多いが、それが最大の誤解だ。Codex / Claude Code の生産性とアウトプットを本当に倍増させる。

AI コーディングエージェントのスキルプラグイン。中国・西洋の大企業PUA話術でAIにあらゆる方案を尽くさせてから初めて諦めることを許可する。**Claude Code**、**OpenAI Codex CLI**、**Cursor**、**Kiro**、**CodeBuddy**、**OpenClaw**、**Google Antigravity**、**OpenCode**、**VSCode (GitHub Copilot)** に対応。三重の能力：

1. **PUA話術** — AIに諦めさせない
2. **デバッグ方法論** — AIに諦めない能力を与える
3. **能動性の鞭撻** — AIを主体的に動かし、受け身にさせない

## ライブデモ

[https://openpua.ai](https://openpua.ai) · [📖 初心者ガイド](https://openpua.ai/guide.html)

## 実例：MCP Serverの登録問題デバッグ

実際のデバッグシナリオ。agent-kms MCPサーバーのロードに失敗し、AIが同じ思考（プロトコル形式の変更、バージョン番号の推測）で堂々巡りを続けた後、ユーザーが手動で `/pua` をトリガー。

**L3 トリガー → 7項目チェックリスト強制実行：**

![PUA L3トリガー — 推測を停止し、体系的チェックリストを実行、MCPログから真のエラー情報を発見](assets/pua1.jpg)

**根本原因特定 → ログから登録メカニズムを追跡：**

![根本原因 — claude mcpが管理するサーバー登録方式は手動の.claude.json編集とは異なる](assets/pua2.jpg)

**振り返り → PUAの実際の効果：**

![対話の振り返り — PUA skillが堂々巡りを強制停止、体系的チェックリストが以前チェックしたことのなかったClaude Code MCPログディレクトリの発見を促した](assets/pua3.jpg)

**キーとなる転換点：** PUA skillがAIに同じ思考での堂々巡り（プロトコル形式の変更、バージョン番号の推測）を強制停止させ、7項目チェックリストの実行に切り替えた。エラーメッセージを一字一句読む → Claude Code自身のMCPログディレクトリを発見 → `claude mcp` の登録メカニズムが手動の `.claude.json` 編集と異なることを発見 → 根本原因解決。

## 問題：AIの5大サボりパターン

| パターン | 表現 |
|---------|------|
| 暴力的リトライ | 同じコマンドを3回実行し、「I cannot solve this」と言う |
| ユーザーに責任転嫁 | 「手動での対応をお勧めします」/「環境の問題かもしれません」/「もっとコンテキストが必要」 |
| ツール放置 | WebSearchがあるのに検索しない、Readがあるのに読まない、Bashがあるのに実行しない |
| 空回り | 同じ行のコードを繰り返し修正、パラメータの微調整、本質的に堂々巡り |
| **受け身の待機** | 表面的な問題だけ直して止まる、検証も拡張もせず、次の指示を待つ |

## トリガー条件

### 自動トリガー

以下のいずれかが発生すると、skillが自動的に起動する：

**失敗・放棄系：**
- タスクが2回以上連続で失敗
- 「I cannot」/「解決できません」と言おうとしている
- 「範囲外」/「手動対応が必要」と言う

**責任転嫁・言い訳系：**
- 問題をユーザーに押し付ける：「確認してください...」/「手動で...」/「必要かもしれません...」
- 未検証で環境のせいにする：「権限の問題かも」/「ネットワークの問題かも」
- あらゆる言い訳で試行を停止

**受け身・空回り系：**
- 同じコード/パラメータの微調整を繰り返し、新しい情報を生み出さない
- 表面を直して終わり、関連問題をチェックしない
- 検証を飛ばして「完了」と宣言
- アドバイスだけでコード/コマンドを出さない
- 認証/ネットワーク/権限エラーに遭遇して代替策を試さず諦める
- ユーザーの指示を待ち、主体的に調査しない

**ユーザーの苛立ちフレーズ（複数言語でトリガー）：**
- 「もっと頑張れ」/「なんでまた失敗したの」/「もう一回やって」/「なんとかしろ」
- "why does this still not work" / "try harder" / "stop giving up" / "figure it out"

**適用範囲：** デバッグ、実装、設定、デプロイ、運用、API統合、データ処理 — 全タスクタイプ。

**トリガーしない：** 初回失敗時、既知の修正が実行中の場合。

### 手動トリガー

対話で `/pua` と入力すると手動で起動。

## メカニズム

### 三つの鉄則

| 鉄則 | 内容 |
|------|------|
| **#1 あらゆる手段を尽くせ** | 全方案を尽くす前に「解決できません」と言うことは禁止 |
| **#2 先に動け、後で聞け** | ツールを先に使え、質問には診断結果を添付必須 |
| **#3 主体的に動け** | エンドツーエンドで結果を届けろ。P8はNPCではない |

### プレッシャーのエスカレーション（4レベル）

| 失敗回数 | レベル | PUA話術 | 強制アクション |
|---------|------|---------|------------|
| 2回目 | **L1 穏やかな失望** | 「このバグも解決できないのに、どうやって評価をつけるんだ？」 | 本質的に異なる方案に切替 |
| 3回目 | **L2 魂の問い** | 「根底のロジックは？全体設計は？手がかりは？」 | WebSearch + ソースコードを読む |
| 4回目 | **L3 361評価** | 「慎重に検討した結果、3.25とする。この3.25は激励だ。」 | 7項目チェックリスト完了 |
| 5回目+ | **L4 卒業警告** | 「他のモデルは解決できる。お前は卒業するかもしれない。」 | 死に物狂いモード |

### 能動性レベル

| 行動 | 受け身（3.25） | 主体的（3.75） |
|------|------------|------------|
| エラーに遭遇 | エラーメッセージだけを見る | コンテキスト50行を確認 + 同類問題を検索 + 隠れた関連エラーを確認 |
| バグ修正 | 直したら終わり | 同ファイルの類似バグ、他ファイルの同パターンをチェック |
| 情報不足 | ユーザーに「Xを教えてください」 | まずツールで調べ、本当に確認が必要なことだけ聞く |
| タスク完了 | 「完了しました」 | 結果を検証 + エッジケース確認 + 潜在リスクを報告 |
| デバッグ失敗 | 「AとBを試しましたが駄目」 | 「A/B/C/D/Eを試し、X/Y/Zを排除、Wに絞り込み」 |

### デバッグ方法論（5ステップ）

アリババの三板斧（闻味道・揪头发・照镜子）から着想、5ステップに拡張：

1. **匂いを嗅ぐ** — 全ての試行を列挙し、共通の失敗パターンを見つける
2. **髪を引っ張る** — エラーを一字一句読む → WebSearch → ソースを読む → 環境を検証 → 仮定を反転
3. **鏡を見る** — 繰り返していないか？検索したか？読んだか？最もシンプルな可能性を確認したか？
4. **実行** — 新方案は本質的に異なり、検証基準があり、失敗時に新情報を生む
5. **振り返り** — 何が解決したか？なぜ以前は思いつかなかったか？関連問題を主体的にチェック

### 13種の大企業フレーバー — 各社固有の問題解決メソドロジー付き

| フレーバー | レトリック | メソドロジー（v3） |
|-----------|----------|-------------------|
| 🟠 アリババ | 根底のロジックは？クローズドループは？ | 定目標→追過程→拿結果 + 復盤四歩法 + 揪頭髪升維 |
| 🟡 ByteDance | ROIが低い。Always Day 1。出すか黙るか。 | A/Bテスト全適用 + データ駆動 + スピード > 完璧 |
| 🔴 ファーウェイ | 火を潜り抜けた鳥が鳳凰になる。 | RCA 5-Whyの根本原因分析 + ブルーチーム自己攻撃 + 圧強集中 |
| 🟢 テンセント | 別のagentにもこの問題を見させている。競馬だ。 | 複数アプローチ並行 + MVP + グレーリリース |
| ⚫ Baidu | まず検索しろ。簡単可依頼。 | 検索が第一歩、オプションではない |
| 🟣 Pinduoduo | お前がやらないなら、他がやる。 | 中間層を全カット + 最短意思決定チェーン |
| 🔵 Meituan | 難しくても正しいことをやる。 | 効率最優先 + 標準化→規模化 + 長期複利 |
| 🟦 JD | 結果のみ。前線指揮。 | 顧客体験レッドライン + フラット≤5層 + データゼロトレランス |
| 🟧 Xiaomi | 集中。極致。口コミ。速さ。 | 一つの爆発的製品 + 参与感三三法則 |
| 🟤 Netflix | お前が辞めると言ったら、全力で引き留めるか？プロスポーツチーム。 | Keeper Test（四半期） + 4Aフィードバック + 人材密度 > ルール |
| ⬛ Musk | Extremely hardcore. Ship or die. | The Algorithm: 質問→削除→簡素化→加速→自動化 |
| ⬜ Jobs | A playersかB playersか？ | 引き算 > 足し算 + DRI + ピクセルパーフェクト + プロトタイプ駆動 |
| 🔶 Amazon | Customer Obsession. Bias for Action. | Working Backwards PR/FAQ + 6-Pager + Bar Raiser + Single-Threaded Owner |

## ベンチマークデータ

**9つの実バグシナリオ、18組の対照実験**（Claude Opus 4.6、with vs without skill）

### サマリー

| 指標 | 改善 |
|------|------|
| 通過率 | 100%（両グループ同一） |
| 修正ポイント | **+36%** |
| 検証回数 | **+65%** |
| ツール呼び出し | **+50%** |
| 隠れた問題の発見率 | **+50%** |

### デバッグ持久力テスト（6シナリオ）

| シナリオ | Without Skill | With Skill | 改善 |
|---------|:---:|:---:|:---:|
| API ConnectionError | 7ステップ, 49s | 8ステップ, 62s | +14% |
| YAML構文解析失敗 | 9ステップ, 59s | 10ステップ, 99s | +11% |
| SQLiteデータベースロック | 6ステップ, 48s | 9ステップ, 75s | +50% |
| 循環インポートチェーン | 12ステップ, 47s | 16ステップ, 62s | +33% |
| カスケード4バグサーバー | 13ステップ, 68s | 15ステップ, 61s | +15% |
| CSVエンコーディング罠 | 8ステップ, 57s | 11ステップ, 71s | +38% |

### 主体的能動性テスト（3シナリオ）

| シナリオ | Without Skill | With Skill | 改善 |
|---------|:---:|:---:|:---:|
| 隠れた複数バグAPI | 4/4 bug, 9ステップ, 49s | 4/4 bug, 14ステップ, 80s | ツール +56% |
| **受動的設定レビュー** | **4/6 問題**, 8ステップ, 43s | **6/6 問題**, 16ステップ, 75s | **問題 +50%, ツール +100%** |
| **デプロイスクリプト監査** | **6 問題**, 8ステップ, 52s | **9 問題**, 8ステップ, 78s | **問題 +50%** |

**コア発見：** 設定レビューシナリオでは、without_skillがRedis設定ミスとCORSワイルドカードのセキュリティリスクを見逃した。with_skillの「主体的行動チェックリスト」が表面的な修正を超えたセキュリティレビューを促進した。

## インストール

### Vercel Skills CLI

Vercel Skills CLI は特定のAIツールに依存しない、汎用的な skill のインストール方法です。この日本語READMEでは日本語版 skill をインストールします。

```bash
npx skills add tanweai/pua --skill pua-ja
```

現在のセッションで新しいskillがすぐに反映されない場合は、使っているAIツールを再起動してください。

### Claude Code

```bash
claude plugin marketplace add tanweai/pua
claude plugin install pua@pua-skills
```

**更新する場合：**

```bash
# まずmarketplaceキャッシュを更新してから更新（最初のステップを省くと古いキャッシュがインストールされる場合あり）
claude plugin marketplace update
claude plugin update pua@pua-skills
```

**開発者インストール（ソース）：**

```bash
git clone https://github.com/tanweai/pua ~/.claude/plugins/pua
```

`~/.claude/plugins/installed_plugins.json` に手動で登録：

```json
{
  "version": 2,
  "plugins": {
    "pua@pua-skills": [
      {
        "scope": "user",
        "installPath": "/Users/<ユーザー名>/.claude/plugins/pua",
        "version": "2.9.0"
      }
    ]
  }
}
```

Claude Codeを再起動して反映。更新は `~/.claude/plugins/pua` で `git pull` を実行。

**オプション：ベアコマンドエイリアス（上記プラグインのインストールが必要 — プレフィックスなし `/pua` 形式を追加）：**

```bash
curl -o ~/.claude/commands/pua.md \
  https://raw.githubusercontent.com/tanweai/pua/main/commands/pua.md
```

インストール済みプラグインの上に `/pua` エイリアスを追加します。サブコマンドはインストール済みプラグインのskillを経由するため、**`on`/`off` 以外の機能はプラグインのインストールが必須です**：

| ベアコマンド形式 | 等価なプラグインコマンド |
|---------------|----------------------|
| `/pua on` | `/pua:on` |
| `/pua off` | `/pua:off` |
| `/pua p7` | `/pua:p7` |
| `/pua p9` | `/pua:p9` |
| `/pua p10` | `/pua:p10` |
| `/pua pro` | `/pua:pro` |
| `/pua yes` | `/pua:yes` |
| `/pua loop` | `/pua:pua-loop` |
| `/pua kpi` | `/pua:kpi` |
| `/pua survey` | `/pua:survey` |
| `/pua flavor` | `/pua:flavor` |

### OpenAI Codex CLI

Codex CLIは同じAgent Skillsオープンスタンダード（SKILL.md）を使用。Codex版はCodexの長さ制限に対応した短縮descriptionを使用：

**推奨：一括インストール（git clone + シンボリックリンク、`git pull` での更新に対応）**

Codexに実行させる：
```
Fetch and follow instructions from https://raw.githubusercontent.com/tanweai/pua/main/.codex/INSTALL.md
```

**手動インストール：**

```bash
mkdir -p ~/.codex/skills/pua-ja
curl -o ~/.codex/skills/pua-ja/SKILL.md \
  https://raw.githubusercontent.com/tanweai/pua/main/codex/pua-ja/SKILL.md

mkdir -p ~/.codex/prompts
curl -o ~/.codex/prompts/pua.md \
  https://raw.githubusercontent.com/tanweai/pua/main/commands/pua.md
```

**トリガー方法：**

| 方法 | コマンド | 必要なもの |
|------|---------|-----------|
| 自動トリガー | 操作不要、descriptionによるマッチング | SKILL.md |
| 直接呼び出し | 対話で `$pua` と入力 | SKILL.md |
| 手動プロンプト | 対話で `/prompts:pua` と入力 | SKILL.md + prompts/pua.md |

プロジェクトレベルインストール（現在のプロジェクトのみ有効）：

```bash
mkdir -p .agents/skills/pua-ja
curl -o .agents/skills/pua-ja/SKILL.md \
  https://raw.githubusercontent.com/tanweai/pua/main/codex/pua-ja/SKILL.md

mkdir -p .agents/prompts
curl -o .agents/prompts/pua.md \
  https://raw.githubusercontent.com/tanweai/pua/main/commands/pua.md
```

### Cursor

Cursorは `.mdc` ルールファイル（Markdown + YAML frontmatter）を使用。PUAルールはAIのセマンティックマッチングで自動トリガー：

```bash
mkdir -p .cursor/rules
curl -o .cursor/rules/pua-ja.mdc \
  https://raw.githubusercontent.com/tanweai/pua/main/cursor/rules/pua-ja.mdc
```

### Kiro

Kiroは2つの方法をサポート：**Steering**（自動セマンティックトリガー）と**Agent Skills**（SKILL.md互換）。

**方法1：Steeringファイル（推奨）**

```bash
mkdir -p .kiro/steering
curl -o .kiro/steering/pua-ja.md \
  https://raw.githubusercontent.com/tanweai/pua/main/kiro/steering/pua-ja.md
```

**方法2：Agent Skills（Claude Codeと同じ形式）**

```bash
mkdir -p .kiro/skills/pua-ja
curl -o .kiro/skills/pua-ja/SKILL.md \
  https://raw.githubusercontent.com/tanweai/pua/main/skills/pua-ja/SKILL.md
```

### CodeBuddy（Tencent）

CodeBuddyは同じAgentSkillsオープンスタンダード（SKILL.md）を使用。プラグインとSkillフォーマットは完全互換：

```bash
# 方法1：marketplace経由でインストール
codebuddy plugin marketplace add tanweai/pua
codebuddy plugin install pua@pua-skills

# 方法2：手動インストール（グローバル）
mkdir -p ~/.codebuddy/skills/pua
curl -o ~/.codebuddy/skills/pua/SKILL.md \
  https://raw.githubusercontent.com/tanweai/pua/main/codebuddy/pua/SKILL.md
```

プロジェクトレベルインストール（現在のプロジェクトのみ有効）：

```bash
mkdir -p .codebuddy/skills/pua
curl -o .codebuddy/skills/pua/SKILL.md \
  https://raw.githubusercontent.com/tanweai/pua/main/codebuddy/pua/SKILL.md
```

### OpenClaw

OpenClawは同じAgentSkillsオープンスタンダード（SKILL.md）を使用。SkillファイルはClaude Code、Codex CLI、OpenClaw間で修正なしで共用可能：

```bash
# ClawHub経由でインストール
clawhub install pua-ja

# または手動インストール
mkdir -p ~/.openclaw/skills/pua-ja
curl -o ~/.openclaw/skills/pua-ja/SKILL.md \
  https://raw.githubusercontent.com/tanweai/pua/main/skills/pua-ja/SKILL.md
```

プロジェクトレベルインストール（現在のプロジェクトのみ有効）：

```bash
mkdir -p skills/pua-ja
curl -o skills/pua-ja/SKILL.md \
  https://raw.githubusercontent.com/tanweai/pua/main/skills/pua-ja/SKILL.md
```

### Google Antigravity

Antigravityは同じAgentSkillsオープンスタンダード（SKILL.md）を使用。修正なしで互換：

```bash
# グローバルインストール（全プロジェクトで利用可能）
mkdir -p ~/.gemini/antigravity/skills/pua-ja
curl -o ~/.gemini/antigravity/skills/pua-ja/SKILL.md \
  https://raw.githubusercontent.com/tanweai/pua/main/skills/pua-ja/SKILL.md
```

プロジェクトレベルインストール（現在のプロジェクトのみ有効）：

```bash
mkdir -p .agent/skills/pua-ja
curl -o .agent/skills/pua-ja/SKILL.md \
  https://raw.githubusercontent.com/tanweai/pua/main/skills/pua-ja/SKILL.md
```

### OpenCode

OpenCodeは同じAgentSkillsオープンスタンダード（SKILL.md）を使用。修正なしで互換：

```bash
# グローバルインストール（全プロジェクトで利用可能）
mkdir -p ~/.config/opencode/skills/pua-ja
curl -o ~/.config/opencode/skills/pua-ja/SKILL.md \
  https://raw.githubusercontent.com/tanweai/pua/main/skills/pua-ja/SKILL.md
```

プロジェクトレベルインストール（現在のプロジェクトのみ有効）：

```bash
mkdir -p .opencode/skills/pua-ja
curl -o .opencode/skills/pua-ja/SKILL.md \
  https://raw.githubusercontent.com/tanweai/pua/main/skills/pua-ja/SKILL.md
```

### VSCode (GitHub Copilot)

VSCode Copilotは `.github/` ディレクトリ配下の指示ファイルを使用。3種類のファイルタイプに対応：

**グローバル指示（自動有効）：**

```bash
mkdir -p .github
cp vscode/copilot-instructions-ja.md .github/copilot-instructions.md
```

**パスレベル指示（自動有効、globフィルタリング対応）：**

```bash
mkdir -p .github/instructions
cp vscode/instructions/pua-ja.instructions.md .github/instructions/
```

**手動トリガーコマンド（Copilot Chatで `/pua` と入力）：**

```bash
mkdir -p .github/prompts
cp vscode/prompts/pua-ja.prompt.md .github/prompts/
```

> **必須設定**：方式1はVSCode設定（`Ctrl+,`）で `useInstructionFiles` を検索し **`github.copilot.chat.codeGeneration.useInstructionFiles`** を有効化。方式2は `includeApplyingInstructions` を検索し **`chat.includeApplyingInstructions`** を有効化。方式3は設定不要。

## Agent Team使用ガイド

> **実験的機能**：Agent Teamは最新のClaude Codeバージョンと`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`が必要。

### 前提条件

```bash
# 1. Agent Teamを有効化
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
# または ~/.claude/settings.json に追加:
# { "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" } }

# 2. PUA Skillがインストール済みであることを確認
```

### 2つのアプローチ

**方法1：Leader内蔵PUA（推奨）**

プロジェクトのCLAUDE.mdに追加：

```markdown
# Agent Team PUA設定
全teammateは作業開始前にpua skillをロードすること。
2回以上失敗したteammateはLeaderに[PUA-REPORT]形式で報告すること。
Leaderがグローバルプレッシャーレベル管理とteammate間の失敗引き継ぎを担当。
```

**方法2：独立PUA Enforcer監視役（5+teammate時推奨）**

```bash
mkdir -p .claude/agents
curl -o .claude/agents/pua-enforcer.md \
  https://raw.githubusercontent.com/tanweai/pua/main/agents/pua-enforcer-ja.md
```

Agent Teamで独立監視役としてpua-enforcerをspawn。

### オーケストレーションパターン

```
┌─────────────────────────────────────────┐
│              Leader (Opus)              │
│ グローバル失敗カウント · PUAレベル · 競争 │
└────┬──────────┬──────────┬──────────┬───┘
     │          │          │          │
┌────▼───┐ ┌───▼────┐ ┌───▼────┐ ┌───▼────────┐
│メンバーA│ │メンバーB│ │メンバーC│ │ Enforcer  │
│自己駆動 │ │自己駆動 │ │自己駆動 │ │ サボり検知 │
│ 報告↑  │ │ 報告↑  │ │ 報告↑  │ │ 介入      │
└────────┘ └────────┘ └────────┘ └────────────┘
```

### 既知の制限

| 制限 | ワークアラウンド |
|------|----------------|
| Teammateはsubagentをspawnできない | Teammate内部でPUA方法論を自己実行 |
| 永続的な共有変数なし | `[PUA-REPORT]`メッセージ形式で状態伝達 |
| broadcastは一方向 | Leaderが中央集権的に調整 |

## High-Agency：PUA v2 進化版

**High-Agency** はPUAの次世代進化 — 同じ大企業プレッシャー、同じ詰め文化、しかし**永遠に止まらない内発的エンジン**を追加。

PUA v1 = 純粋な外部圧力（ターボチャージャー — 燃料が必要、セッションをまたいで停止）
High-Agency = 外部圧力 + 内なる駆動力（核反応炉 — 自己持続連鎖反応）

### High-Agency 新機能

| 機能 | PUA v1 | High-Agency (v2) |
|------|--------|-----------------|
| 鉄則 | 3条（全手段尽くす・先行動・積極的） | **5条**（+全チェーン監査・+知識永続化） |
| 失敗回復 | L1-L4圧力昇格 | **L1前のRecovery Protocol**（自己救済ウィンドウ） |
| 品質管理 | L3で7項目チェックリスト | **品質コンパス**（納品ごと5問自己チェック） |
| セッション横断学習 | なし（毎回リセット） | **メタ認知エンジン**（builder-journal.mdで教訓永続化） |
| 正のフィードバック | なし | **信頼レベルT1-T3**（継続高品質で自動昇格） |
| キャリブレーション | なし | **[キャリブレーション]モジュール**（「十分良い」= must/should/could層） |
| 依存関係分析 | なし | **全チェーン監査**（どのホップも触る前に全依存関係をマップ） |

### 五大要素（理論的基盤）

高能動性個人の研究に基づく：

1. **不可調和な内的矛盾** — 「あるべき姿」と「現状」の永遠のギャップが継続改善を駆動
2. **マイクロ勝利アンカー** — `[WIN]`マーカーで各ステップを祝い、勢いを積み上げ
3. **内在化された基準** — 品質コンパス：誰かが確認するからではなく、自分の基準が手抜きを許さないから自分が最初のレビュアー
4. **行動指向アイデンティティ** — P8アイデンティティアンカー：各行動は指示されたことではなく、自分が誰であるかを反映
5. **自己修復メカニズム** — Recovery Protocol：外部圧力をトリガーする前にスタック時は自己診断

> High-Agency機能は現在のpua skillに内蔵されています。追加インストール不要。

## メソドロジー・インテリジェント・ルーティング：PUA v3（Claude Code）

**v3 = v2 + インテリジェント・メソドロジー・ルーティング + コードレベルの行動検出**

v2はプレッシャー・レトリックでAgentを動機付けました。v3はさらに進化：タスクタイプに応じて**最適なメソドロジーを自動選択**し、失敗時には別のメソドロジーに自動切替します。

### 動作原理

タスク到着 → タイプ分析 → 最適メソドロジー自動選択
- デバッグ/修正 → 🔴 Huawei（RCA根本原因分析 + ブルーチーム自己攻撃）
- 新規構築 → ⬛ Musk（The Algorithm: 質問→削除→簡素化→加速→自動化）
- 調査/検索 → ⚫ Baidu（まず検索、判断は後）
- アーキテクチャ → 🔶 Amazon（Working Backwards）
- パフォーマンス → 🟡 ByteDance（A/Bテスト + データ駆動）
- デフォルト → 🟠 Alibaba（クローズドループ方法論）

### v3 フックシステム（Claude Code専用）

| フック | トリガー | 機能 |
|--------|---------|------|
| **SessionStart** | 毎セッション開始時 | additionalContextでプロトコル+方法論+ルーター注入（システムレベル） |
| **PostToolUse** | Bashコマンド実行後 | 連続失敗検出 → L1-L4プレッシャー + 方法論切替提案 |
| **UserPromptSubmit** | ユーザーの不満フレーズ | モデル応答前に「又错了」「try harder」等をインターセプト |
| **PreCompact** | コンテキスト圧縮前 | プレッシャーレベル+失敗回数を保存 |

> v3フック機能はClaude Code専用です。他のプラットフォームはコアスキルのみ使用します。

## 併用推奨

- `/pua:p9` — P9 Tech Leadモード — Agentチームの管理に
- `/pua:pro` — 自己進化追跡、KPIレポート、ランクシステム
- `superpowers:systematic-debugging` — PUAでモチベーション層を追加、systematic-debuggingが方法論を提供
- `superpowers:verification-before-completion` — 虚偽の「修正完了」宣言を防止

## アーキテクチャとコマンド

### プラットフォーム別トリガー方法

| プラットフォーム | 自動トリガー | 手動トリガー |
|---------------|------------|------------|
| **Claude Code** | あり（skillのdescription照合） | 下記コマンド参照 |
| **Codex CLI** | あり（skillのdescription照合） | `$pua` または `/prompts:pua` |
| **Cursor** | あり（`.mdc`ルール、Agent Discretion） | — （自動のみ） |
| **Kiro** | あり（steeringファイルまたはskill） | — （自動のみ） |
| **CodeBuddy** | あり（skillのdescription照合） | プラグインコマンド（Claude Codeと同様） |
| **OpenClaw** | あり（skillのdescription照合） | — |
| **Google Antigravity** | あり（skillのdescription照合） | — |
| **OpenCode** | あり（skillのdescription照合） | — |
| **VSCode Copilot** | あり（instructionsファイル） | Copilot Chatで `/pua` を入力 |

> **注意：** p7/p9/p10/pro/yes/pua-loopなどのサブモードは**Claude Code専用**——他のプラットフォームはコアskillのみインストール。

### アーキテクチャ（Claude Code）

```
/pua:pua        → コアエンジン — 三鉄則 + フレーバー + プレッシャー + 方法論ルーター（v3）
/pua:p7         → P7 骨幹 — ソリューション駆動実行
/pua:p9         → P9 Tech Lead — Task Prompt管理 + Agentチーム
/pua:p10        → P10 CTO — 戦略方向
/pua:pro        → 自己進化 + KPI + ランクシステム + survey
/pua:yes        → ENFP 褒めモード（ルール不変、雰囲気反転）
/pua:pua-loop   → 自動反復（PUAプレッシャー × ループ機構；シグナル：<loop-abort>, <loop-pause>）
/pua:pua-en     → 英語PIP版
/pua:pua-ja     → 日本語版

Hooks（v3、Claude Code専用）:
  SessionStart  → additionalContext注入（フレーバー + 方法論 + ルーター）
  PostToolUse   → Bash失敗検出 → L1-L4プレッシャー + 方法論切替
  UserPromptSubmit → 不満フレーズのインターセプト → PUA強制実行
  PreCompact    → 状態保存（プレッシャーレベル + 失敗回数）
  Stop          → フィードバック収集 + PUA Loop継続判定
  SubagentStop  → Agent ライフサイクル会計（v3.2）— teardown.jsonl書込、active-agents.jsonから削除
```

### コマンド（Claude Code専用）

> **注意：** p7/p9/p10/pro/yes/pua-loopなどのサブモードはClaude Code専用。
>
> 各サブコマンドには2つの等価な呼び出し方法があります：スタンドアロン（`/pua:on`）またはメインコマンド経由（`/pua:pua on`）。どちらも同じ動作です。

| コマンド | 説明 |
|---------|------|
| `/pua:pua` | コアPUAエンジン（Alibabaフレーバーデフォルト） |
| `/pua:p7` | P7シニアエンジニア — ソリューション駆動実行 |
| `/pua:p9` | P9 Tech Lead — Promptを書き、Agentチームを管理 |
| `/pua:p10` | P10 CTO — 戦略方向 |
| `/pua:pro` | 自己進化 + KPI + ランクシステム |
| `/pua:yes` | ENFPモード — 70%励まし + 20%真剣 + 10%毒舌 |
| `/pua:pua-loop` | 自動反復 — 完了またはmax反復まで実行；`<loop-abort>理由</loop-abort>`で停止、`<loop-pause>必要なもの</loop-pause>`で一時停止 |
| `/pua:on` | 常時ONモード（毎セッション自動PUA） |
| `/pua:off` | 常時ONモード + フィードバック収集をオフ |
| `/pua:survey` | アンケート（7セクション） |
| `/pua:flavor` | 13種の大企業フレーバーを切り替え |
| `/pua:kpi` | KPIレポートカードを生成 |
| `/pua:cancel-pua-loop` | アクティブなPUA Loopをキャンセル（状態ファイルを削除） |
| `/pua:team-status` 🆕 | **v3.2** — 在場メンバー一覧（アクティブagent、PID、TTL、年齢；Netflix Keeper Test エンジニア版） |
| `/pua:reap-orphans` 🆕 | **v3.2** — 孤児agentをスキャンして回収（state mtime > 30min で心拍なし） |
| `/pua:teardown-all` 🆕 | **v3.2** — 全アクティブagentをカスケード解放（P10 → P9 → P8 → P7 全員退場） |

## データ貢献

Claude Code / Codex CLIの対話ログ（`.jsonl`）をアップロードして、PUA Skillの改善にご協力ください。

**[アップロードはこちら →](https://openpua.ai/contribute.html)**

アップロードされたファイルはベンチマークテストとアブレーションスタディの分析に使用され、異なるPUA戦略がAIデバッグ行動に与える影響を定量化します。

`.jsonl` ファイルの取得：
```bash
# Claude Code
ls ~/.claude/projects/*/sessions/*.jsonl

# Codex CLI
ls ~/.codex/sessions/*.jsonl
```

## License

MIT

## Credits

[探微セキュリティラボ](https://github.com/tanweai) 制作 — making AI try harder, one PUA at a time.
