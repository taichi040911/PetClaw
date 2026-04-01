# 57. siqidev/avatar-ui リファレンス

## 1. 概要
デスクトップ上でAIアバターが人間と共存するインターフェース（MIT License）。
「物理的な存在（人間）と情報的な存在（AI）が持続的に相互作用する場」がコンセプト。

## 2. 主な特徴

### 7ペイン統合UI
Avatar / Space / Canvas / X(Twitter) / Stream / Terminal / Roblox

### 持続的「Field」
- セッション・再起動・メディアを跨いだ連続した相互作用
- AIと人間が「同じフィールド」で相互作用
- state.json: atomic write + 1-generation backup + corruption recovery
- 状態遷移: generated → active → paused → resumed → terminated

### Long-term Memory (RAG)
- xAI Collections APIでサーバーサイド長期記憶
- AIが「何が重要か」を自分で判断して記憶を選択・保存

### Avatar Space
- 専用ファイルシステム（~/Avatar/space）
- AIがファイル読み書き可能

### Reciprocity Loop
- 人間入力 → Pulse（AI自律行動）→ 観測のシリアライズドキュー
- 時間的一貫性を保証

## 3. PetClawへの適用

| avatar-ui機能 | PetClaw実装 |
|-------------|-----------|
| Field持続性 | PersistentField.gd — JSON永続化 + atomic write |
| Long-term Memory | BiologicalMemorySystem cortex + ローカルJSON |
| Reciprocity Loop | AtoA会話キュー + オフライン自律行動 |
| 7ペインUI | Godotメイン画面 + AtoAログ + ステータス + 記憶パネル |
| Headless対応 | 将来のサーバー版（Web UI経由）に対応可能 |

### 設計原則の取り込み
1. 「存在感」重視（Cocomoと共通）
2. セッション跨ぎの記憶継続性
3. AIの自律性（Pulse = オフライン行動）
4. 安全設計（ツール実行は承認制）
