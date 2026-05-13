# EKS完全理解ロードマップ

**目的**: EKS（Elastic Kubernetes Service）を段階的に理解する

**前提**: AWS CCPの基礎知識がある

---

## 学習の全体像

```
Level 0: 基礎準備（完了済み）
    ↓
Level 1: ローカルKubernetes（minikube） ← 今ここ推奨
    ↓
Level 2: Kubernetes中級
    ↓
Level 3: AWS基礎（VPC/IAM復習）
    ↓
Level 4: EKS標準モード
    ↓
Level 5: EKS Auto Mode
```

---

## Level 0: 基礎準備（完了済み ✅）

### 既に学んだこと

✅ VPC、サブネット、IGW、NAT Gateway
✅ Terraform基礎
✅ EC2インスタンス
✅ セキュリティグループ
✅ IAMロール

**ファイル**: `/Users/k24032kk/AWS_CCP/handson-terraform/11_vpc_multisubnet.md`

---

## Level 1: ローカルKubernetes（minikube）⭐

### なぜローカルから始めるべきか？

```
ローカル（minikube）:
✅ 無料
✅ すぐ試せる
✅ 失敗しても安心
✅ 何度でもやり直せる
✅ Kubernetesの基本に集中できる

EKS:
❌ 課金される
❌ セットアップ複雑
❌ AWS知識も必要
❌ トラブルシューティング困難
```

### 学ぶべき内容

#### 1-1: 環境構築（完了済み ✅）

- Docker Desktop インストール
- minikube インストール
- kubectl インストール

**ファイル**: `/Users/k24032kk/AWS_CCP/handson-kubernetes/12_local_kubernetes_basics.md`

---

#### 1-2: Kubernetes基本リソース（推奨順）

##### ① Pod（最小単位）

**何をする**: 1つのコンテナを起動する

```bash
# Podを作成
kubectl run nginx-pod --image=nginx:latest

# 確認
kubectl get pods
kubectl describe pod nginx-pod

# ログ確認
kubectl logs nginx-pod

# 削除
kubectl delete pod nginx-pod
```

**学ぶこと**:
- Podとは何か？
- コンテナとの違い
- PodのライフサイクルステージS（Pending → Running → Succeeded/Failed）

**所要時間**: 30分

---

##### ② Deployment（Pod管理）

**何をする**: 複数Podを管理・自動復旧

**ファイル**: `/Users/k24032kk/AWS_CCP/handson-kubernetes/nginx-deployment.yaml`

```bash
# Deploymentを作成
kubectl apply -f /Users/k24032kk/AWS_CCP/handson-kubernetes/nginx-deployment.yaml

# 確認
kubectl get deployments
kubectl get pods

# Podを削除してみる（自動復旧される）
kubectl delete pod <pod名>
kubectl get pods  # 新しいPodが自動作成される

# スケーリング
kubectl scale deployment nginx-deployment --replicas=5
kubectl get pods

# 削除
kubectl delete deployment nginx-deployment
```

**学ぶこと**:
- Deploymentの役割
- 自動復旧（Self-healing）
- スケーリング
- ローリングアップデート

**所要時間**: 1時間

---

##### ③ Service（ネットワーク）

**何をする**: Podへの安定したアクセス提供

**ファイル**: `/Users/k24032kk/AWS_CCP/handson-kubernetes/nginx-service.yaml`

```bash
# Serviceを作成
kubectl apply -f /Users/k24032kk/AWS_CCP/handson-kubernetes/nginx-service.yaml

# 確認
kubectl get services

# minikubeでアクセス
minikube service nginx-service

# または
kubectl port-forward service/nginx-service 8080:80
# ブラウザで http://localhost:8080

# 削除
kubectl delete service nginx-service
```

**学ぶこと**:
- ServiceのClusterIP、NodePort、LoadBalancer
- DNS名によるアクセス
- 負荷分散

**所要時間**: 1時間

**関連教材**: `/Users/k24032kk/AWS_CCP/handson-kubernetes/14_kubernetes_network.md`

---

##### ④ ConfigMap（設定管理）

**何をする**: 設定を外部化

**ファイル**: `/Users/k24032kk/AWS_CCP/handson-kubernetes/13_configmap_basics.md`

```bash
# 教材に従って実践
```

**学ぶこと**:
- ConfigMapの必要性
- 環境変数としての使用
- ファイルとしてのマウント

**所要時間**: 1.5時間

---

#### 1-3: 実践プロジェクト

**目標**: 簡単なWebアプリをKubernetesで動かす

```yaml
# WordPress + MySQL の構成
WordPress（3 Pods）
    ↓ Service
MySQL（1 Pod）
    ↓ PersistentVolume（データ永続化）
```

**学ぶこと**:
- 複数コンポーネントの連携
- データベース接続
- データの永続化

**所要時間**: 2-3時間

---

## Level 2: Kubernetes中級

### 2-1: リソース管理

#### リソース制限

```yaml
resources:
  requests:   # 最低限必要
    cpu: 250m
    memory: 256Mi
  limits:     # 最大使用可能
    cpu: 500m
    memory: 512Mi
```

**学ぶこと**:
- CPUとメモリの指定方法
- リソース不足時の挙動
- QoS（Quality of Service）

**所要時間**: 1時間

---

#### Liveness Probe / Readiness Probe

```yaml
livenessProbe:   # 生きているか？
  httpGet:
    path: /health
    port: 80
  initialDelaySeconds: 10
  periodSeconds: 5

readinessProbe:  # リクエスト受付可能か？
  httpGet:
    path: /ready
    port: 80
  initialDelaySeconds: 5
  periodSeconds: 3
```

**学ぶこと**:
- ヘルスチェック
- 自動再起動
- トラフィック制御

**所要時間**: 1時間

---

### 2-2: ストレージ

#### PersistentVolume (PV) / PersistentVolumeClaim (PVC)

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```

**学ぶこと**:
- データの永続化
- ボリュームの種類
- StatefulSetとの違い

**所要時間**: 2時間

---

### 2-3: セキュリティ

#### Secret（機密情報管理）

```bash
# Secretを作成
kubectl create secret generic db-secret \
  --from-literal=username=admin \
  --from-literal=password=secretpass

# Podで使用
envFrom:
  - secretRef:
      name: db-secret
```

**学ぶこと**:
- ConfigMapとの違い
- Base64エンコーディング
- 機密情報の扱い

**所要時間**: 1時間

---

## Level 3: AWS基礎（VPC/IAM復習）

### なぜEKSの前に復習？

EKSはAWSリソースを大量に使うため、AWS基礎の理解が必須

### 3-1: VPC復習

**必須知識**:
- ✅ VPC、サブネット（パブリック/プライベート）
- ✅ インターネットゲートウェイ（IGW）
- ✅ NATゲートウェイ
- ✅ ルートテーブル
- ✅ セキュリティグループ

**確認方法**: 以前のTerraform教材を見返す

**ファイル**: `/Users/k24032kk/AWS_CCP/handson-terraform/11_vpc_multisubnet.md`

**所要時間**: 1時間（復習）

---

### 3-2: IAM深堀り

#### IAMロールとは？

```
IAMユーザー: 人間が使う（アクセスキー/パスワード）
    ↓
IAMロール: AWSリソースが使う（一時的な認証情報）
```

#### EKSで必要なロール

```
①クラスタロール（Control Plane用）
  └── EKSがEC2・ELB・VPCを操作する権限

②ノードロール（Worker Node用）
  └── EC2がECR・CloudWatchにアクセスする権限
```

#### 信頼関係（Trust Relationship）

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Service": "ec2.amazonaws.com"  ← EC2がこのロールを引き受けられる
    },
    "Action": "sts:AssumeRole"
  }]
}
```

#### インスタンスプロファイル

```
IAMロール（抽象的な権限）
    ↓
インスタンスプロファイル（EC2に割り当てる実体）
    ↓
EC2インスタンス
```

**学ぶこと**:
- IAMロールの仕組み
- 信頼関係とは
- インスタンスプロファイルとは
- ポリシーのアタッチ

**所要時間**: 2時間

---

### 3-3: ELB（Elastic Load Balancer）

#### 3種類のロードバランサー

| 種類 | 用途 | レイヤー |
|------|------|---------|
| **ALB** | HTTP/HTTPS | Layer 7（アプリケーション層） |
| **NLB** | TCP/UDP | Layer 4（トランスポート層） |
| **CLB** | 旧型（非推奨） | Layer 4/7 |

**EKSでの使い分け**:
- **ALB**: Ingressで使用（パスベースルーティング）
- **NLB**: Service type=LoadBalancerで使用（高性能）

**所要時間**: 1時間

---

## Level 4: EKS標準モード（重要⭐）

### なぜ標準モードから？

```
標準モード:
✅ 全てを手動設定 → 仕組みが理解できる
✅ トラブルシューティングしやすい
✅ カスタマイズ自由

Auto Mode:
❌ 自動化されすぎて何が起きているか分からない
❌ トラブル時に対処できない
```

---

### 4-1: EKSクラスタ作成（コンソール）

#### 前提条件

1. **VPCの準備**
   - パブリックサブネット × 2
   - プライベートサブネット × 2
   - NAT Gateway × 2

2. **IAMロールの準備**
   - クラスタロール
   - ノードロール

#### 手順

**Step 1: クラスタ作成**

1. EKSコンソール → クラスターを作成
2. **名前**: `my-eks-cluster`
3. **Kubernetesバージョン**: 最新
4. **クラスタサービスロール**: 作成したクラスタロール
5. **VPC**: 準備したVPC
6. **サブネット**: プライベートサブネット × 2を選択
7. **セキュリティグループ**: デフォルト
8. 作成（約15分）

**Step 2: ノードグループ作成**

1. クラスタ → Compute → ノードグループを追加
2. **名前**: `my-node-group`
3. **ノードIAMロール**: 準備したノードロール
4. **インスタンスタイプ**: `t3.medium`
5. **ディスクサイズ**: 20GB
6. **スケーリング設定**:
   - 最小: 2
   - 最大: 4
   - 希望: 2
7. **サブネット**: プライベートサブネット × 2
8. 作成（約5分）

**Step 3: kubectl設定**

```bash
aws eks update-kubeconfig --region ap-northeast-1 --name my-eks-cluster
kubectl get nodes
```

**所要時間**: 2時間

---

### 4-2: AWS Load Balancer Controllerのインストール

**何をする**: KubernetesのServiceをAWS ELBと連携

```bash
# Helmインストール（まだの場合）
brew install helm

# AWS Load Balancer Controllerをインストール
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=my-eks-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

**所要時間**: 1時間

---

### 4-3: サンプルアプリをデプロイ

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
```

```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# ELBのDNS名を取得
kubectl get svc nginx-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# ブラウザでアクセス
```

**学ぶこと**:
- EKSとAWSの連携
- LoadBalancerの自動作成
- 実際のトラフィック流れ

**所要時間**: 1時間

---

### 4-4: EKS標準モードで理解すべきこと

#### ①ノードグループとは

```
ノードグループ = EC2 Auto Scaling Groupのラッパー

設定項目:
- インスタンスタイプ
- AMI
- スケーリング設定
- サブネット
- セキュリティグループ
```

#### ②VPC CNIの仕組み

```
通常のKubernetes:
Pod → 仮想IP（クラスタ内のみ）

EKS VPC CNI:
Pod → VPCのIPアドレス（直接割り当て）
    ↓
VPC内の他のリソースから直接アクセス可能
```

#### ③EKSのコスト構造

| 項目 | 料金 |
|------|------|
| クラスタ | $0.10/時間 = $72/月 |
| EC2 (t3.medium × 2) | $0.0416 × 2 × 24 × 30 = $60/月 |
| NAT Gateway × 2 | $0.045 × 2 × 24 × 30 = $65/月 |
| データ転送 | 変動 |
| **合計** | **約$197/月** |

**所要時間**: 1時間（理解）

---

## Level 5: EKS Auto Mode

### 前提条件

✅ Level 4（EKS標準モード）を完全に理解している

### Auto Modeとの違い

| 項目 | 標準モード | Auto Mode |
|------|-----------|-----------|
| ノードグループ | 手動作成 | 不要 |
| スケーリング | 手動設定（ASG） | 自動（Karpenter） |
| アドオン | 手動インストール | 組み込み済み |
| ノード管理 | 手動 | AWS管理 |
| AMI選択 | 手動 | 自動（Bottlerocket） |
| コスト | 安い | +12%高い |

### Auto Modeを理解するために必要な知識

#### ① Karpenter

**何をする**: Podの要求に応じて最適なノードを自動作成

```
従来（Cluster Autoscaler）:
ノードグループを事前定義 → その範囲でスケール

Karpenter:
Podの要求を見る → 最適なインスタンスを選択 → 作成
```

#### ② Bottlerocket OS

**何をする**: コンテナ実行に特化したLinux

```
Amazon Linux 2:
- 汎用OS
- 多くのパッケージ
- SSH可能

Bottlerocket:
- コンテナ専用
- 最小構成
- SSH不可（セキュリティ向上）
- イミュータブル（変更不可）
```

#### ③ NodePool / NodeClass

**NodePool**: どんなノードが欲しいか（要件）
```yaml
requirements:
  - key: karpenter.sh/capacity-type
    operator: In
    values: ["on-demand"]
  - key: kubernetes.io/arch
    operator: In
    values: ["amd64"]
```

**NodeClass**: AWS固有の設定（サブネット、SG、IAMロール）
```yaml
subnetSelectorTerms:
  - id: subnet-xxxxx
  - id: subnet-yyyyy
securityGroupSelectorTerms:
  - id: sg-zzzzz
```

**所要時間**: 2時間（理解）

---

### Auto Mode実践

**ファイル**: `/Users/k24032kk/AWS_CCP/handson/10_eks_auto_mode.md`

**注意点**:
- 標準モードを理解してから
- トラブルシューティングは困難
- 課金に注意

**所要時間**: 3時間

---

## 推奨学習順序（まとめ）

### Week 1: Kubernetesローカル基礎

**目標**: minikubeでKubernetesの基本を完全マスター

- [ ] Day 1-2: Pod / Deployment
- [ ] Day 3-4: Service / ネットワーク
- [ ] Day 5-6: ConfigMap / Secret
- [ ] Day 7: 復習 + 小プロジェクト

**教材**:
- `/Users/k24032kk/AWS_CCP/handson-kubernetes/12_local_kubernetes_basics.md`
- `/Users/k24032kk/AWS_CCP/handson-kubernetes/13_configmap_basics.md`
- `/Users/k24032kk/AWS_CCP/handson-kubernetes/14_kubernetes_network.md`

---

### Week 2: Kubernetes中級 + AWS復習

**目標**: Kubernetes深堀り + AWS基礎固め

- [ ] Day 1-2: リソース管理 / Probe
- [ ] Day 3-4: PersistentVolume / StatefulSet
- [ ] Day 5: VPC復習
- [ ] Day 6-7: IAM深堀り（ロール/信頼関係）

---

### Week 3-4: EKS標準モード

**目標**: EKSの仕組みを完全理解

- [ ] Day 1-2: VPC準備 + IAMロール作成
- [ ] Day 3-4: クラスタ作成 + ノードグループ
- [ ] Day 5-6: AWS Load Balancer Controller
- [ ] Day 7-8: サンプルアプリデプロイ
- [ ] Day 9-10: トラブルシューティング練習
- [ ] Day 11-14: 実践プロジェクト

---

### Week 5: EKS Auto Mode（オプション）

**目標**: Auto Modeの特徴を理解

- [ ] Day 1-2: Karpenter / Bottlerocket理解
- [ ] Day 3-4: Auto Mode作成
- [ ] Day 5-7: 標準モードとの比較

---

## よくある質問

### Q1: 本当にローカルから始めるべき？

**A**: はい。理由:
- 無料
- 何度でも試せる
- Kubernetesの本質に集中できる
- EKS特有の問題に惑わされない

### Q2: EKS Auto Modeは初心者向けでは？

**A**: いいえ。Auto Modeは:
- 自動化されすぎて何が起きているか分からない
- トラブル時に対処できない
- 標準モードを理解してから使うべき

### Q3: 全部やるのに何日かかる？

**A**: 目安:
- ローカルKubernetes: 1週間
- Kubernetes中級 + AWS復習: 1週間
- EKS標準モード: 2週間
- **合計**: 約1ヶ月（毎日2-3時間）

### Q4: お金はどれくらいかかる？

**A**:
- ローカル（minikube）: $0
- EKS標準モード: 約$200/月（実際には数時間で削除すれば$10以下）
- EKS Auto Mode: 約$220/月（+12%）

**節約方法**: 学習時のみ起動、終わったらすぐ削除

---

## 次のアクション

### 今すぐやるべきこと

1. **EKS Auto Modeのリソースを削除**（課金停止）
   - ファイル: `/Users/k24032kk/AWS_CCP/handson/cleanup_eks_auto_mode.md`

2. **minikubeでKubernetes基礎を学ぶ**
   - ファイル: `/Users/k24032kk/AWS_CCP/handson-kubernetes/12_local_kubernetes_basics.md`

3. **焦らない**
   - EKSは最終目標
   - 基礎から着実に

---

**作成日**: 2026-05-13
**目的**: EKSを段階的に理解するための完全ロードマップ
**重要**: 必ずローカルKubernetesから始めること
