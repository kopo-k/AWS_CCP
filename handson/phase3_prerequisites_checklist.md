# Phase 3 検証環境構築のための学習チェックリスト

**ファイルパス**: `/Users/k24032kk/AWS_CCP/handson/phase3_prerequisites_checklist.md`

## 目的

「EKS標準 vs Auto Mode」比較記事のPhase 3（検証環境構築）を実行するために必要な学習項目を体系的にまとめたチェックリスト。

## 検証ワークロード要件（復習）

Phase 3で構築する環境：
- **Web層**: nginx (Deployment + Service + ALB Ingress)
- **DB層**: PostgreSQL (StatefulSet + PVC + EBS CSI)
- **Auto Scaling**: HPA (Horizontal Pod Autoscaler)
- **インフラ**: VPC + EKS標準 + EKS Auto Mode

## 学習の全体像

```
現在地: Level 0-1 (基礎準備〜ローカルKubernetes途中)
    ↓
[Level 1] Kubernetesローカル基礎 (必須) ← 1週間
    ↓
[Level 2] Kubernetes中級 (必須) ← 1週間
    ↓
[Level 3] AWS基礎復習 (必須) ← 2-3日
    ↓
[Level 4] EKS標準モード (必須) ← 1-2週間
    ↓
Phase 3 実行可能 ✅
```

**合計学習期間**: 3-4週間

---

## Level 1：Kubernetesローカル基礎（minikube）⭐必須

**期間**: 1週間
**環境**: minikube (無料、安全)
**目的**: Phase 3のワークロードをローカルで理解する

### 1.1 Pod の基礎

- [ ] **Podとは何か** ★★★
  - コンテナの最小単位
  - 1つ以上のコンテナをまとめる
  - 固有のIPアドレスを持つ
  - **検証ワークロードとの関連**: nginx Pod、PostgreSQL Podの理解
  - **参考**: `/Users/k24032kk/AWS_CCP/handson-kubernetes/12_local_kubernetes_basics.md`
  - **所要時間**: 30分

- [ ] **Pod YAMLの書き方** ★★★
  - `apiVersion`, `kind`, `metadata`, `spec`
  - `containers`, `image`, `ports`
  - リソース制限 (`requests`, `limits`)
  - **検証ワークロードとの関連**: nginx-deployment.yaml の理解
  - **実習**: nginxのPodを作成・削除
  - **所要時間**: 1時間

- [ ] **Podのライフサイクル** ★★
  - Pending → Running → Succeeded/Failed
  - `kubectl get pods`, `kubectl describe pod`
  - **検証ワークロードとの関連**: トラブルシューティングの基礎
  - **所要時間**: 30分

### 1.2 Deployment の基礎

- [ ] **Deploymentとは何か** ★★★
  - 複数のPodを管理
  - レプリカ数の指定
  - ローリングアップデート
  - セルフヒーリング（自動再起動）
  - **検証ワークロードとの関連**: nginx Deploymentの中核
  - **参考**: `/Users/k24032kk/AWS_CCP/handson-kubernetes/12_local_kubernetes_basics.md`
  - **所要時間**: 1時間

- [ ] **Deployment YAMLの書き方** ★★★
  - `replicas`, `selector`, `template`
  - ラベルとセレクタの関係
  - **検証ワークロードとの関連**: nginx-deployment.yaml
  - **実習**: nginx Deploymentを3レプリカで作成
  - **所要時間**: 1時間

- [ ] **Deploymentの操作** ★★★
  - スケール: `kubectl scale deployment`
  - 更新: `kubectl set image`
  - ロールバック: `kubectl rollout undo`
  - **検証ワークロードとの関連**: Phase 3の動作確認
  - **実習**: レプリカ数を変更、イメージを更新
  - **所要時間**: 1時間

### 1.3 Service の基礎

- [ ] **Serviceとは何か** ★★★
  - Podへの固定アクセスポイント
  - DNS名の提供
  - 負荷分散
  - **検証ワークロードとの関連**: nginx ServiceがALBのバックエンド
  - **参考**: `/Users/k24032kk/AWS_CCP/handson-kubernetes/14_kubernetes_network.md`
  - **所要時間**: 1時間

- [ ] **Service の種類** ★★★
  - **ClusterIP**: クラスタ内部のみ（PostgreSQL用）
  - **NodePort**: ノードのポートで公開
  - **LoadBalancer**: 外部LB使用（nginx用）
  - **検証ワークロードとの関連**: nginx=LoadBalancer、PostgreSQL=ClusterIP
  - **実習**: ClusterIPとNodePortを試す
  - **所要時間**: 1.5時間

- [ ] **ServiceとPodの接続** ★★★
  - ラベルセレクタの仕組み
  - Endpointsの確認
  - DNS名の解決 (`<service>.<namespace>.svc.cluster.local`)
  - **検証ワークロードとの関連**: nginx→PostgreSQL間の通信
  - **実習**: 2つのPod間でService経由通信
  - **所要時間**: 1時間

### 1.4 ConfigMap と Secret

- [ ] **ConfigMapの基礎** ★★★
  - 設定の外部化
  - 環境変数、ファイルマウント
  - **検証ワークロードとの関連**: PostgreSQL接続情報
  - **参考**: `/Users/k24032kk/AWS_CCP/handson-kubernetes/13_configmap_basics.md`
  - **実習**: ConfigMapを作成してPodにマウント
  - **所要時間**: 1時間

- [ ] **Secretの基礎** ★★★
  - 機密情報の管理
  - Base64エンコード
  - **検証ワークロードとの関連**: PostgreSQLのパスワード
  - **実習**: Secretを作成してPodで使用
  - **所要時間**: 1時間

---

## Level 2：Kubernetes中級

**期間**: 1週間
**環境**: minikube
**目的**: PostgreSQL（StatefulSet + PVC）とIngress を理解する

### 2.1 StatefulSet の基礎

- [ ] **StatefulSetとは何か** ★★★
  - ステートフルアプリケーション用
  - Pod名が固定（`postgres-0`, `postgres-1`...）
  - 順序付き起動・削除
  - Deploymentとの違い
  - **検証ワークロードとの関連**: PostgreSQL StatefulSetの中核
  - **所要時間**: 1時間

- [ ] **StatefulSet YAMLの書き方** ★★★
  - `serviceName`, `volumeClaimTemplates`
  - Headless Service との連携
  - **検証ワークロードとの関連**: PostgreSQL StatefulSet
  - **実習**: 簡単なStatefulSetを作成
  - **所要時間**: 1.5時間

- [ ] **StatefulSetの操作** ★★
  - スケール時の挙動
  - Podの削除・再作成
  - **検証ワークロードとの関連**: トラブルシューティング
  - **所要時間**: 1時間

### 2.2 PersistentVolume (PV) と PersistentVolumeClaim (PVC)

- [ ] **PV・PVCとは何か** ★★★
  - 永続ストレージの抽象化
  - PV: ストレージリソース
  - PVC: ストレージ要求
  - **検証ワークロードとの関連**: PostgreSQLのデータ永続化
  - **所要時間**: 1時間

- [ ] **PVC YAMLの書き方** ★★★
  - `storageClassName`, `accessModes`, `resources.requests.storage`
  - **検証ワークロードとの関連**: PostgreSQL用PVC
  - **実習**: PVCを作成してPodにマウント
  - **所要時間**: 1.5時間

- [ ] **StorageClassの理解** ★★
  - 動的プロビジョニング
  - クラウドプロバイダごとの違い（EBS CSI）
  - **検証ワークロードとの関連**: EKSでのEBS CSI Driver
  - **所要時間**: 1時間

### 2.3 Ingress の基礎

- [ ] **Ingressとは何か** ★★★
  - HTTP/HTTPSルーティング
  - 複数Serviceを1つのIPで公開
  - ServiceのLoadBalancerとの違い
  - **検証ワークロードとの関連**: nginx へのALB Ingress
  - **所要時間**: 1時間

- [ ] **Ingress YAMLの書き方** ★★
  - `rules`, `host`, `path`, `backend`
  - **検証ワークロードとの関連**: ALB Ingress Controller
  - **実習**: minikubeでIngress Addonを有効化して試す
  - **所要時間**: 1.5時間

- [ ] **Ingress Controllerの理解** ★★
  - Nginx Ingress Controller (minikube)
  - AWS Load Balancer Controller (EKS)
  - **検証ワークロードとの関連**: ALB Controller導入
  - **所要時間**: 1時間

### 2.4 HPA (Horizontal Pod Autoscaler)

- [ ] **HPAとは何か** ★★
  - CPU/メモリ使用率に応じた自動スケール
  - Metrics Serverの必要性
  - **検証ワークロードとの関連**: 負荷テスト時のスケール検証
  - **所要時間**: 1時間

- [ ] **HPA YAMLの書き方** ★★
  - `minReplicas`, `maxReplicas`, `targetCPUUtilizationPercentage`
  - **実習**: nginxに負荷をかけてスケールさせる
  - **所要時間**: 1.5時間

---

## Level 3：AWS基礎復習（VPC・IAM）

**期間**: 2-3日
**環境**: AWS Console / Terraform
**目的**: Phase 3のVPC準備とIAM理解

### 3.1 VPCの復習

- [ ] **VPC設計の復習** ★★★
  - Public/Private Subnet
  - NAT Gateway、Internet Gateway
  - ルートテーブル
  - **検証ワークロードとの関連**: Phase 3のVPC作成
  - **参考**: `/Users/k24032kk/AWS_CCP/handson-terraform/11_vpc_multisubnet.md`
  - **所要時間**: 1時間

- [ ] **EKS用VPCの要件** ★★★
  - 最低2つのAZ
  - PublicとPrivate Subnetのタグ
    - `kubernetes.io/role/elb=1` (Public)
    - `kubernetes.io/role/internal-elb=1` (Private)
  - **検証ワークロードとの関連**: Phase 3 VPC準備
  - **所要時間**: 1時間

### 3.2 IAMの復習

- [ ] **IAM Roleの基礎** ★★★
  - Trust Relationship (信頼関係)
  - Policy Attachment
  - **検証ワークロードとの関連**: EKS Cluster Role, Node Role
  - **所要時間**: 1時間

- [ ] **EKS用IAM Roleの理解** ★★★
  - Cluster Role: `AmazonEKSClusterPolicy`
  - Node Role: `AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`, `AmazonEC2ContainerRegistryReadOnly`
  - **検証ワークロードとの関連**: Phase 3でeksctlが自動作成
  - **所要時間**: 1時間

- [ ] **IRSA (IAM Roles for Service Accounts)の概念** ★★
  - Pod単位でIAM権限を付与
  - ServiceAccountとIAM Roleの紐付け
  - **検証ワークロードとの関連**: ALB Controller, EBS CSI Driverで使用
  - **所要時間**: 1時間

---

## Level 4：EKS標準モード

**期間**: 1-2週間
**環境**: AWS EKS
**目的**: Phase 3の標準EKS構築を実行できるようになる

### 4.1 EKSの基礎

- [ ] **EKSとは何か** ★★★
  - マネージドKubernetesサービス
  - Control Planeの管理不要
  - セルフマネージドK8sとの違い
  - **検証ワークロードとの関連**: Phase 3の土台
  - **所要時間**: 30分

- [ ] **EKSのアーキテクチャ** ★★★
  - Control Plane (AWS管理)
  - Data Plane (ユーザー管理)
  - VPCとの統合
  - **所要時間**: 1時間

### 4.2 eksctl の使い方

- [ ] **eksctlのインストール** ★★★
  - Homebrew経由
  - バージョン確認
  - **所要時間**: 15分

- [ ] **eksctl基本コマンド** ★★★
  - `eksctl create cluster` - クラスタ作成
  - `eksctl create nodegroup` - ノードグループ追加
  - `eksctl delete cluster` - クラスタ削除
  - **検証ワークロードとの関連**: Phase 3の標準EKS構築
  - **実習**: 最小構成でクラスタ作成→削除
  - **所要時間**: 2時間

- [ ] **eksctl設定ファイル** ★★★
  - YAML形式でクラスタ定義
  - `metadata`, `vpc`, `managedNodeGroups`
  - **検証ワークロードとの関連**: Phase 3で再利用可能な設定
  - **実習**: 設定ファイルからクラスタ作成
  - **所要時間**: 1.5時間

### 4.3 EKS Node Groups

- [ ] **マネージドノードグループとは** ★★★
  - Auto Scaling Groupのラッパー
  - EC2インスタンスタイプの選択
  - スケーリング設定
  - **検証ワークロードとの関連**: Phase 3の標準EKSで使用
  - **所要時間**: 1時間

- [ ] **ノードグループの作成・管理** ★★★
  - インスタンスタイプ選択 (t3.medium推奨)
  - 最小/最大ノード数
  - **実習**: ノードグループを追加・削除
  - **所要時間**: 1.5時間

### 4.4 Karpenter の導入

- [ ] **Karpenterとは何か** ★★★
  - より高度なオートスケーリング
  - Cluster Autoscalerの代替
  - ノードを数秒で起動
  - **検証ワークロードとの関連**: Phase 3で標準EKSに導入
  - **所要時間**: 1時間

- [ ] **Karpenterのインストール** ★★★
  - Helmでインストール
  - IRSA (IAM Role for Service Account) の設定
  - Provisioner/NodePool の作成
  - **検証ワークロードとの関連**: Phase 3の構築手順
  - **参考**: 公式ドキュメント参照
  - **所要時間**: 2-3時間

- [ ] **Karpenterの動作確認** ★★
  - Podをスケールアウトして新ノード起動を確認
  - ノードの自動削除を確認
  - **所要時間**: 1時間

### 4.5 EBS CSI Driver の導入

- [ ] **EBS CSI Driverとは何か** ★★★
  - EBS ボリュームを PV として使用
  - 動的プロビジョニング
  - **検証ワークロードとの関連**: PostgreSQLのPVC用
  - **所要時間**: 1時間

- [ ] **EBS CSI Driverのインストール** ★★★
  - EKS Addonとして追加
  - IRSA設定（IAM Role作成）
  - **検証ワークロードとの関連**: Phase 3で必須
  - **実習**: EBS CSI Driverをインストール
  - **所要時間**: 1.5時間

- [ ] **StorageClassの作成** ★★★
  - `gp3` ボリュームタイプ
  - `volumeBindingMode: WaitForFirstConsumer`
  - **検証ワークロードとの関連**: PostgreSQL用StorageClass
  - **実習**: StorageClassを作成してPVCをテスト
  - **所要時間**: 1時間

### 4.6 AWS Load Balancer Controller の導入

- [ ] **ALB Controllerとは何か** ★★★
  - Ingressから自動的にALB作成
  - Service type=LoadBalancerでNLB作成
  - **検証ワークロードとの関連**: nginx用ALB Ingress
  - **所要時間**: 1時間

- [ ] **ALB Controllerのインストール** ★★★
  - Helmでインストール
  - IRSA設定（IAM Policy作成）
  - **検証ワークロードとの関連**: Phase 3で必須
  - **実習**: ALB Controllerをインストール
  - **所要時間**: 2時間

- [ ] **ALB Ingressの作成** ★★★
  - Ingress YAMLでALBを作成
  - アノテーションの理解 (`alb.ingress.kubernetes.io/*`)
  - **検証ワークロードとの関連**: nginx Ingress
  - **実習**: サンプルアプリをALBで公開
  - **所要時間**: 1.5時間

### 4.7 Helmの基礎

- [ ] **Helmとは何か** ★★★
  - Kubernetesのパッケージマネージャー
  - Chart = アプリケーションの定義
  - **検証ワークロードとの関連**: Karpenter, ALB Controller導入で使用
  - **所要時間**: 30分

- [ ] **Helm基本コマンド** ★★★
  - `helm repo add` - リポジトリ追加
  - `helm install` - Chartインストール
  - `helm list` - インストール済みChart一覧
  - `helm uninstall` - アンインストール
  - **実習**: サンプルChartをインストール
  - **所要時間**: 1時間

---

## Phase 3 直前の準備

**期間**: 2-3日
**目的**: 検証ワークロードを構築できるようになる

### 完全な検証ワークロードのローカル実践

- [ ] **nginx + PostgreSQL構成をminikubeで構築** ★★★
  - nginx Deployment + Service
  - PostgreSQL StatefulSet + PVC + Service
  - Ingress (minikube addon)
  - nginx → PostgreSQL 接続確認
  - **目的**: Phase 3の予行演習
  - **所要時間**: 3-4時間

- [ ] **Phase 3用のYAMLファイル準備** ★★★
  - nginx-deployment.yaml
  - nginx-service.yaml
  - postgres-statefulset.yaml
  - postgres-pvc.yaml
  - postgres-service.yaml
  - ingress.yaml
  - **所要時間**: 2時間

- [ ] **eksctl設定ファイル準備** ★★★
  - 標準EKS用の設定ファイル
  - Auto Mode用の設定ファイル
  - VPC設定の確認
  - **所要時間**: 1時間

- [ ] **コスト見積もり確認** ★★
  - 標準EKS: 約$50-60 (48時間)
  - Auto Mode: 約$50-60 (48時間)
  - 合計: $100-120
  - **所要時間**: 30分

---

## 学習チェックリストの使い方

### 推奨学習順序

**Week 1: Level 1（Kubernetesローカル基礎）**
- 毎日2-3時間
- minikubeで実践
- Pod → Deployment → Service → ConfigMap/Secret

**Week 2: Level 2（Kubernetes中級）**
- 毎日2-3時間
- StatefulSet + PVC + Ingress + HPA
- minikubeで実践

**Week 3: Level 3 + Level 4前半**
- AWS基礎復習（VPC・IAM）
- eksctl基礎
- 最小構成EKSクラスタ作成・削除

**Week 4: Level 4後半**
- Karpenter導入
- EBS CSI Driver導入
- ALB Controller導入
- 完全な検証ワークロード構築

**Week 5: Phase 3実行** ✅

### 学習のヒント

1. **必ず手を動かす**
   - 読むだけでは理解できない
   - 失敗から学ぶ

2. **minikubeは失敗しても無料**
   - 気軽に試す
   - 何度でもやり直せる

3. **EKSは課金に注意**
   - Level 4の実習は短時間で
   - 使わないときは必ず削除

4. **わからないことはメモ**
   - 後で質問する
   - 記事のQ&Aセクションのネタになる

5. **公式ドキュメントを読む習慣**
   - Kubernetes公式: https://kubernetes.io/docs/
   - EKS公式: https://docs.aws.amazon.com/eks/

---

## 重要度の凡例

- **★★★ 必須**: これがないとPhase 3が実行不可能
- **★★ 推奨**: 理解が浅いと躓く可能性が高い
- **★ オプション**: あると便利だが、なくても進められる

---

## よくある質問

### Q1: 本当に3-4週間かかる？もっと短縮できない？

**A**: 短縮は可能ですが**非推奨**です。理由：

- Phase 3で躓いたときに原因が特定できない
- 記事の「学習コスト」軸が体感に基づかない浅い内容になる
- 検証環境でトラブルが起きたとき対処できない

**最低限の短縮案** (2週間):
- Level 1: 4日（Pod, Deployment, Serviceのみ）
- Level 2: 3日（StatefulSet, PVC, Ingressのみ、HPAスキップ）
- Level 3: 1日（復習のみ）
- Level 4: 6日（eksctl, Karpenter, EBS CSI, ALB Controllerのみ）

### Q2: Level 1-2をスキップしてEKSから始められない？

**A**: **絶対に不可能**です。理由：

- EKS Auto Mode失敗時と同じ状況になる
- Podが起動しない理由がわからない
- YAMLの書き方がわからない
- トラブルシューティングができない

### Q3: Helmを使わずにYAMLで全部やりたい

**A**: 可能ですが**非推奨**です。理由：

- Karpenter, ALB ControllerのYAMLは複雑（数百行）
- 公式ドキュメントもHelm前提
- Phase 3で時間を浪費する

Helmは「Kubernetesのapt/yum」と考えてください。

### Q4: minikubeの代わりにDocker Desktopは？

**A**: 可能です。Docker Desktop for MacにはKubernetes機能があります。

ただしminikubeの利点：
- Ingress addonが簡単
- より本番に近い
- トラブルシューティング情報が豊富

### Q5: AWSの課金が心配

**A**: Level 4の実習は短時間で終わらせましょう。

**コスト最適化**:
- 実習後は必ず `eksctl delete cluster`
- t3.small (ノード) で十分
- 夜間・週末は削除しておく

**Level 4のコスト目安**:
- クラスタ稼働: 10時間 = $1
- EC2 (t3.small): 10時間 = $0.25
- NAT Gateway: 10時間 = $0.90
- **合計**: 約$2-3

---

## 次のステップ

このチェックリストを印刷またはコピーして、1つずつチェックを入れていってください。

**Level 1完了の目安**:
- minikubeでnginx Deploymentを3レプリカで作成できる
- ServiceでPod間通信ができる
- ConfigMapを使って環境変数を設定できる

**Level 2完了の目安**:
- minikubeでPostgreSQL StatefulSetを作成できる
- PVCを使ってデータを永続化できる
- Ingressを使ってHTTPアクセスできる

**Level 3完了の目安**:
- EKS用VPCの要件を説明できる
- IAM RoleとIRSAの違いを理解している

**Level 4完了の目安**:
- eksctlでEKSクラスタを作成・削除できる
- Karpenter, EBS CSI, ALB Controllerを導入できる
- nginx + PostgreSQLをEKSで動かせる

↓

**Phase 3実行可能** ✅

---

**作成日**: 2026-05-13
**目的**: Phase 3検証環境構築に向けた体系的学習計画
**対象者**: EKS標準 vs Auto Mode 比較記事を書く人
