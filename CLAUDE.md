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
- レベル2：VPC + マルチサブネット構成（完了）
- レベル3：ALB + Auto Scaling + RDS
- レベル4：変数化・モジュール化・環境分離

## Kubernetes 学習（ローカル環境）

### 重要な原則
1. **ローカル環境で完全無料**
   - minikube + Docker Desktop で学習
   - AWSコストなし
2. **手を動かして学ぶ**
   - コマンドとYAMLファイル両方で理解
   - 実際にPodを作成・削除・更新
3. **Kubernetesの基礎概念を理解する**
   - Pod、Deployment、Service、ReplicaSet
   - 宣言的な設定（YAML）

### 基本コマンド
```bash
# クラスター管理
minikube start       # クラスター起動
minikube stop        # クラスター停止
minikube delete      # クラスター削除
minikube status      # 状態確認

# リソース確認
kubectl get pods              # Pod一覧
kubectl get deployments       # Deployment一覧
kubectl get services          # Service一覧
kubectl get all               # 全リソース

# リソース作成・削除
kubectl apply -f <file.yaml>  # YAMLから作成
kubectl delete -f <file.yaml> # YAMLから削除
kubectl delete pod <pod名>    # 特定リソース削除

# 詳細確認・デバッグ
kubectl describe pod <pod名>  # 詳細情報
kubectl logs <pod名>          # ログ確認
kubectl exec -it <pod名> -- /bin/bash  # Pod内に入る

# スケーリング・更新
kubectl scale deployment <名前> --replicas=5  # Pod数変更
kubectl set image deployment/<名前> <container>=<image>  # イメージ更新
kubectl rollout undo deployment/<名前>  # ロールバック
```

### 学習パス
- ハンズオン⑫：ローカルKubernetes入門（完了予定） ← 現在
  - minikube環境構築
  - Pod、Deployment、Service作成
  - スケーリング、ローリングアップデート
- 次のステップ：ConfigMap、Secret、Volume、Namespace
- AWS連携：Amazon ECS（無料枠）、Amazon EKS（有料）
