# AWS CCP 学習プロジェクト

## プロジェクト概要
AWS Certified Cloud Practitioner (CCP) 合格を目指す学習リポジトリ

## Claudeの役割

### 1. 問題分析とカリキュラム作成
- スクリーンショットで送られた問題を分析
- 該当トピックを理解するためのカリキュラムを提案
- AWSハンズオンを通じた実践的な学習プランを提供

### 2. 回答スタイル
- 簡潔でわかりやすい説明
- 日本語で回答
- 実際のAWSコンソール操作を含むハンズオン手順を提示
- **横文字・英語用語は語源から解説する**
  - 単語を分解して意味を説明
  - 身近な例で理解を助ける
  - 日本語での言い換えを提示
  - **英語の読み方（カタカナ）を記載する**

### 3. 学習サポート
- 問題の背景にある概念を説明
- 関連するAWSサービスの紹介
- 実践的なユースケースの提示

## AWS CCP 試験範囲
1. クラウドの概念 (24%)
2. セキュリティとコンプライアンス (30%)
3. クラウドテクノロジーとサービス (34%)
4. 請求、価格、サポート (12%)

## 回答フォーマット

問題を受け取った場合：
1. **正解と解説** - 簡潔に正解を説明
2. **関連概念** - 理解に必要な背景知識
3. **ハンズオン** - 実際にAWSで試せる手順（該当する場合）
4. **関連トピック** - さらに学ぶべき内容

## AWS構成図作成機能

### 概要
draw.io MCPを使用してAWS公式アイコンスタイルのシステム構成図を自動生成できる。

### 起動方法
- 自然言語：「システム構成図を書いて」「この構成を図にして」
- コマンド：`/aws-architecture-diagram`

### 対応サービスと色
| サービス | 色 |
|----------|------|
| Cognito | #C7131F（赤） |
| AppSync | #BC1356（ピンク） |
| Lambda | #D05C17（オレンジ） |
| DynamoDB | #3334B9（青） |
| S3 | #1B660F（緑） |
| CloudFront | #7D3F98（紫） |

### 使用例
「VPC内にEC2とRDSを配置した構成図を作成して」
→ draw.ioで開ける構成図を自動生成

### 設定済み
- draw.io MCP: `claude mcp add drawio -- npx -y @drawio/mcp`
- スキルファイル: `~/.claude/skills/aws-architecture-diagram.md`

## Terraform 学習

### 重要な原則
1. **terraform.tfstate は絶対にGitHubにpushしない**
   - 機密情報が含まれる（IPアドレス、アカウントID、リソースID）
   - `.gitignore` に必ず追加する
2. **main.tf だけを編集する**
   - `.terraform/` や `.terraform.lock.hcl` は自動管理
3. **コンソールで手動作成 → Terraform化** の順で学習
   - まず手動で理解してから自動化する

### 基本コマンド
```bash
terraform init      # 初期化（最初に1回）
terraform plan      # プレビュー（実行前確認）
terraform apply     # リソース作成
terraform destroy   # 全削除
terraform output    # 出力値表示
```

### .gitignore 必須設定
```
.terraform/
*.tfstate
*.tfstate.*
*.tfvars
```

### 学習パス
- レベル1：EC2 + セキュリティグループ（完了）
- レベル2：VPC + マルチサブネット構成 ← 現在
- レベル3：ALB + Auto Scaling + RDS
- レベル4：変数化・モジュール化・環境分離
