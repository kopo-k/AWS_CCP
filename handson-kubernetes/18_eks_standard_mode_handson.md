# Level 4: EKS標準モード ハンズオン

**ファイルパス**: `/Users/k24032kk/AWS_CCP/handson-kubernetes/18_eks_standard_mode_handson.md`

**前提**: Level 1-3（Kubernetes基礎・中級・AWS基礎）を完了していること

**環境**: AWS（⚠️ 課金あり）

**所要時間**: 約21時間（1-2週間、毎日2-3時間）

**Phase 3での使い道**: EKSクラスタ作成、Karpenter、EBS CSI Driver、ALB Controller導入

**⚠️ コスト注意**: Level 4の実習コスト = 約$2-3（10時間程度）

---

## 📋 このハンズオンで学ぶこと

- ✅ EKSの基礎とアーキテクチャ
- ✅ eksctlの使い方
- ✅ EKSクラスタの作成・削除
- ✅ マネージドノードグループ
- ✅ Karpenter（自動スケーリング）
- ✅ EBS CSI Driver（永続ストレージ）
- ✅ AWS Load Balancer Controller（ALB自動作成）
- ✅ Helm（パッケージ管理）

---

## ⚠️ 重要：コスト管理

### Level 4の実習コスト（目安）

| リソース | 時間単価 | 10時間 |
|---------|---------|--------|
| EKSクラスタ | $0.10/時間 | $1.00 |
| EC2（t3.small × 1） | $0.025/時間 | $0.25 |
| NAT Gateway × 2 | $0.045 × 2/時間 | $0.90 |
| **合計** | **$0.22/時間** | **$2.20** |

### コスト削減のポイント

1. **実習後は必ず削除**
   ```bash
   eksctl delete cluster --name <cluster-name>
   ```

2. **長時間放置しない**
   - 夜間・週末は削除しておく
   - 必要な時だけ作成

3. **最小構成で実習**
   - Node数: 1個
   - インスタンスタイプ: t3.small

4. **削除確認**
   ```bash
   # クラスタ削除確認
   eksctl get cluster

   # VPC削除確認（手動削除の場合）
   aws ec2 describe-vpcs --filters "Name=tag:Name,Values=eks-*"
   ```

---

# Part 1: EKSの基礎（1.5時間）

## タスク1: EKSとは何か、アーキテクチャ（Control Plane、Data Plane）を学ぶ（1.5時間）

### EKSとは？

**EKS = Amazon Elastic Kubernetes Service**

- **Elastic**: ラテン語の「elasticus（エラスティクス）」= 弾性的な → 伸び縮みする
- **Kubernetes**: ギリシャ語の「κυβερνήτης（クベルネーテス）」= 操舵手、パイロット
- **Service**: サービス

**意味**: AWSが提供するマネージド型Kubernetesサービス

### minikube vs EKS

| 項目 | minikube | EKS |
|------|----------|-----|
| **環境** | ローカルPC（VM） | AWS |
| **Control Plane** | 自分で管理 | **AWSが管理** |
| **可用性** | 単一障害点 | 複数AZで冗長化 |
| **スケール** | 小規模（学習用） | 大規模（本番用） |
| **コスト** | 無料 | $0.10/時間 + リソース |
| **Node** | 1つ | 複数 |

### EKSのアーキテクチャ

```
┌─────────────────────────────────────────────┐
│          AWS Management Console             │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│          EKS Control Plane                  │
│         （AWSが管理）                        │
│  ┌────────────────────────────────────┐    │
│  │  kube-apiserver                     │    │
│  │  etcd（複数AZで冗長化）             │    │
│  │  kube-controller-manager            │    │
│  │  kube-scheduler                     │    │
│  └────────────────────────────────────┘    │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│          Data Plane                         │
│         （ユーザーが管理）                  │
│                                             │
│  ┌────────────┐  ┌────────────┐           │
│  │  Node 1    │  │  Node 2    │           │
│  │  (EC2)     │  │  (EC2)     │           │
│  │            │  │            │           │
│  │  Pod Pod   │  │  Pod Pod   │           │
│  └────────────┘  └────────────┘           │
└─────────────────────────────────────────────┘
```

### Control Plane（コントロールプレーン）

**Control Plane** = Kubernetesの管理機能

#### 構成要素

| コンポーネント | 役割 |
|--------------|------|
| **kube-apiserver** | KubernetesのAPI提供（kubectl経由でアクセス） |
| **etcd** | クラスタの状態を保存する分散KVS |
| **kube-controller-manager** | リソース（Pod、Service）の管理 |
| **kube-scheduler** | Podをどのノードに配置するか決定 |

#### EKSの特徴

✅ **AWSが完全管理**
- ユーザーはControl Planeを管理不要
- 自動アップグレード
- 複数AZで冗長化（高可用性）
- パッチ適用

✅ **課金**
- $0.10/時間（$72/月）
- クラスタあたりの固定費

### Data Plane（データプレーン）

**Data Plane** = 実際にPodが動くWorker Node群

#### 構成要素

| コンポーネント | 役割 |
|--------------|------|
| **Worker Node（EC2）** | Podが実際に動くサーバー |
| **kubelet** | Podの起動・監視 |
| **kube-proxy** | ネットワーク管理 |
| **Container Runtime** | コンテナを動かすエンジン（containerd） |

#### EKSの特徴

⚠️ **ユーザーが管理**
- EC2インスタンスの起動・停止
- スケーリング
- パッチ適用

✅ **課金**
- EC2インスタンスの料金
- EBS ボリュームの料金
- Data Transfer料金

### EKSのメリット

| メリット | 説明 |
|---------|------|
| **管理不要** | Control PlaneをAWSが管理 |
| **高可用性** | 複数AZで冗長化 |
| **セキュリティ** | IAM、VPC、セキュリティグループ統合 |
| **スケーラビリティ** | 大規模クラスタに対応 |
| **エコシステム** | Helm、Karpenter、ALB Controllerなど |

### EKSのデメリット

| デメリット | 説明 |
|----------|------|
| **コスト** | Control Planeの固定費 $72/月 |
| **複雑性** | VPC、IAM、Subnetの理解が必要 |
| **学習コスト** | minikubeより設定が複雑 |

---

# Part 2: eksctlの基礎（3.5時間）

## タスク2: eksctlをHomebrewでインストールする（30分）

### eksctlとは？

**eksctl** = EKS +ctl（control）

**意味**: EKSクラスタを簡単に作成・管理するCLIツール

### なぜeksctl？

#### AWS CLIだけで作成（大変）

```bash
# 1. VPC作成
aws ec2 create-vpc --cidr-block 10.0.0.0/16

# 2. Subnet作成（4つ）
aws ec2 create-subnet ...
aws ec2 create-subnet ...
aws ec2 create-subnet ...
aws ec2 create-subnet ...

# 3. Internet Gateway作成
aws ec2 create-internet-gateway ...

# 4. NAT Gateway作成（2つ）
aws ec2 create-nat-gateway ...
aws ec2 create-nat-gateway ...

# 5. Route Table作成・関連付け
...

# 6. IAM Role作成（Cluster Role、Node Role）
...

# 7. EKSクラスタ作成
aws eks create-cluster ...

# 8. ノードグループ作成
aws eks create-nodegroup ...

（合計: 50コマンド以上）
```

#### eksctlで作成（簡単）

```bash
# 1コマンドで完了
eksctl create cluster
```

### インストール

#### Homebrew経由（推奨）

```bash
brew install eksctl
```

#### 確認

```bash
eksctl version
```

**期待される出力**:
```
0.193.0
```

#### awscliの確認

```bash
aws --version
```

**期待される出力**:
```
aws-cli/2.x.x Python/3.x.x Darwin/xx.x.x
```

#### kubectlの確認

```bash
kubectl version --client
```

**期待される出力**:
```
Client Version: v1.28.x
```

---

## タスク3: eksctl基本コマンドを学ぶ（1時間）

### 主要コマンド

| コマンド | 説明 |
|---------|------|
| `eksctl create cluster` | クラスタ作成 |
| `eksctl get cluster` | クラスタ一覧 |
| `eksctl delete cluster` | クラスタ削除 |
| `eksctl create nodegroup` | ノードグループ追加 |
| `eksctl delete nodegroup` | ノードグループ削除 |
| `eksctl utils write-kubeconfig` | kubeconfig更新 |

### create cluster（クラスタ作成）

#### 最小構成

```bash
eksctl create cluster
```

**デフォルト設定**:
- クラスタ名: ランダム
- リージョン: `us-west-2`
- Kubernetes バージョン: 最新
- ノード数: 2
- インスタンスタイプ: `m5.large`
- VPC: 自動作成

#### オプション指定

```bash
eksctl create cluster \
  --name my-cluster \
  --region ap-northeast-1 \
  --version 1.28 \
  --nodegroup-name my-nodes \
  --node-type t3.small \
  --nodes 1 \
  --nodes-min 1 \
  --nodes-max 3
```

**オプション説明**:

| オプション | 説明 | 例 |
|----------|------|-----|
| `--name` | クラスタ名 | `my-cluster` |
| `--region` | AWSリージョン | `ap-northeast-1` |
| `--version` | Kubernetesバージョン | `1.28` |
| `--nodegroup-name` | ノードグループ名 | `my-nodes` |
| `--node-type` | EC2インスタンスタイプ | `t3.small` |
| `--nodes` | 初期ノード数 | `1` |
| `--nodes-min` | 最小ノード数 | `1` |
| `--nodes-max` | 最大ノード数 | `3` |

### get cluster（クラスタ一覧）

```bash
eksctl get cluster
```

**期待される出力**:
```
NAME        REGION          EKSCTL CREATED
my-cluster  ap-northeast-1  True
```

### delete cluster（クラスタ削除）

```bash
eksctl delete cluster --name my-cluster
```

**削除されるもの**:
- EKSクラスタ
- ノードグループ（EC2インスタンス）
- VPC（eksctlが作成した場合）
- Internet Gateway
- NAT Gateway
- Elastic IP
- Security Group
- IAM Role（一部）

**所要時間**: 10-15分

---

## タスク4: 最小構成でEKSクラスタを作成→削除する（2時間）

### ⚠️ コスト確認

**この実習のコスト**: 約$0.50（2時間）

### クラスタ作成

```bash
eksctl create cluster \
  --name test-cluster \
  --region ap-northeast-1 \
  --version 1.28 \
  --nodegroup-name test-nodes \
  --node-type t3.small \
  --nodes 1 \
  --nodes-min 1 \
  --nodes-max 1
```

**所要時間**: 15-20分

**出力例**:
```
2024-05-14 10:00:00 [ℹ]  eksctl version 0.193.0
2024-05-14 10:00:00 [ℹ]  using region ap-northeast-1
2024-05-14 10:00:02 [ℹ]  setting availability zones to [ap-northeast-1a ap-northeast-1c]
2024-05-14 10:00:02 [ℹ]  subnets for ap-northeast-1a - public:10.0.0.0/19 private:10.0.64.0/19
2024-05-14 10:00:02 [ℹ]  subnets for ap-northeast-1c - public:10.0.32.0/19 private:10.0.96.0/19
2024-05-14 10:00:03 [ℹ]  using Kubernetes version 1.28
2024-05-14 10:00:03 [ℹ]  creating EKS cluster "test-cluster" in "ap-northeast-1" region
...
2024-05-14 10:15:00 [✔]  EKS cluster "test-cluster" in "ap-northeast-1" region is ready
```

### 確認

#### クラスタ確認

```bash
eksctl get cluster
```

**期待される出力**:
```
NAME          REGION          EKSCTL CREATED
test-cluster  ap-northeast-1  True
```

#### kubeconfigの確認

```bash
# kubeconfigが自動的に更新される
cat ~/.kube/config | grep test-cluster
```

#### kubectl動作確認

```bash
kubectl get nodes
```

**期待される出力**:
```
NAME                                                STATUS   ROLES    AGE   VERSION
ip-10-0-x-xxx.ap-northeast-1.compute.internal       Ready    <none>   5m    v1.28.x
```

#### Pod起動テスト

```bash
kubectl run nginx --image=nginx
kubectl get pods
```

**期待される出力**:
```
NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          10s
```

#### 削除

```bash
kubectl delete pod nginx
```

### AWSコンソールで確認

#### EKSクラスタ

1. AWSコンソール → **EKS**
2. クラスタ一覧に `test-cluster` が表示される
3. クリックして詳細を確認

**確認項目**:
- ステータス: `Active`
- Kubernetesバージョン: `1.28`
- エンドポイント: `https://xxxxx.eks.ap-northeast-1.amazonaws.com`

#### VPC

1. AWSコンソール → **VPC**
2. `eksctl-test-cluster-cluster/VPC` が作成されている

**確認項目**:
- CIDR: `10.0.0.0/16`
- Subnet: 4つ（Public × 2、Private × 2）
- NAT Gateway: 2つ
- Internet Gateway: 1つ

#### EC2

1. AWSコンソール → **EC2**
2. インスタンス一覧に `test-cluster-test-nodes-Node` が表示される

**確認項目**:
- タイプ: `t3.small`
- 状態: `running`
- VPC: `eksctl-test-cluster-cluster/VPC`

### クラスタ削除

```bash
eksctl delete cluster --name test-cluster
```

**所要時間**: 10-15分

**出力例**:
```
2024-05-14 11:00:00 [ℹ]  deleting EKS cluster "test-cluster"
2024-05-14 11:00:05 [ℹ]  will drain 1 unmanaged nodegroup(s) in cluster "test-cluster"
2024-05-14 11:00:10 [ℹ]  starting parallel draining, max in-flight of 1
2024-05-14 11:05:00 [ℹ]  deleted 1 Fargate profile(s)
2024-05-14 11:10:00 [✔]  all cluster resources were deleted
```

### 削除確認

```bash
# クラスタが削除されているか確認
eksctl get cluster

# VPCが削除されているか確認
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=eksctl-test-cluster-cluster/VPC" --region ap-northeast-1
```

**期待される出力**: 何も表示されない（削除完了）

---

# Part 3: eksctl設定ファイル（1.5時間）

## タスク5: eksctl設定ファイル（YAML形式）の書き方を学ぶ（1時間）

### なぜ設定ファイル？

#### コマンドライン（長い）

```bash
eksctl create cluster \
  --name my-cluster \
  --region ap-northeast-1 \
  --version 1.28 \
  --nodegroup-name my-nodes \
  --node-type t3.small \
  --nodes 1 \
  --nodes-min 1 \
  --nodes-max 3 \
  --ssh-access \
  --ssh-public-key ~/.ssh/id_rsa.pub \
  --vpc-public-subnets subnet-xxx,subnet-yyy \
  --vpc-private-subnets subnet-aaa,subnet-bbb \
  ...
```

#### 設定ファイル（わかりやすい）

```yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: my-cluster
  region: ap-northeast-1
  version: "1.28"

managedNodeGroups:
  - name: my-nodes
    instanceType: t3.small
    desiredCapacity: 1
    minSize: 1
    maxSize: 3
```

### 基本構造

```yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: <クラスタ名>
  region: <リージョン>
  version: "<Kubernetesバージョン>"

managedNodeGroups:
  - name: <ノードグループ名>
    instanceType: <インスタンスタイプ>
    desiredCapacity: <希望ノード数>
    minSize: <最小ノード数>
    maxSize: <最大ノード数>
```

### 詳細設定

```yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: production-cluster
  region: ap-northeast-1
  version: "1.28"
  tags:
    environment: production
    team: platform

# VPC設定
vpc:
  cidr: 10.0.0.0/16
  nat:
    gateway: HighlyAvailable  # NAT Gateway × 2

# IAM設定
iam:
  withOIDC: true  # IRSAを有効化

# マネージドノードグループ
managedNodeGroups:
  - name: general
    instanceType: t3.small
    desiredCapacity: 2
    minSize: 1
    maxSize: 5
    volumeSize: 20
    ssh:
      allow: true
      publicKeyPath: ~/.ssh/id_rsa.pub
    labels:
      role: general
    tags:
      nodegroup-type: general
    iam:
      attachPolicyARNs:
        - arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
        - arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
        - arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly

  - name: spot
    instanceType: t3.medium
    desiredCapacity: 0
    minSize: 0
    maxSize: 10
    spot: true  # スポットインスタンス
    labels:
      role: spot
```

### VPC設定

#### 自動作成（デフォルト）

```yaml
vpc:
  cidr: 10.0.0.0/16
  nat:
    gateway: HighlyAvailable  # NAT Gateway × 2
```

#### 既存VPCを使用

```yaml
vpc:
  id: vpc-xxxxx
  subnets:
    public:
      ap-northeast-1a:
        id: subnet-xxxxx
      ap-northeast-1c:
        id: subnet-yyyyy
    private:
      ap-northeast-1a:
        id: subnet-aaaaa
      ap-northeast-1c:
        id: subnet-bbbbb
```

### IAM設定

```yaml
iam:
  withOIDC: true  # IRSAを有効化（必須）

  serviceAccounts:
    - metadata:
        name: aws-load-balancer-controller
        namespace: kube-system
      wellKnownPolicies:
        awsLoadBalancerController: true

    - metadata:
        name: ebs-csi-controller-sa
        namespace: kube-system
      wellKnownPolicies:
        ebsCSIController: true
```

---

## タスク6: 設定ファイルからEKSクラスタを作成する（30分）

### ファイル作成

```bash
cd /Users/k24032kk/AWS_CCP/handson-kubernetes

cat > eks-test-config.yaml << 'EOF'
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: test-cluster-config
  region: ap-northeast-1
  version: "1.28"

iam:
  withOIDC: true

managedNodeGroups:
  - name: test-nodes
    instanceType: t3.small
    desiredCapacity: 1
    minSize: 1
    maxSize: 1
    volumeSize: 20
    labels:
      role: test
EOF
```

### クラスタ作成

```bash
eksctl create cluster -f eks-test-config.yaml
```

**所要時間**: 15-20分

### 確認

```bash
eksctl get cluster
kubectl get nodes
```

### 削除

```bash
eksctl delete cluster -f eks-test-config.yaml
```

または

```bash
eksctl delete cluster --name test-cluster-config
```

---

# Part 4: マネージドノードグループ（2.5時間）

## タスク7: マネージドノードグループとは何か学ぶ（30分）

### マネージドノードグループとは？

**Managed Node Group** = AWSが管理するWorker Node群

### セルフマネージド vs マネージド

| 項目 | セルフマネージド | マネージド |
|------|----------------|-----------|
| **作成** | 手動でEC2作成 | eksctlで自動作成 |
| **更新** | 手動でAMI更新 | 自動更新可能 |
| **スケーリング** | Auto Scaling Group設定 | eksctlで簡単設定 |
| **管理** | 複雑 | 簡単 |
| **推奨** | - | ✅ |

### マネージドノードグループの特徴

✅ **自動プロビジョニング**
- EC2インスタンス自動作成
- IAM Role自動設定
- Security Group自動設定

✅ **ライフサイクル管理**
- ノードの追加・削除
- AMI更新
- Kubernetesバージョンアップグレード

✅ **スケーリング**
- Cluster Autoscaler対応
- Karpenter対応

---

## タスク8: ノードグループを追加・削除する（2時間）

### ⚠️ コスト確認

**この実習のコスト**: 約$0.50（2時間）

### クラスタ作成（1ノードグループ）

```bash
cat > eks-multinode-config.yaml << 'EOF'
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: multinode-cluster
  region: ap-northeast-1
  version: "1.28"

iam:
  withOIDC: true

managedNodeGroups:
  - name: general
    instanceType: t3.small
    desiredCapacity: 1
    minSize: 1
    maxSize: 3
    labels:
      role: general
EOF
```

```bash
eksctl create cluster -f eks-multinode-config.yaml
```

### 確認

```bash
# ノードグループ一覧
eksctl get nodegroup --cluster multinode-cluster

# Node確認
kubectl get nodes --show-labels
```

**期待される出力**:
```
NAME                                                STATUS   ROLES    AGE   VERSION   LABELS
ip-10-0-x-xxx.ap-northeast-1.compute.internal       Ready    <none>   5m    v1.28.x   ...,role=general,...
```

### ノードグループ追加

```bash
eksctl create nodegroup \
  --cluster multinode-cluster \
  --name spot-nodes \
  --node-type t3.medium \
  --nodes 0 \
  --nodes-min 0 \
  --nodes-max 5 \
  --spot \
  --node-labels role=spot
```

**所要時間**: 3-5分

### 確認

```bash
# ノードグループ一覧
eksctl get nodegroup --cluster multinode-cluster
```

**期待される出力**:
```
CLUSTER             NODEGROUP   STATUS  CREATED                 MIN SIZE    MAX SIZE    DESIRED CAPACITY    INSTANCE TYPE   IMAGE ID        ASG NAME
multinode-cluster   general     ACTIVE  2024-05-14T10:00:00Z    1           3           1                   t3.small        ami-xxxxx       eks-general-xxxxx
multinode-cluster   spot-nodes  ACTIVE  2024-05-14T10:10:00Z    0           5           0                   t3.medium       ami-xxxxx       eks-spot-nodes-xxxxx
```

### スポットノードをスケールアウト

```bash
eksctl scale nodegroup \
  --cluster multinode-cluster \
  --name spot-nodes \
  --nodes 2
```

### 確認

```bash
kubectl get nodes --show-labels | grep spot
```

**期待される出力**:
```
ip-10-0-x-xxx...  Ready  <none>  1m  v1.28.x  ...,role=spot,...
ip-10-0-y-yyy...  Ready  <none>  1m  v1.28.x  ...,role=spot,...
```

### ノードグループ削除

```bash
eksctl delete nodegroup \
  --cluster multinode-cluster \
  --name spot-nodes
```

**所要時間**: 3-5分

### クラスタ削除

```bash
eksctl delete cluster --name multinode-cluster
```

---

# Part 5: Karpenter（4-5時間）

## タスク9: Karpenterとは何か、Cluster Autoscalerとの違いを学ぶ（1時間）

### Karpenterとは？

**Karpenter（カーペンター）** = Carpenter（大工）に由来

**意味**: Kubernetesのためのオートスケーラー（ノード自動追加・削除）

### Cluster Autoscaler vs Karpenter

| 項目 | Cluster Autoscaler | Karpenter |
|------|-------------------|-----------|
| **スケール判断** | Node Group単位 | Pod単位 |
| **インスタンスタイプ** | 固定 | 柔軟（複数タイプから選択） |
| **スケール速度** | 遅い（数分） | 速い（数秒） |
| **コスト最適化** | 限定的 | 優れている |
| **設定** | 複雑 | シンプル |
| **AWS統合** | 部分的 | 深い |

### Cluster Autoscalerの動作

```
1. PendingのPodを検出
2. どのNode Groupにスケールするか判断
3. Auto Scaling Groupでノード追加
4. 新ノード起動（3-5分）
5. Podがスケジューリング
```

**問題**:
- Node Group毎に固定インスタンスタイプ
- スケール遅い
- コスト最適化が難しい

### Karpenterの動作

```
1. PendingのPodを検出
2. Podの要求（CPU、メモリ、ラベル）を分析
3. 最適なインスタンスタイプを選択
4. EC2インスタンスを直接起動
5. ノード追加（数秒）
6. Podがスケジューリング
```

**利点**:
- インスタンスタイプを柔軟に選択
- スケール速い
- コスト最適化

### Karpenterの仕組み

```
Karpenter Controller（Pod）
    ↓ 監視
Pending Pods
    ↓ 分析
Provisioner（設定）
    ├ インスタンスタイプ候補
    ├ アベイラビリティゾーン
    └ Taints/Labels
    ↓ 選択
最適なEC2インスタンス
    ↓ 直接起動
新しいNode
```

---

## タスク10: KarpenterをHelmでインストールする（IRSA設定含む）（2時間）

### 前提条件

- EKSクラスタが作成済み
- IAM OIDCプロバイダーが有効
- Helmがインストール済み

### Helm インストール（まだの場合）

```bash
brew install helm
helm version
```

### クラスタ作成（Karpenter用）

```bash
cat > eks-karpenter-cluster.yaml << 'EOF'
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: karpenter-cluster
  region: ap-northeast-1
  version: "1.28"

iam:
  withOIDC: true

karpenter:
  version: v0.33.0

managedNodeGroups:
  - name: karpenter-nodes
    instanceType: t3.small
    desiredCapacity: 2
    minSize: 1
    maxSize: 3
    labels:
      role: karpenter
EOF
```

```bash
eksctl create cluster -f eks-karpenter-cluster.yaml
```

**所要時間**: 20-25分

**`karpenter` セクションの効果**:
- Karpenter用のIAM Roleを自動作成
- ServiceAccountを自動作成
- IRSAを自動設定

### Karpenterインストール

```bash
# Helm Repoを追加
helm repo add karpenter https://charts.karpenter.sh
helm repo update

# Karpenterをインストール
helm install karpenter karpenter/karpenter \
  --namespace karpenter \
  --create-namespace \
  --set serviceAccount.create=false \
  --set settings.clusterName=karpenter-cluster \
  --set settings.clusterEndpoint=$(aws eks describe-cluster --name karpenter-cluster --query "cluster.endpoint" --output text) \
  --set defaultProvisioner.create=false \
  --set settings.interruptionQueue=karpenter-cluster
```

**所要時間**: 1-2分

### 確認

```bash
# Karpenter Podの確認
kubectl get pods -n karpenter
```

**期待される出力**:
```
NAME                        READY   STATUS    RESTARTS   AGE
karpenter-xxxxxxxxx-xxxxx   1/1     Running   0          1m
karpenter-xxxxxxxxx-xxxxx   1/1     Running   0          1m
```

```bash
# ServiceAccountの確認
kubectl get sa -n karpenter karpenter
```

**期待される出力**:
```
NAME        SECRETS   AGE
karpenter   0         1m
```

```bash
# annotationの確認（IRSA）
kubectl describe sa -n karpenter karpenter | grep role-arn
```

**期待される出力**:
```
Annotations:  eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/eksctl-karpenter-cluster-addon-iamserviceaccount-Role1-xxxxx
```

---

## タスク11: Provisioner/NodePoolを作成する（1時間）

### Provisioner（v0.33以前）vs NodePool（v0.34以降）

| 項目 | Provisioner（旧） | NodePool（新） |
|------|-----------------|--------------|
| **APIバージョン** | `karpenter.sh/v1alpha5` | `karpenter.sh/v1beta1` |
| **リソース名** | Provisioner | NodePool |
| **推奨** | - | ✅ |

**Phase 3では**: NodePool（v1beta1）を使用

### NodePool作成

```bash
cat > karpenter-nodepool.yaml << 'EOF'
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: default
spec:
  template:
    spec:
      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["on-demand"]
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
        - key: node.kubernetes.io/instance-type
          operator: In
          values: ["t3.small", "t3.medium"]
      nodeClassRef:
        name: default
  limits:
    cpu: "10"
    memory: 20Gi
  disruption:
    consolidationPolicy: WhenUnderutilized
    expireAfter: 720h  # 30日
---
apiVersion: karpenter.k8s.aws/v1beta1
kind: EC2NodeClass
metadata:
  name: default
spec:
  amiFamily: AL2
  role: KarpenterNodeRole-karpenter-cluster
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: karpenter-cluster
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: karpenter-cluster
EOF
```

```bash
kubectl apply -f karpenter-nodepool.yaml
```

### 確認

```bash
kubectl get nodepool
```

**期待される出力**:
```
NAME      CAPACITY TYPE
default   on-demand
```

---

## タスク12: Podをスケールアウトして新ノード起動を確認する（1時間）

### テスト用Deployment作成

```bash
cat > test-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inflate
spec:
  replicas: 0
  selector:
    matchLabels:
      app: inflate
  template:
    metadata:
      labels:
        app: inflate
    spec:
      terminationGracePeriodSeconds: 0
      containers:
      - name: inflate
        image: public.ecr.aws/eks-distro/kubernetes/pause:3.7
        resources:
          requests:
            cpu: 1
EOF
```

```bash
kubectl apply -f test-deployment.yaml
```

### スケールアウト

```bash
kubectl scale deployment inflate --replicas=10
```

### 監視

**ターミナル1（Pod監視）**:
```bash
kubectl get pods -w
```

**ターミナル2（Node監視）**:
```bash
kubectl get nodes -w
```

**期待される動作**:
1. 10個のPodが`Pending`状態
2. Karpenterが新しいNodeを自動追加（数秒）
3. Podが`Running`状態に変わる

**確認**:
```bash
kubectl get nodes --show-labels | grep karpenter
```

Karpenterが追加したNodeには `karpenter.sh/provisioner-name=default` ラベルが付く

---

## タスク13: ノードの自動削除を確認する（30分）

### スケールイン

```bash
kubectl scale deployment inflate --replicas=0
```

### 監視

```bash
kubectl get nodes -w
```

**期待される動作**:
- 数分後、Karpenterが追加したNodeが自動削除される

**確認**:
```bash
kubectl get nodes
```

Karpenterが追加したNodeが削除され、元のNodeだけ残る

### クラスタ削除

```bash
eksctl delete cluster --name karpenter-cluster
```

---

# Part 6: EBS CSI Driver（3.5時間）

## タスク14: EBS CSI Driverとは何か、動的プロビジョニングを学ぶ（30分）

### EBS CSI Driver とは？

**EBS CSI Driver** = **E**lastic **B**lock **S**tore **C**ontainer **S**torage **I**nterface Driver

**意味**: KubernetesからEBSボリュームを使うためのドライバー

### なぜ必要？

#### 従来（in-tree driver）

```
Kubernetesに組み込み
  ↓
EBSボリュームを作成
  ↓
問題: Kubernetesのバージョンアップ毎に更新必要
```

#### EBS CSI Driver（out-of-tree driver）

```
独立したドライバー
  ↓
EBSボリュームを作成
  ↓
利点: Kubernetes本体と独立して更新可能
```

### 動的プロビジョニング

```
1. PVCを作成
2. EBS CSI DriverがEBSボリュームを自動作成
3. PVを自動作成してPVCとバインド
4. Podにマウント
```

**Phase 3での使い道**: PostgreSQLのデータ永続化

---

## タスク15: EBS CSI DriverをEKS Addonとして追加する（IRSA設定含む）（2時間）

### クラスタ作成

```bash
cat > eks-ebs-cluster.yaml << 'EOF'
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: ebs-cluster
  region: ap-northeast-1
  version: "1.28"

iam:
  withOIDC: true

managedNodeGroups:
  - name: ebs-nodes
    instanceType: t3.small
    desiredCapacity: 1
    minSize: 1
    maxSize: 1
EOF
```

```bash
eksctl create cluster -f eks-ebs-cluster.yaml
```

### IAM Role作成（EBS CSI Driver用）

```bash
eksctl create iamserviceaccount \
  --cluster ebs-cluster \
  --namespace kube-system \
  --name ebs-csi-controller-sa \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve \
  --role-name AmazonEKS_EBS_CSI_DriverRole
```

### EBS CSI DriverをAddonとして追加

```bash
eksctl create addon \
  --cluster ebs-cluster \
  --name aws-ebs-csi-driver \
  --service-account-role-arn $(aws iam get-role --role-name AmazonEKS_EBS_CSI_DriverRole --query 'Role.Arn' --output text)
```

### 確認

```bash
# Addonの確認
eksctl get addon --cluster ebs-cluster
```

**期待される出力**:
```
NAME                VERSION         STATUS  ISSUES  IAMROLE
aws-ebs-csi-driver  v1.25.0-eksbuild.1  ACTIVE  0
```

```bash
# Podの確認
kubectl get pods -n kube-system | grep ebs-csi
```

**期待される出力**:
```
ebs-csi-controller-xxxxxxxxx-xxxxx   6/6     Running   0          2m
ebs-csi-controller-xxxxxxxxx-xxxxx   6/6     Running   0          2m
ebs-csi-node-xxxxx                   3/3     Running   0          2m
```

---

## タスク16: StorageClass（gp3、volumeBindingMode）を作成する（30分）

### StorageClass作成

```bash
cat > storageclass-gp3.yaml << 'EOF'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  fsType: ext4
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
EOF
```

```bash
kubectl apply -f storageclass-gp3.yaml
```

### 確認

```bash
kubectl get storageclass
```

**期待される出力**:
```
NAME   PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      AGE
gp2    kubernetes.io/aws-ebs   Delete          WaitForFirstConsumer   10m
gp3    ebs.csi.aws.com         Delete          WaitForFirstConsumer   1m
```

### volumeBindingModeの意味

| モード | 動作 |
|-------|------|
| **Immediate** | PVC作成時に即座にEBSボリューム作成 |
| **WaitForFirstConsumer** | Podが作成されるまで待つ（推奨） |

**WaitForFirstConsumerの利点**:
- PodがスケジューリングされたAZにEBSボリュームを作成
- AZミスマッチを防ぐ

---

## タスク17: StorageClassを使ってPVCをテストする（30分）

### PVC作成

```bash
cat > test-pvc.yaml << 'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gp3
  resources:
    requests:
      storage: 10Gi
EOF
```

```bash
kubectl apply -f test-pvc.yaml
```

### 確認（Pending状態）

```bash
kubectl get pvc
```

**期待される出力**:
```
NAME       STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
test-pvc   Pending                                      gp3            10s
```

**理由**: `WaitForFirstConsumer` のため、Podが作成されるまで待機

### Pod作成

```bash
cat > test-pod-with-pvc.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: test-pvc
EOF
```

```bash
kubectl apply -f test-pod-with-pvc.yaml
```

### 確認（Bound状態）

```bash
kubectl get pvc
```

**期待される出力**:
```
NAME       STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
test-pvc   Bound    pvc-12345678-1234-1234-1234-123456789abc   10Gi       RWO            gp3            1m
```

```bash
kubectl get pv
```

**期待される出力**:
```
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM
pvc-12345678-1234-1234-1234-123456789abc   10Gi       RWO            Delete           Bound    default/test-pvc
```

### データ永続化テスト

```bash
# データ書き込み
kubectl exec test-pod -- sh -c "echo 'EBS Test Data' > /data/test.txt"

# 確認
kubectl exec test-pod -- cat /data/test.txt
# 出力: EBS Test Data

# Pod削除
kubectl delete pod test-pod

# Pod再作成
kubectl apply -f test-pod-with-pvc.yaml

# データが残っているか確認
kubectl exec test-pod -- cat /data/test.txt
# 出力: EBS Test Data ← データが残っている！
```

### 削除

```bash
kubectl delete -f test-pod-with-pvc.yaml
kubectl delete -f test-pvc.yaml
```

### クラスタ削除

```bash
eksctl delete cluster --name ebs-cluster
```

---

# Part 7: AWS Load Balancer Controller（4.5時間）

## タスク18: AWS Load Balancer Controllerとは何か学ぶ（ALB/NLB自動作成）（30分）

### AWS Load Balancer Controller とは？

**意味**: KubernetesのIngressリソースから自動的にALB/NLBを作成するコントローラー

### 従来のLoadBalancer Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  type: LoadBalancer
  selector:
    app: myapp
  ports:
  - port: 80
```

**問題**:
- Classic Load Balancerが作成される（古い）
- パスベースルーティングができない
- HTTPSはService毎に設定が必要

### Ingress + ALB Controller

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
spec:
  rules:
  - http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 8080
      - path: /web
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

**利点**:
- Application Load Balancer（ALB）が自動作成される
- パスベースルーティング
- ホストベースルーティング
- 1つのALBで複数Serviceを公開

---

## タスク19: ALB ControllerをHelmでインストールする（IRSA設定含む）（2時間）

### クラスタ作成

```bash
cat > eks-alb-cluster.yaml << 'EOF'
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: alb-cluster
  region: ap-northeast-1
  version: "1.28"

iam:
  withOIDC: true

managedNodeGroups:
  - name: alb-nodes
    instanceType: t3.small
    desiredCapacity: 1
    minSize: 1
    maxSize: 1
EOF
```

```bash
eksctl create cluster -f eks-alb-cluster.yaml
```

### IAM Policy作成

```bash
curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.0/docs/install/iam_policy.json

aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://iam-policy.json
```

### IAM Role作成（IRSA）

```bash
eksctl create iamserviceaccount \
  --cluster alb-cluster \
  --namespace kube-system \
  --name aws-load-balancer-controller \
  --attach-policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/AWSLoadBalancerControllerIAMPolicy \
  --approve
```

### ALB ControllerをHelmでインストール

```bash
# Helm Repo追加
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# ALB Controllerインストール
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=alb-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

### 確認

```bash
kubectl get pods -n kube-system | grep aws-load-balancer-controller
```

**期待される出力**:
```
aws-load-balancer-controller-xxxxxxxxx-xxxxx   1/1     Running   0          1m
aws-load-balancer-controller-xxxxxxxxx-xxxxx   1/1     Running   0          1m
```

---

## タスク20: ALB Ingressを作成する（1時間）

### テスト用アプリ作成

```bash
cat > test-app.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: ClusterIP
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
EOF
```

```bash
kubectl apply -f test-app.yaml
```

### Ingress作成

```bash
cat > alb-ingress.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  ingressClassName: alb
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx-service
            port:
              number: 80
EOF
```

```bash
kubectl apply -f alb-ingress.yaml
```

### 確認

```bash
kubectl get ingress
```

**期待される出力**:
```
NAME            CLASS   HOSTS   ADDRESS                                                                  PORTS   AGE
nginx-ingress   alb     *       k8s-default-nginxing-xxxxxxxxxx-1234567890.ap-northeast-1.elb.amazonaws.com   80      2m
```

### アクセステスト

```bash
# ALBのDNS名を取得
ALB_DNS=$(kubectl get ingress nginx-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# アクセステスト
curl http://$ALB_DNS
```

**期待される出力**: nginxのHTMLが表示される

---

## タスク21: Ingressアノテーション（alb.ingress.kubernetes.io/*）を理解する（30分）

### 主なアノテーション

| アノテーション | 説明 | 値の例 |
|--------------|------|--------|
| `alb.ingress.kubernetes.io/scheme` | ALBの配置 | `internet-facing`, `internal` |
| `alb.ingress.kubernetes.io/target-type` | ターゲットタイプ | `ip`, `instance` |
| `alb.ingress.kubernetes.io/certificate-arn` | SSL証明書 | `arn:aws:acm:...` |
| `alb.ingress.kubernetes.io/listen-ports` | リスニングポート | `'[{"HTTP": 80}, {"HTTPS": 443}]'` |
| `alb.ingress.kubernetes.io/healthcheck-path` | ヘルスチェックパス | `/health` |
| `alb.ingress.kubernetes.io/subnets` | サブネット指定 | `subnet-xxx,subnet-yyy` |

### HTTPS対応の例

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress-https
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:ap-northeast-1:123456789012:certificate/xxxxx
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/ssl-redirect: '443'
spec:
  ingressClassName: alb
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx-service
            port:
              number: 80
```

---

## タスク22: サンプルアプリをALBで公開する（1時間）

### 複数パスのルーティング

```bash
cat > multi-path-ingress.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: api
        image: hashicorp/http-echo
        args:
          - "-text=API Response"
        ports:
        - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: api-service
spec:
  type: ClusterIP
  selector:
    app: api
  ports:
  - port: 5678
    targetPort: 5678
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: web
        image: hashicorp/http-echo
        args:
          - "-text=Web Response"
        ports:
        - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  type: ClusterIP
  selector:
    app: web
  ports:
  - port: 5678
    targetPort: 5678
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-path-ingress
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  ingressClassName: alb
  rules:
  - http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 5678
      - path: /web
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 5678
EOF
```

```bash
kubectl apply -f multi-path-ingress.yaml
```

### テスト

```bash
# ALBのDNS名を取得
ALB_DNS=$(kubectl get ingress multi-path-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# /apiアクセス
curl http://$ALB_DNS/api
# 出力: API Response

# /webアクセス
curl http://$ALB_DNS/web
# 出力: Web Response
```

### クラスタ削除

```bash
eksctl delete cluster --name alb-cluster
```

---

# Part 8: Helm基礎（1.5時間）

## タスク23: Helmとは何か、Chartを学ぶ（30分）

### Helmとは？

**Helm（ヘルム）** = 舵（船の操縦装置）

**意味**: Kubernetesのパッケージマネージャー

### なぜHelmが必要？

#### 手動デプロイ（大変）

```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml
kubectl apply -f serviceaccount.yaml
kubectl apply -f role.yaml
kubectl apply -f rolebinding.yaml
...（10ファイル以上）
```

#### Helmデプロイ（簡単）

```bash
helm install myapp ./myapp-chart
```

### Helm Chart とは？

**Chart** = Kubernetesリソース定義のパッケージ

```
Chart（パッケージ）
  ├── Chart.yaml（メタデータ）
  ├── values.yaml（デフォルト設定）
  └── templates/（YAMLテンプレート）
        ├── deployment.yaml
        ├── service.yaml
        └── ingress.yaml
```

### Helm Repositoryとは？

**Repository** = Chartを配布する場所

**主なRepository**:
- Artifact Hub: https://artifacthub.io/
- Bitnami: https://charts.bitnami.com/bitnami
- AWS: https://aws.github.io/eks-charts

---

## タスク24: Helm基本コマンドを学ぶ（30分）

### 主要コマンド

| コマンド | 説明 |
|---------|------|
| `helm repo add` | リポジトリを追加 |
| `helm repo update` | リポジトリを更新 |
| `helm search repo` | Chartを検索 |
| `helm install` | Chartをインストール |
| `helm list` | インストール済みChart一覧 |
| `helm upgrade` | Chartを更新 |
| `helm uninstall` | Chartをアンインストール |

### repo add（リポジトリ追加）

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

### search repo（Chart検索）

```bash
helm search repo nginx
```

**出力例**:
```
NAME                            CHART VERSION   APP VERSION     DESCRIPTION
bitnami/nginx                   15.0.0          1.25.4          NGINX Open Source is a web server...
bitnami/nginx-ingress-controller 10.0.0         1.9.5           NGINX Ingress Controller...
```

### install（インストール）

```bash
helm install my-nginx bitnami/nginx
```

### list（一覧）

```bash
helm list
```

**出力例**:
```
NAME      NAMESPACE  REVISION  UPDATED                                STATUS    CHART         APP VERSION
my-nginx  default    1         2024-05-14 10:00:00.000000 +0900 JST  deployed  nginx-15.0.0  1.25.4
```

### uninstall（アンインストール）

```bash
helm uninstall my-nginx
```

---

## タスク25: サンプルChartをインストールする（30分）

### クラスタ作成（またはLevel 4で作成したクラスタを使用）

既存のクラスタがあればそれを使用、なければ作成:

```bash
eksctl create cluster --name helm-test-cluster --region ap-northeast-1 --node-type t3.small --nodes 1
```

### Repositoryを追加

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

### nginxをインストール

```bash
helm install my-nginx bitnami/nginx --set service.type=LoadBalancer
```

### 確認

```bash
# Release確認
helm list

# Pod確認
kubectl get pods

# Service確認
kubectl get svc
```

**期待される出力**:
```
NAME                TYPE           CLUSTER-IP      EXTERNAL-IP                                                               PORT(S)        AGE
my-nginx-nginx      LoadBalancer   10.100.xxx.xxx  xxxxx.ap-northeast-1.elb.amazonaws.com                                   80:xxxxx/TCP   2m
```

### アクセステスト

```bash
# LoadBalancerのDNS名を取得
LB_DNS=$(kubectl get svc my-nginx-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# アクセステスト
curl http://$LB_DNS
```

### アンインストール

```bash
helm uninstall my-nginx
```

### クラスタ削除

```bash
eksctl delete cluster --name helm-test-cluster
```

---

# Level 4 全体まとめ

## 完了したタスク

- [x] EKSとは何か、アーキテクチャ（Control Plane、Data Plane）を学ぶ
- [x] eksctlをHomebrewでインストールする
- [x] eksctl基本コマンドを学ぶ（create cluster、create nodegroup、delete cluster）
- [x] 最小構成でEKSクラスタを作成→削除する
- [x] eksctl設定ファイル（YAML形式）の書き方を学ぶ
- [x] 設定ファイルからEKSクラスタを作成する
- [x] マネージドノードグループとは何か学ぶ
- [x] ノードグループを追加・削除する
- [x] Karpenterとは何か、Cluster Autoscalerとの違いを学ぶ
- [x] KarpenterをHelmでインストールする（IRSA設定含む）
- [x] Provisioner/NodePoolを作成する
- [x] Podをスケールアウトして新ノード起動を確認する
- [x] ノードの自動削除を確認する
- [x] EBS CSI Driverとは何か、動的プロビジョニングを学ぶ
- [x] EBS CSI DriverをEKS Addonとして追加する（IRSA設定含む）
- [x] StorageClass（gp3、volumeBindingMode）を作成する
- [x] StorageClassを使ってPVCをテストする
- [x] AWS Load Balancer Controllerとは何か学ぶ（ALB/NLB自動作成）
- [x] ALB ControllerをHelmでインストールする（IRSA設定含む）
- [x] ALB Ingressを作成する
- [x] Ingressアノテーション（alb.ingress.kubernetes.io/*）を理解する
- [x] サンプルアプリをALBで公開する
- [x] Helmとは何か、Chartを学ぶ
- [x] Helm基本コマンドを学ぶ（repo add、install、list、uninstall）
- [x] サンプルChartをインストールする

## 習得したスキル

| スキル | Phase 3での使い道 |
|--------|------------------|
| **eksctl** | EKSクラスタ作成・削除 |
| **マネージドノードグループ** | Worker Node管理 |
| **Karpenter** | 自動スケーリング |
| **EBS CSI Driver** | PostgreSQLのデータ永続化 |
| **ALB Controller** | nginxへのHTTPアクセス |
| **Helm** | パッケージ管理 |

## Level 4のコスト総額（目安）

| 実習 | 時間 | コスト |
|------|------|--------|
| タスク4（最小構成） | 2時間 | $0.50 |
| タスク8（ノードグループ） | 2時間 | $0.50 |
| タスク10-13（Karpenter） | 3時間 | $0.75 |
| タスク15-17（EBS CSI） | 2時間 | $0.50 |
| タスク19-22（ALB Controller） | 3時間 | $0.75 |
| タスク25（Helm） | 1時間 | $0.25 |
| **合計** | **13時間** | **$3.25** |

**実際のコスト**: 削除忘れがなければ$3-5程度

## 次のステップ

**Phase 3直前の準備** に進む

minikubeでnginx + PostgreSQL構成を予行演習してから、Phase 3で本番環境（EKS）に挑みます。

---

**作成日**: 2026-05-14
**目的**: Phase 3検証環境構築に向けたEKS実践スキル習得
**対象者**: Level 1-3を完了した人
**⚠️ 重要**: 実習後は必ずクラスタを削除すること！
