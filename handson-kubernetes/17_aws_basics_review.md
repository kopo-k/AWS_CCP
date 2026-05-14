# Level 3: AWS基礎復習（VPC・IAM）ハンズオン

**ファイルパス**: `/Users/k24032kk/AWS_CCP/handson-kubernetes/17_aws_basics_review.md`

**前提**: Level 1-2（Kubernetes基礎・中級）を完了していること

**環境**: AWS Console / AWS CLI

**所要時間**: 約5時間（2-3日、毎日2時間）

**Phase 3での使い道**: EKS用VPC作成、IAM Role設定、IRSA設定

---

## 📋 このハンズオンで学ぶこと

- ✅ VPC設計の復習（Public/Private Subnet、NAT Gateway、Internet Gateway）
- ✅ EKS用VPCの要件
- ✅ IAM Roleの基礎（Trust Relationship、Policy Attachment）
- ✅ EKS用IAM Role（Cluster Role、Node Role）
- ✅ IRSA（IAM Roles for Service Accounts）の概念

---

# Part 1: VPC設計の復習（2時間）

## タスク1: VPC設計を復習する（1時間）

### VPCとは？

**VPC = Virtual Private Cloud（バーチャル・プライベート・クラウド）** = 仮想プライベートクラウド

- **Virtual**: ラテン語の「virtus（ウィルトゥス）」= 力、能力 → 仮想的な
- **Private**: ラテン語の「privatus（プリーウァートゥス）」= 個人の、私的な
- **Cloud**: 雲 → クラウドコンピューティング

**意味**: AWS上に作る自分専用のプライベートネットワーク

### VPCの構成要素

```
VPC（10.0.0.0/16）
  ├── Public Subnet（10.0.1.0/24）
  │     ├── Internet Gateway（IGW）← インターネット接続
  │     ├── Route Table（Public）
  │     └── NAT Gateway ← Private SubnetからInternet接続用
  │
  └── Private Subnet（10.0.2.0/24）
        ├── Route Table（Private）
        └── NAT Gateway経由でInternet接続
```

### CIDR表記の復習

**CIDR = Classless Inter-Domain Routing（クラスレス・インター・ドメイン・ルーティング）**

| 表記 | 意味 | IPアドレス範囲 | IP数 |
|------|------|---------------|------|
| `10.0.0.0/16` | 10.0.x.x | 10.0.0.0 〜 10.0.255.255 | 65,536個 |
| `10.0.1.0/24` | 10.0.1.x | 10.0.1.0 〜 10.0.1.255 | 256個 |
| `10.0.2.0/24` | 10.0.2.x | 10.0.2.0 〜 10.0.2.255 | 256個 |

**計算方法**:
```
/16 = 32 - 16 = 16ビットが可変 = 2^16 = 65,536個
/24 = 32 - 24 = 8ビットが可変 = 2^8 = 256個
```

### Public SubnetとPrivate Subnetの違い

| 項目 | Public Subnet | Private Subnet |
|------|--------------|---------------|
| **インターネット接続** | ✅ 直接接続可能 | ❌ 直接不可（NAT Gateway経由） |
| **ルートテーブル** | Internet Gateway（IGW）へのルート | NAT Gatewayへのルート |
| **用途** | ロードバランサー、踏み台サーバー | アプリサーバー、データベース |
| **パブリックIP** | 自動割り当て可能 | 割り当てなし |

### Internet Gateway（IGW）

**Internet Gateway** = VPCとインターネットの出入り口

```
Internet
    ↕ (IGW)
VPC
```

**役割**:
- VPCからインターネットへの通信
- インターネットからVPCへの通信

### NAT Gateway

**NAT = Network Address Translation（ネットワーク・アドレス・トランスレーション）** = ネットワークアドレス変換

**役割**: Private SubnetからInternet方向への通信を可能にする（逆方向は不可）

```
Private Subnet → NAT Gateway → Internet Gateway → Internet
Internet → ❌ NAT Gateway（ブロック）
```

**なぜ必要？**
- Private Subnetのインスタンスがソフトウェア更新する必要がある
- でも、Internetから直接アクセスされたくない

### ルートテーブル

**Route Table** = ネットワークトラフィックをどこに転送するか定義する表

#### Public Subnet用ルートテーブル

| Destination | Target | 意味 |
|-------------|--------|------|
| `10.0.0.0/16` | local | VPC内部の通信 |
| `0.0.0.0/0` | igw-xxxxx | それ以外（Internet）はIGW経由 |

#### Private Subnet用ルートテーブル

| Destination | Target | 意味 |
|-------------|--------|------|
| `10.0.0.0/16` | local | VPC内部の通信 |
| `0.0.0.0/0` | nat-xxxxx | それ以外（Internet）はNAT Gateway経由 |

---

## タスク2: EKS用VPCの要件を学ぶ（1時間）

### EKS用VPCの最低要件

1. **最低2つのアベイラビリティゾーン（AZ）**
2. **各AZに最低1つのSubnet**
3. **適切なタグ設定**

### 推奨構成

```
VPC（10.0.0.0/16）
  ├── AZ: ap-northeast-1a
  │     ├── Public Subnet（10.0.1.0/24）
  │     └── Private Subnet（10.0.11.0/24）
  │
  └── AZ: ap-northeast-1c
        ├── Public Subnet（10.0.2.0/24）
        └── Private Subnet（10.0.12.0/24）
```

### 必須タグ

#### VPC

| Key | Value |
|-----|-------|
| `Name` | eks-vpc |

#### Public Subnet

| Key | Value | 意味 |
|-----|-------|------|
| `Name` | eks-public-1a | わかりやすい名前 |
| `kubernetes.io/role/elb` | `1` | ELB（ALB/NLB）用 |
| `kubernetes.io/cluster/<cluster-name>` | `shared` | EKSクラスタで使用 |

#### Private Subnet

| Key | Value | 意味 |
|-----|-------|------|
| `Name` | eks-private-1a | わかりやすい名前 |
| `kubernetes.io/role/internal-elb` | `1` | Internal ELB用 |
| `kubernetes.io/cluster/<cluster-name>` | `shared` | EKSクラスタで使用 |

### なぜこのタグが必要？

#### `kubernetes.io/role/elb`
- AWS Load Balancer ControllerがALB/NLBを作成するSubnetを自動検出
- Public SubnetにALB/NLBが作成される

#### `kubernetes.io/role/internal-elb`
- Internal ELB用のSubnetを自動検出
- Private SubnetにInternal ELBが作成される

#### `kubernetes.io/cluster/<cluster-name>`
- EKSクラスタがこのSubnetを使うことを示す
- 複数クラスタで同じVPCを共有する場合に必要

### Subnet数の考慮事項

#### 最小構成（学習用）
```
2 AZ × 2 Subnet = 4 Subnet
- Public × 2
- Private × 2
```

#### 本番推奨
```
3 AZ × 2 Subnet = 6 Subnet
- Public × 3
- Private × 3
```

**Phase 3では**: 最小構成（2 AZ × 2 Subnet）

### IPアドレス範囲の推奨

| 用途 | CIDR | IP数 |
|------|------|------|
| **VPC** | `10.0.0.0/16` | 65,536個 |
| **Public Subnet（1a）** | `10.0.1.0/24` | 256個 |
| **Public Subnet（1c）** | `10.0.2.0/24` | 256個 |
| **Private Subnet（1a）** | `10.0.11.0/24` | 256個 |
| **Private Subnet（1c）** | `10.0.12.0/24` | 256個 |

**ポイント**:
- Public SubnetとPrivate Subnetで明確に範囲を分ける
- 将来の拡張を考慮して `/16` を使用

---

# Part 2: IAM Roleの基礎（3時間）

## タスク3: IAM Roleの基礎を復習する（1時間）

### IAM Roleとは？

**IAM = Identity and Access Management（アイデンティティ・アンド・アクセス・マネジメント）** = ID・アクセス管理
**Role** = 役割

**意味**: AWSリソースに対する一時的な権限

### IAM UserとIAM Roleの違い

| 項目 | IAM User | IAM Role |
|------|----------|----------|
| **誰が使う？** | 人間（開発者） | AWSリソース（EC2、EKSなど） |
| **認証情報** | パスワード、アクセスキー | 一時的なセキュリティトークン |
| **有効期限** | なし（無期限） | あり（1時間など） |
| **用途** | CLIやコンソールログイン | EC2からS3にアクセスなど |

### IAM Roleの構成要素

```
IAM Role
  ├── Trust Relationship（信頼関係）← 誰がこのRoleを使えるか
  │     └── Principal（プリンシパル）
  │
  └── Policy（ポリシー）← 何ができるか
        ├── Managed Policy（AWS管理ポリシー）
        └── Inline Policy（カスタムポリシー）
```

### Trust Relationship（信頼関係）

**Trust Relationship** = このRoleを誰が引き受けられるか定義

**例**: EC2インスタンスがこのRoleを引き受けられる

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

**Principal**: 誰が（EC2サービス）
**Action**: 何をする（Roleを引き受ける）

### Policy（ポリシー）

**Policy** = 何ができるかを定義

**例**: S3の読み取り権限

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::my-bucket",
        "arn:aws:s3:::my-bucket/*"
      ]
    }
  ]
}
```

**Effect**: 許可（Allow）または拒否（Deny）
**Action**: 何ができるか（S3からオブジェクト取得）
**Resource**: どのリソースに対して（my-bucket）

### Policy Attachment

**Managed Policy**: AWS提供またはカスタム作成の再利用可能なポリシー

```
IAM Role
  ├── AmazonS3ReadOnlyAccess（Managed Policy）
  └── AmazonEC2ReadOnlyAccess（Managed Policy）
```

**Inline Policy**: Role専用のカスタムポリシー

```
IAM Role
  └── CustomS3Policy（Inline Policy）
```

---

## タスク4: EKS用IAM Roleを理解する（1時間）

### EKSに必要な2つのRole

```
1. Cluster Role（クラスターロール）
   - EKS Control Planeが使用
   - EC2、ELB、CloudWatchへのアクセス

2. Node Role（ノードロール）
   - Worker Node（EC2）が使用
   - ECR、EBS、ENIへのアクセス
```

### 1. Cluster Role（EKSClusterRole）

**用途**: EKS Control Planeが他のAWSサービスを操作するため

#### Trust Relationship

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

**意味**: EKSサービスがこのRoleを引き受けられる

#### 必須Policy

| Policy名 | 用途 |
|----------|------|
| `AmazonEKSClusterPolicy` | EKSの基本操作（EC2、ELB、CloudWatch） |

**AmazonEKSClusterPolicyの内容**:
- EC2インスタンス、セキュリティグループの管理
- Elastic Load Balancer（ELB）の作成・削除
- CloudWatch Logsへのログ送信
- VPCリソースの管理

### 2. Node Role（EKSNodeRole）

**用途**: Worker Node（EC2）が他のAWSサービスを操作するため

#### Trust Relationship

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

**意味**: EC2インスタンスがこのRoleを引き受けられる

#### 必須Policy

| Policy名 | 用途 |
|----------|------|
| `AmazonEKSWorkerNodePolicy` | EKS Worker Nodeの基本操作 |
| `AmazonEKS_CNI_Policy` | Pod間ネットワーク（VPC CNI） |
| `AmazonEC2ContainerRegistryReadOnly` | ECRからコンテナイメージ取得 |

**各Policyの役割**:

| Policy | 主な権限 |
|--------|---------|
| **AmazonEKSWorkerNodePolicy** | EC2インスタンス情報取得、ENI操作 |
| **AmazonEKS_CNI_Policy** | ENI作成・削除、IPアドレス割り当て |
| **AmazonEC2ContainerRegistryReadOnly** | ECRからコンテナイメージダウンロード |

### CLI例: Cluster Role作成

```bash
# 1. Trust Relationship JSON作成
cat > eks-cluster-trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# 2. Role作成
aws iam create-role \
  --role-name EKSClusterRole \
  --assume-role-policy-document file://eks-cluster-trust-policy.json

# 3. Policy Attach
aws iam attach-role-policy \
  --role-name EKSClusterRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
```

### CLI例: Node Role作成

```bash
# 1. Trust Relationship JSON作成
cat > eks-node-trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# 2. Role作成
aws iam create-role \
  --role-name EKSNodeRole \
  --assume-role-policy-document file://eks-node-trust-policy.json

# 3. Policy Attach（3つ）
aws iam attach-role-policy \
  --role-name EKSNodeRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy

aws iam attach-role-policy \
  --role-name EKSNodeRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy

aws iam attach-role-policy \
  --role-name EKSNodeRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
```

---

## タスク5: IRSA（IAM Roles for Service Accounts）の概念を学ぶ（1時間）

### IRSAとは？

**IRSA = IAM Roles for Service Accounts**

**意味**: KubernetesのServiceAccount（Pod）にIAM Roleを割り当てる仕組み

### なぜIRSAが必要？

#### 従来の方法（Node Role）

```
Node Role（EC2全体に権限）
  ↓ すべてのPodが同じ権限
Pod A（S3アクセス必要）✅
Pod B（DynamoDBアクセス必要）← でもS3権限も持ってしまう ❌
Pod C（権限不要）← でもS3権限を持ってしまう ❌
```

**問題**:
- すべてのPodが同じ権限を持つ
- 最小権限の原則に反する
- セキュリティリスク

#### IRSA（Pod毎に権限）

```
Pod A + ServiceAccount A → IAM Role A（S3のみ） ✅
Pod B + ServiceAccount B → IAM Role B（DynamoDBのみ） ✅
Pod C + ServiceAccount C → 権限なし ✅
```

**利点**:
- Pod毎に必要な権限だけ付与
- 最小権限の原則を実現
- セキュリティ向上

### IRSAの仕組み

```
1. OIDCプロバイダーをIAMに登録
2. ServiceAccountを作成（annotationでIAM Role指定）
3. IAM RoleのTrust RelationshipにOIDC条件を追加
4. PodがServiceAccountを使用
5. Podは自動的にIAM Roleの一時認証情報を取得
```

### OIDC プロバイダーとは？

**OIDC = OpenID Connect（オープンアイディー・コネクト）**

**意味**: 認証・認可の標準プロトコル

**EKSの場合**:
- EKSクラスタがOIDCプロバイダーを提供
- IAMがこのOIDCプロバイダーを信頼
- ServiceAccountの認証情報をIAMが検証

### IAM RoleのTrust Relationship（IRSA用）

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::123456789012:oidc-provider/oidc.eks.ap-northeast-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.ap-northeast-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE:sub": "system:serviceaccount:default:my-service-account"
        }
      }
    }
  ]
}
```

**Federated**: OIDCプロバイダーのARN
**Condition**: どのServiceAccountか指定

### ServiceAccountの作成

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-service-account
  namespace: default
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/MyIRSARole
```

**annotations**: どのIAM Roleを使うか指定

### PodでServiceAccountを使用

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  serviceAccountName: my-service-account  # ← ServiceAccount指定
  containers:
  - name: app
    image: my-app
```

**自動的に行われること**:
1. PodにAWS認証情報が環境変数として注入される
2. `AWS_ROLE_ARN` = IAM RoleのARN
3. `AWS_WEB_IDENTITY_TOKEN_FILE` = トークンファイルのパス
4. AWS SDKが自動的にこれらを使って認証

### Phase 3での使用例

#### ALB Controller用のIRSA

```
1. ALB Controller用のIAM Role作成
   - ELB、EC2、VPCへのアクセス権限

2. OIDCプロバイダー登録

3. ServiceAccount作成
   apiVersion: v1
   kind: ServiceAccount
   metadata:
     name: aws-load-balancer-controller
     namespace: kube-system
     annotations:
       eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/AmazonEKSLoadBalancerControllerRole

4. ALB ControllerをHelmでインストール
   - 自動的にこのServiceAccountを使用
```

#### EBS CSI Driver用のIRSA

```
1. EBS CSI Driver用のIAM Role作成
   - EBSへのアクセス権限

2. ServiceAccount作成
   apiVersion: v1
   kind: ServiceAccount
   metadata:
     name: ebs-csi-controller-sa
     namespace: kube-system
     annotations:
       eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/AmazonEKS_EBS_CSI_DriverRole

3. EBS CSI DriverをEKS Addonとして追加
   - 自動的にこのServiceAccountを使用
```

### IRSAのメリット

| メリット | 説明 |
|---------|------|
| **最小権限** | Pod毎に必要な権限だけ付与 |
| **セキュリティ** | 他のPodに影響しない |
| **監査** | CloudTrailでPod毎のAPI呼び出しを追跡 |
| **柔軟性** | Pod毎に異なるIAM Roleを使用可能 |

---

# Level 3 全体まとめ

## 完了したタスク

- [x] VPC設計を復習する（Public/Private Subnet、NAT Gateway、Internet Gateway、ルートテーブル）
- [x] EKS用VPCの要件を学ぶ（最低2つのAZ、SubnetのタグKubernetes.io/role/elb）
- [x] IAM Roleの基礎を復習する（Trust Relationship、Policy Attachment）
- [x] EKS用IAM Roleを理解する（Cluster Role、Node Role）
- [x] IRSA（IAM Roles for Service Accounts）の概念を学ぶ

## 習得したスキル

| スキル | Phase 3での使い道 |
|--------|------------------|
| **VPC設計** | EKS用VPCの作成 |
| **Subnetタグ** | ALB自動作成のためのタグ設定 |
| **Cluster Role** | EKSクラスタ作成時に使用 |
| **Node Role** | ノードグループ作成時に使用 |
| **IRSA** | ALB Controller、EBS CSI Driverで使用 |

## 重要な概念

### VPC
- Public SubnetとPrivate Subnetの使い分け
- NAT Gatewayの役割
- EKS用の必須タグ

### IAM
- Cluster RoleとNode Roleの違い
- Trust RelationshipとPolicyの関係
- IRSAによるPod毎の権限分離

## 次のステップ

**Level 4: EKS標準モード** に進む

ここで学んだVPCとIAMの知識を使って、実際にEKSクラスタを作成します。

---

**作成日**: 2026-05-14
**目的**: Phase 3検証環境構築に向けたAWS基礎知識の復習
**対象者**: Level 1-2を完了した人
