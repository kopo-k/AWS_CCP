# Phase 3 検証環境構築に向けた学習計画サマリー

**ファイルパス**: `/Users/k24032kk/AWS_CCP/handson/phase3_learning_summary.md`

**関連ファイル**:
- 詳細チェックリスト: `/Users/k24032kk/AWS_CCP/handson/phase3_prerequisites_checklist.md`
- EKS学習ロードマップ: `/Users/k24032kk/AWS_CCP/handson/00_eks_learning_roadmap.md`

---

## 作成したファイル

`/Users/k24032kk/AWS_CCP/handson/phase3_prerequisites_checklist.md`

Phase 3の検証環境構築に必要な学習項目を体系的にまとめた、実行可能なチェックリスト。

---

## 学習の全体像

```
現在地: Level 0-1 (Kubernetes基礎途中)
    ↓
Level 1: Kubernetesローカル基礎 (1週間) ★必須
    ↓
Level 2: Kubernetes中級 (1週間) ★必須
    ↓
Level 3: AWS基礎復習 (2-3日) ★必須
    ↓
Level 4: EKS標準モード (1-2週間) ★必須
    ↓
Phase 3 実行可能 ✅
```

**合計学習期間**: 3-4週間

---

## 主な内容

### Level 1（Kubernetes基礎）- 1週間

**環境**: minikube（無料、安全）

- **Pod の基礎**
  - Podとは何か、YAMLの書き方、ライフサイクル
  - 所要時間: 2時間

- **Deployment の基礎**
  - Deploymentとは何か、YAMLの書き方、操作方法
  - 所要時間: 3時間

- **Service の基礎**
  - Serviceとは何か、種類（ClusterIP/NodePort/LoadBalancer）
  - ServiceとPodの接続
  - 所要時間: 3.5時間

- **ConfigMap と Secret**
  - 設定の外部化、機密情報の管理
  - 所要時間: 2時間

**検証ワークロードとの関連**:
- nginx Pod、Deployment、Serviceの理解
- PostgreSQL接続情報の管理

**参考ファイル**:
- `/Users/k24032kk/AWS_CCP/handson-kubernetes/12_local_kubernetes_basics.md`
- `/Users/k24032kk/AWS_CCP/handson-kubernetes/13_configmap_basics.md`
- `/Users/k24032kk/AWS_CCP/handson-kubernetes/14_kubernetes_network.md`

---

### Level 2（Kubernetes中級）- 1週間

**環境**: minikube

- **StatefulSet の基礎**
  - ステートフルアプリケーション用
  - Pod名が固定、順序付き起動・削除
  - 所要時間: 3.5時間

- **PV・PVC (永続ストレージ)**
  - PersistentVolume、PersistentVolumeClaim
  - StorageClassの理解
  - 所要時間: 3.5時間

- **Ingress の基礎**
  - HTTP/HTTPSルーティング
  - Ingress Controller
  - 所要時間: 3.5時間

- **HPA (Horizontal Pod Autoscaler)**
  - CPU/メモリに応じた自動スケール
  - 所要時間: 2.5時間

**検証ワークロードとの関連**:
- **StatefulSet** - PostgreSQL用
- **PVC** - PostgreSQLのデータ永続化
- **Ingress** - nginx へのALB Ingress
- **HPA** - 負荷テスト時のスケール検証

---

### Level 3（AWS基礎復習）- 2-3日

**環境**: AWS Console / Terraform

- **VPCの復習**
  - VPC設計（Public/Private Subnet、NAT Gateway）
  - EKS用VPCの要件（タグ設定）
  - 所要時間: 2時間

- **IAMの復習**
  - IAM Roleの基礎（Trust Relationship、Policy Attachment）
  - EKS用IAM Role（Cluster Role、Node Role）
  - IRSA (IAM Roles for Service Accounts)の概念
  - 所要時間: 3時間

**検証ワークロードとの関連**:
- Phase 3のVPC準備
- EKS Cluster Role, Node Role
- ALB Controller, EBS CSI Driverで使用

**参考ファイル**:
- `/Users/k24032kk/AWS_CCP/handson-terraform/11_vpc_multisubnet.md`

---

### Level 4（EKS標準モード）- 1-2週間

**環境**: AWS EKS（課金に注意）

- **EKSの基礎**
  - EKSとは何か、アーキテクチャ
  - 所要時間: 1.5時間

- **eksctl の使い方**
  - インストール、基本コマンド、設定ファイル
  - 所要時間: 3.5時間

- **EKS Node Groups**
  - マネージドノードグループの作成・管理
  - 所要時間: 2.5時間

- **Karpenter の導入**
  - より高度なオートスケーリング
  - Helmでインストール、IRSA設定、動作確認
  - 所要時間: 4-5時間

- **EBS CSI Driver の導入**
  - EBS ボリュームをPVとして使用
  - EKS Addonとして追加、IRSA設定、StorageClass作成
  - 所要時間: 3.5時間

- **AWS Load Balancer Controller の導入**
  - Ingressから自動的にALB作成
  - Helmでインストール、IRSA設定、ALB Ingress作成
  - 所要時間: 4.5時間

- **Helm の基礎**
  - Kubernetesのパッケージマネージャー
  - 基本コマンド
  - 所要時間: 1.5時間

**検証ワークロードとの関連**:
- **Karpenter** - 自動スケーリング（Phase 3で標準EKSに導入）
- **EBS CSI Driver** - PostgreSQL用
- **ALB Controller** - nginx用
- **Helm** - パッケージ管理

**Level 4のコスト目安**:
- クラスタ稼働: 10時間 = $1
- EC2 (t3.small): 10時間 = $0.25
- NAT Gateway: 10時間 = $0.90
- **合計**: 約$2-3

---

### Phase 3 直前の準備 - 2-3日

**環境**: minikube（予行演習）

- **nginx + PostgreSQL構成をminikubeで構築**
  - nginx Deployment + Service
  - PostgreSQL StatefulSet + PVC + Service
  - Ingress (minikube addon)
  - nginx → PostgreSQL 接続確認
  - 所要時間: 3-4時間

- **Phase 3用のYAMLファイル準備**
  - nginx-deployment.yaml
  - nginx-service.yaml
  - postgres-statefulset.yaml
  - postgres-pvc.yaml
  - postgres-service.yaml
  - ingress.yaml
  - 所要時間: 2時間

- **eksctl設定ファイル準備**
  - 標準EKS用の設定ファイル
  - Auto Mode用の設定ファイル
  - VPC設定の確認
  - 所要時間: 1時間

- **コスト見積もり確認**
  - 標準EKS: 約$50-60 (48時間)
  - Auto Mode: 約$50-60 (48時間)
  - 合計: $100-120
  - 所要時間: 30分

---

## チェックリストの特徴

✅ **チェックボックス形式** - 進捗が見える形式で管理可能

✅ **重要度付き**
- ★★★ 必須 - これがないとPhase 3が実行不可能
- ★★ 推奨 - 理解が浅いと躓く可能性が高い
- ★ オプション - あると便利だが、なくても進められる

✅ **所要時間明記** - 現実的な学習計画が立てられる

✅ **検証ワークロードとの関連** - Phase 3でどう使うか明示

✅ **参考ファイル** - 既存の学習資料にリンク

✅ **FAQ** - よくある疑問に先回り回答
- Q1: 本当に3-4週間かかる？もっと短縮できない？
- Q2: Level 1-2をスキップしてEKSから始められない？
- Q3: Helmを使わずにYAMLで全部やりたい
- Q4: minikubeの代わりにDocker Desktopは？
- Q5: AWSの課金が心配

---

## 重要なメッセージ

### ⚠️ Level 1-2はスキップ不可

**理由**:
- EKS Auto Mode失敗時と同じ状況になる
- Podが起動しない理由がわからない
- YAMLの書き方がわからない
- トラブルシューティングができない

**絶対に不可能**です。

### 📅 記事執筆のタイミング

**現在地**: Level 1（ローカルKubernetes基礎）

**記事に必要**: Level 4-5（EKS標準 + Auto Mode）

**ギャップ**: 約3-4週間の学習

**選択肢**:
1. **今すぐ進める** (非推奨)
   - Phase 3で躓いたときに原因が特定できない
   - 記事の「学習コスト」軸が体感に基づかない浅い内容になる
   - 検証環境でトラブルが起きたとき対処できない

2. **1ヶ月後に延期** (推奨)
   - Level 1-4を完了してからPhase 3実行
   - 確実な検証ができる
   - 記事の品質が上がる

### 💰 コストについて

**Level 4の実習コスト**: 約$2-3（10時間程度）

**Phase 3のコスト**: 約$100-120（48時間 × 2クラスタ）

**コスト最適化**:
- 実習後は必ず `eksctl delete cluster`
- t3.small (ノード) で十分
- 夜間・週末は削除しておく

### 📚 学習のヒント

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

## 推奨学習順序

### Week 1: Level 1（Kubernetesローカル基礎）
- 毎日2-3時間
- minikubeで実践
- Pod → Deployment → Service → ConfigMap/Secret

### Week 2: Level 2（Kubernetes中級）
- 毎日2-3時間
- StatefulSet + PVC + Ingress + HPA
- minikubeで実践

### Week 3: Level 3 + Level 4前半
- AWS基礎復習（VPC・IAM）
- eksctl基礎
- 最小構成EKSクラスタ作成・削除

### Week 4: Level 4後半
- Karpenter導入
- EBS CSI Driver導入
- ALB Controller導入
- 完全な検証ワークロード構築

### Week 5: Phase 3実行 ✅

---

## Level完了の目安

### Level 1完了の目安
- minikubeでnginx Deploymentを3レプリカで作成できる
- ServiceでPod間通信ができる
- ConfigMapを使って環境変数を設定できる

### Level 2完了の目安
- minikubeでPostgreSQL StatefulSetを作成できる
- PVCを使ってデータを永続化できる
- Ingressを使ってHTTPアクセスできる

### Level 3完了の目安
- EKS用VPCの要件を説明できる
- IAM RoleとIRSAの違いを理解している

### Level 4完了の目安
- eksctlでEKSクラスタを作成・削除できる
- Karpenter, EBS CSI, ALB Controllerを導入できる
- nginx + PostgreSQLをEKSで動かせる

---

## 次のステップ

1. **チェックリストを開く**
   ```bash
   open /Users/k24032kk/AWS_CCP/handson/phase3_prerequisites_checklist.md
   ```

2. **1つずつチェックを入れていく**
   - Level 1から順番に
   - 必ず実習を伴う
   - わからないことはメモ

3. **4週間後にPhase 3実行** ✅

このチェックリストを1つずつ進めていけば、Phase 3を確実に実行できる状態になります。

---

**作成日**: 2026-05-13
**目的**: Phase 3検証環境構築に向けた学習計画の概要
**対象者**: EKS標準 vs Auto Mode 比較記事を書く人
