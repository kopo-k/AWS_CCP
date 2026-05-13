# EKS Auto Mode クリーンアップ手順

**ファイルパス**: `/Users/k24032kk/AWS_CCP/handson/cleanup_eks_auto_mode.md`

**関連ファイル**:
- 教材: `/Users/k24032kk/AWS_CCP/handson/10_eks_auto_mode.md`
- YAMLファイル: `/Users/k24032kk/AWS_CCP/handson/nginx-auto-mode.yaml`

## 削除する理由
料金が発生するリソースを削除して課金を止める

**主な課金対象**:
- EKSクラスタ: $0.10/時間 = $72/月
- NAT Gateway × 2: $0.045/時間 × 2 = $64.8/月
- **合計**: 約$136/月

---

## Step 1：YAMLファイルを削除（オプション）

```bash
# YAMLファイルを削除
rm /Users/k24032kk/AWS_CCP/handson/nginx-auto-mode.yaml
```

---

## Step 2：Deploymentを削除

```bash
kubectl delete deployment nginx-deployment
```

**Note**: 既に削除されている場合はエラーが出ますが、問題ありません。

---

## Step 3：EKSクラスタを削除

```bash
aws eks delete-cluster --name my-first-auto-cluster --region ap-northeast-1
```

**所要時間**: 約10-15分

### 削除完了を確認

```bash
aws eks describe-cluster --name my-first-auto-cluster --region ap-northeast-1
```

**期待される結果**: エラーが出れば削除完了
```
An error occurred (ResourceNotFoundException) when calling the DescribeCluster operation: No cluster found for name: my-first-auto-cluster
```

---

## Step 4：VPCを削除（コンソール）

### 手順

1. AWSコンソール → **VPC**
2. 左メニュー「**お使いのVPC**」
3. `eks-auto-vpc` を選択
4. **「アクション」→「VPCを削除」**
5. 確認して**「削除」**

### 自動的に削除されるもの

- サブネット × 4
- NAT Gateway × 2（**重要：課金対象**）
- Internet Gateway
- ルートテーブル
- Elastic IP

---

## Step 5：IAMリソースを削除

### 5-1：インスタンスプロファイルを削除

```bash
# ロールを削除
aws iam remove-role-from-instance-profile \
  --instance-profile-name AmazonEKSAutoNodeRole \
  --role-name AmazonEKSAutoNodeRole

# インスタンスプロファイルを削除
aws iam delete-instance-profile --instance-profile-name AmazonEKSAutoNodeRole
```

### 5-2：ノードロールを削除

```bash
# ポリシーをデタッチ
aws iam detach-role-policy \
  --role-name AmazonEKSAutoNodeRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy

aws iam detach-role-policy \
  --role-name AmazonEKSAutoNodeRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy

aws iam detach-role-policy \
  --role-name AmazonEKSAutoNodeRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly

# ロールを削除
aws iam delete-role --role-name AmazonEKSAutoNodeRole
```

### 5-3：クラスタロールを削除

```bash
# ポリシーをデタッチ
aws iam detach-role-policy \
  --role-name AmazonEKSAutoClusterRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy

# ロールを削除
aws iam delete-role --role-name AmazonEKSAutoClusterRole
```

---

## 全削除確認

```bash
# EKSクラスタ
aws eks list-clusters --region ap-northeast-1
# 結果: "clusters": []

# VPC
aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=eks-auto-vpc" \
  --region ap-northeast-1 \
  --query "Vpcs[].VpcId"
# 結果: []

# IAMロール
aws iam get-role --role-name AmazonEKSAutoNodeRole
# 結果: NoSuchEntity エラー

aws iam get-role --role-name AmazonEKSAutoClusterRole
# 結果: NoSuchEntity エラー
```

---

## まとめて実行（スクリプト版）

```bash
#!/bin/bash

echo "=== Step 1: YAMLファイル削除 ==="
rm /Users/k24032kk/AWS_CCP/handson/nginx-auto-mode.yaml 2>/dev/null

echo "=== Step 2: Deployment削除 ==="
kubectl delete deployment nginx-deployment 2>/dev/null

echo "=== Step 3: EKSクラスタ削除 ==="
aws eks delete-cluster --name my-first-auto-cluster --region ap-northeast-1

echo "クラスタ削除を待機中（10分）..."
sleep 600

echo "=== Step 5: IAMリソース削除 ==="

# インスタンスプロファイル
aws iam remove-role-from-instance-profile \
  --instance-profile-name AmazonEKSAutoNodeRole \
  --role-name AmazonEKSAutoNodeRole 2>/dev/null

aws iam delete-instance-profile \
  --instance-profile-name AmazonEKSAutoNodeRole 2>/dev/null

# ノードロール
aws iam detach-role-policy \
  --role-name AmazonEKSAutoNodeRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy 2>/dev/null

aws iam detach-role-policy \
  --role-name AmazonEKSAutoNodeRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy 2>/dev/null

aws iam detach-role-policy \
  --role-name AmazonEKSAutoNodeRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly 2>/dev/null

aws iam delete-role --role-name AmazonEKSAutoNodeRole 2>/dev/null

# クラスタロール
aws iam detach-role-policy \
  --role-name AmazonEKSAutoClusterRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy 2>/dev/null

aws iam delete-role --role-name AmazonEKSAutoClusterRole 2>/dev/null

echo "=== 完了 ==="
echo "⚠️ VPCは手動でコンソールから削除してください"
echo "VPCコンソール → eks-auto-vpc を選択 → アクション → VPCを削除"
```

---

## 重要な注意点

### VPCは必ず削除すること

NAT Gatewayが課金対象（$64.8/月）なので、VPCを削除しないと課金が続きます。

### クラスタ削除に時間がかかる

10-15分かかるため、削除コマンド実行後は完了を待つ必要があります。

### エラーが出ても大丈夫

既に削除済みのリソースでエラーが出ても問題ありません。

---

**作成日**: 2026-05-13
**目的**: EKS Auto Mode関連リソースを完全削除して課金を止める
