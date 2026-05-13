# ハンズオン⑩：EKS Auto Mode 入門（AWSコンソール）

## EKS Auto Mode とは

**Kubernetesクラスタのインフラを完全自動管理してくれるAWSの新機能**

### 語源

- **EKS**: Elastic Kubernetes Service
- **Auto Mode**: 自動モード（自動管理モード）

### 発表時期

**2024年12月 AWS re:Invent 2024** で発表された最新機能

---

## Part 1：EKS Auto Mode の基本理解

### 従来のEKSとの違い

#### 従来のEKS（標準モード）

```
あなたが管理する必要があるもの:
├── ノードグループ（EC2インスタンスの集まり）
│   ├── インスタンスタイプ選択（m5.large? c5.xlarge?）
│   ├── AMI選択とアップデート
│   ├── スケーリング設定（Auto Scaling Group）
│   └── セキュリティパッチ適用
├── アドオン管理
│   ├── VPC CNI（ネットワーク）
│   ├── EBS CSI（ストレージ）
│   ├── AWS Load Balancer Controller
│   └── Karpenter（オートスケーリング）
└── ノードのOS管理
    ├── セキュリティアップデート
    └── SSH管理
```

#### EKS Auto Mode

```
AWSが自動管理してくれるもの:
├── ✅ ノード管理（完全自動）
│   ├── インスタンスタイプ自動選択
│   ├── AMI自動選択・アップデート
│   ├── 自動スケーリング（Karpenter内蔵）
│   └── セキュリティパッチ自動適用
├── ✅ アドオン（組み込み済み）
│   ├── VPC CNI（ネットワーク）
│   ├── EBS CSI（ストレージ）
│   └── AWS Load Balancer Controller
└── ✅ セキュリティ強化
    ├── Bottlerocket OS（コンテナ最適化）
    ├── SELinux enforcing mode
    ├── Read-only root filesystem
    └── SSH/SSMアクセス不可（セキュリティ強化）

あなたが管理するもの:
└── アプリケーション（Podの中身）のみ
```

---

## Part 2：EKS Auto Mode の主な機能

### 1. 自動スケーリング

**Podが増えたら自動的にノードを追加、減ったら削除**

```
状態1: Pod 3個
    ↓
状態2: Pod 10個に増加（負荷増加）
    ↓
EKS Auto Mode が自動判断
    ↓
最適なEC2インスタンスを自動追加
    ↓
状態3: Pod 3個に減少
    ↓
不要なノードを自動削除（コスト最適化）
```

### 2. 自動インスタンス選択

**Podの要求リソースに応じて最適なインスタンスを自動選択**

```
例1: Pod要求 → 4 vCPU, 16GB RAM
     → Auto Mode判断 → m5.xlarge を選択

例2: Pod要求 → GPU必要
     → Auto Mode判断 → g4dn.xlarge を選択

例3: Pod要求 → ARM CPU OK
     → Auto Mode判断 → t4g.medium を選択（コスト削減）
```

### 3. 自動アップグレード

**最大21日でノードを自動交換（セキュリティ強化）**

```
Day 0: ノード作成
    ↓
Day 1-20: 通常稼働
    ↓
Day 21: 自動交換
    ├── 新しいノード作成
    ├── Podを新ノードに移行
    └── 古いノード削除
```

### 4. セキュリティ強化

**Bottlerocket OS** を使用（AWSが開発したコンテナ専用OS）

- **SELinux enforcing mode**: 強制アクセス制御
- **Read-only root filesystem**: ルートファイルシステムが読み取り専用
- **最小限のパッケージ**: 攻撃面を最小化
- **SSH/SSM不可**: 直接ログイン不可（セキュリティ向上）

---

## Part 3：料金体系

### 料金の内訳

| 項目 | 料金 | 説明 |
|------|------|------|
| **①クラスタ料金** | $0.10/時間 = $72/月 | 標準EKSと同じ |
| **②EC2インスタンス料金** | 標準料金 | 使ったインスタンス分 |
| **③Auto Mode管理料** | EC2料金の約12%追加 | Auto Mode特有の追加料金 |

### 具体例

**ケース**: m5.large × 3台を1ヶ月稼働（us-east-1）

```
①クラスタ料金: $72/月

②EC2インスタンス料金:
  m5.large = $0.096/時間
  $0.096 × 24時間 × 30日 × 3台 = $207.36

③Auto Mode管理料:
  m5.large Auto Mode料金 = $0.01152/時間（約12%）
  $0.01152 × 24時間 × 30日 × 3台 = $24.88

合計: $72 + $207.36 + $24.88 = $304.24/月
```

### 標準EKSとの比較

| 項目 | 標準EKS | Auto Mode |
|------|---------|-----------|
| クラスタ料金 | $72/月 | $72/月 |
| EC2料金 | $207.36 | $207.36 |
| 管理料 | $0 | **$24.88**（+12%） |
| **合計** | **$279.36** | **$304.24** |
| **手動管理工数** | **多い** | **ゼロ** |

**結論**: 約12%のコスト増で、運用工数がゼロになる

---

## Part 4：コンソールでEKS Auto Modeクラスタを作成

### 前提条件

✅ AWSアカウント
✅ 管理者権限（EC2、VPC、EKS、IAMを操作可能）
✅ 既存VPCまたは新規作成

---

### Step 1：EKSコンソールにアクセス

1. AWSマネジメントコンソールにログイン
2. サービス検索で「**EKS**」と入力
3. **Elastic Kubernetes Service** を選択

---

### Step 2：クラスタ作成を開始

1. 左メニュー「**クラスター**」を選択
2. 右上の「**クラスターを作成**」ボタンをクリック

---

### Step 3：Quick configuration を選択

**重要**: 2つのオプションがあります

- ✅ **Quick configuration**（推奨）← これを選択
  - EKS Auto Modeで推奨設定を自動適用
  - 初心者に最適

- ❌ **Custom configuration**
  - 詳細設定が必要
  - 今回は使わない

**「Quick configuration」が選択されていることを確認**

---

### Step 4：基本設定

#### クラスタ名

```
例: my-first-auto-cluster
```

#### Kubernetesバージョン

```
推奨: 最新版（1.31以上）
注意: Auto Modeは1.29以上が必須
```

---

### Step 5：Cluster IAM Role（クラスタ用IAMロール）

**これは何？**
EKS Auto Modeがあなたのアカウント内でEC2・EBS・ELBを操作するための権限

#### 選択肢

- ✅ **Create recommended role**（推奨）← 初回はこれ
  - 自動的に推奨ロールを作成
  - ロール名: `AmazonEKSAutoClusterRole`

- 既存ロール選択（2回目以降）
  - 前に作ったロールを再利用可能

#### 手順

1. **「Create recommended role」**を選択
2. ポップアップが開く
3. **「Next」**をクリック
4. **「Create」**をクリック
5. 元の画面に戻る
6. 更新ボタン（🔄）をクリックして、ロール一覧を更新
7. `AmazonEKSAutoClusterRole` が選択されていることを確認

---

### Step 6：Node IAM Role（ノード用IAMロール）

**これは何？**
EC2ノードがクラスタに接続したり、ECRからコンテナイメージを取得するための権限

#### 手順

1. **「Create recommended role」**を選択
2. ポップアップが開く
3. **「Next」**をクリック
4. **「Create」**をクリック
5. 元の画面に戻る
6. 更新ボタン（🔄）をクリック
7. `AmazonEKSAutoNodeRole` が選択されていることを確認

---

### Step 7：VPC選択

**2つの選択肢**:

#### オプションA：新規VPCを作成（推奨）

1. **「Create VPC」**リンクをクリック
2. 新しいタブでVPCコンソールが開く
3. VPC作成画面で以下を設定:
   - **VPCの設定**: 「VPCなど」を選択
   - **名前タグ**: `eks-auto-vpc`
   - **IPv4 CIDRブロック**: `10.0.0.0/16`
   - **アベイラビリティゾーン数**: `2`
   - **パブリックサブネット数**: `2`
   - **プライベートサブネット数**: `2`
   - **NATゲートウェイ**: `アベイラビリティゾーンごとに1個`（重要）
   - **VPCエンドポイント**: `なし`
4. **「VPCを作成」**をクリック
5. 作成完了後、EKSの画面に戻る
6. VPCドロップダウンの更新ボタン（🔄）をクリック
7. 作成した`eks-auto-vpc`を選択

#### オプションB：既存VPCを使用

1. ドロップダウンから既存VPCを選択
2. **要件**:
   - プライベートサブネットが最低2つ必要
   - 各プライベートサブネットにNATゲートウェイが必要
   - DNS hostnamesとDNS supportが有効

---

### Step 8：サブネット選択（オプション）

**デフォルトで自動選択される**:
- EKS Auto Modeが自動的にプライベートサブネットを選択
- ベストプラクティスに従って最適なサブネットを選択

**カスタマイズする場合**:
- 不要なサブネットを削除可能
- パブリックサブネットを追加可能（推奨しない）

**推奨**: デフォルトのままにする

---

### Step 9：設定確認（オプション）

**「View quick configuration defaults」**をクリックすると詳細が表示される

確認できる項目:
- Kubernetesバージョン
- エンドポイントアクセス（パブリック・プライベート）
- ログ設定
- アドオン設定
- タグ

注意: 一部の設定はクラスタ作成後は変更不可

---

### Step 10：クラスタ作成

1. **「クラスターを作成」**ボタンをクリック
2. クラスタ作成が開始される

**所要時間**: 約15分

**ステータスの変化**:
```
作成中（Creating） → 約15分
    ↓
アクティブ（Active） → 完了
```

---

### Step 11：クラスタ作成の確認

#### クラスタ詳細を確認

1. クラスタ名をクリック
2. 以下の情報を確認:
   - **ステータス**: Active
   - **エンドポイント**: Kubernetes APIサーバーのURL
   - **OpenID Connect プロバイダー URL**: 認証用
   - **証明書**: クラスタ認証用

#### Compute タブを確認

1. 「**Compute**」タブをクリック
2. 確認事項:
   - **Auto Mode**: Enabled
   - **Node pools**: `default`（自動作成）
   - **Node class**: `default`（自動作成）

**重要**: まだノードは0台（Podをデプロイすると自動作成される）

---

## Part 5：kubectlの設定

### kubectl とは

**Kubernetesを操作するためのCLIツール**

### Step 12：kubectlをインストール

#### macOSの場合

```bash
# Homebrewでインストール
brew install kubectl

# バージョン確認
kubectl version --client
```

#### その他のOS

公式ドキュメント参照:
https://kubernetes.io/docs/tasks/tools/

---

### Step 13：AWS CLIをインストール（未インストールの場合）

```bash
# macOSの場合
brew install awscli

# バージョン確認
aws --version
```

---

### Step 14：AWS認証設定

```bash
# AWS認証情報を設定
aws configure

# 入力する情報:
# AWS Access Key ID: あなたのアクセスキー
# AWS Secret Access Key: あなたのシークレットキー
# Default region name: ap-northeast-1
# Default output format: json
```

---

### Step 15：kubeconfigの更新

```bash
# EKSクラスタに接続するための設定
aws eks update-kubeconfig --region ap-northeast-1 --name my-first-auto-cluster

# 成功メッセージ:
# Added new context arn:aws:eks:ap-northeast-1:123456789012:cluster/my-first-auto-cluster to /Users/yourname/.kube/config
```

---

### Step 16：接続確認

```bash
# クラスタ情報を取得
kubectl cluster-info

# 結果例:
# Kubernetes control plane is running at https://XXXX.eks.ap-northeast-1.amazonaws.com

# ノード一覧を確認（まだ0台）
kubectl get nodes

# 結果:
# No resources found
```

**ノードが0台 = 正常**（Podをデプロイすると自動作成される）

---

## Part 6：サンプルアプリケーションのデプロイ

### Step 17：サンプルDeploymentを作成

`nginx-auto-mode.yaml` を作成します。

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
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
        resources:
          requests:
            cpu: 250m      # 0.25 vCPU
            memory: 256Mi  # 256MB RAM
          limits:
            cpu: 500m      # 最大0.5 vCPU
            memory: 512Mi  # 最大512MB RAM
```

---

### Step 18：Deploymentを適用

```bash
kubectl apply -f nginx-auto-mode.yaml

# 結果:
# deployment.apps/nginx-deployment created
```

---

### Step 19：Pod作成状況を確認

```bash
# Podの状態を確認（リアルタイム監視）
kubectl get pods -w

# 結果の変化:
# NAME                                READY   STATUS              RESTARTS   AGE
# nginx-deployment-xxxxx-xxxxx        0/1     Pending             0          5s
# nginx-deployment-xxxxx-xxxxx        0/1     Pending             0          10s
# nginx-deployment-xxxxx-xxxxx        0/1     ContainerCreating   0          30s
# nginx-deployment-xxxxx-xxxxx        1/1     Running             0          50s
```

**Pendingの理由**: ノードが存在しない → Auto Modeが自動作成中

---

### Step 20：ノード自動作成を確認

別のターミナルで実行:

```bash
# ノードの状態を確認（リアルタイム）
kubectl get nodes -w

# 結果の変化:
# No resources found（最初は0台）
#     ↓ 約1-2分後
# NAME                                         STATUS   ROLES    AGE   VERSION
# ip-10-0-1-123.ap-northeast-1.compute.internal   Ready    <none>   30s   v1.31.x
```

**Auto Modeが自動的に最適なEC2インスタンスを選択・起動した！**

---

### Step 21：どのインスタンスタイプが選ばれたか確認

```bash
# ノードの詳細情報を確認
kubectl describe node <ノード名>

# または
kubectl get nodes -o wide

# 結果例:
# NAME           STATUS   ROLES    AGE   VERSION   INSTANCE-TYPE
# ip-10-0-1-123  Ready    <none>   2m    v1.31.x   t3.medium
```

**Auto Modeの判断**:
- Pod要求: 250m CPU × 3 = 750m CPU, 256Mi × 3 = 768Mi RAM
- 選択インスタンス: `t3.medium`（2 vCPU, 4GB RAM）
- 理由: 最小コストで要件を満たすインスタンス

---

### Step 22：Serviceを作成して外部公開

`nginx-service.yaml` を作成します。

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"  # Network Load Balancer
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
```

```bash
kubectl apply -f nginx-service.yaml

# 結果:
# service/nginx-service created
```

---

### Step 23：LoadBalancerのURL取得

```bash
# Serviceの状態を確認
kubectl get svc nginx-service -w

# 結果の変化:
# NAME            TYPE           CLUSTER-IP      EXTERNAL-IP                                                                   PORT(S)        AGE
# nginx-service   LoadBalancer   10.100.123.45   <pending>                                                                     80:32123/TCP   10s
#     ↓ 約2-3分後
# nginx-service   LoadBalancer   10.100.123.45   a1234567890abcdef.elb.ap-northeast-1.amazonaws.com   80:32123/TCP   2m
```

**EXTERNAL-IPが表示されたら成功**

---

### Step 24：ブラウザでアクセス

```bash
# URLを取得
kubectl get svc nginx-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# ブラウザで以下にアクセス:
# http://<EXTERNAL-IP>
```

**Nginxのデフォルトページが表示されれば成功！**

```
Welcome to nginx!
If you see this page, the nginx web server is successfully installed and working.
```

---

## Part 7：Auto Modeの自動スケーリングを確認

### Step 25：レプリカを10個に増やす

```bash
# Deploymentをスケール
kubectl scale deployment nginx-deployment --replicas=10

# Pod数を確認
kubectl get pods

# 結果:
# NAME                                READY   STATUS    RESTARTS   AGE
# nginx-deployment-xxxxx-xxxxx        1/1     Running   0          5m
# nginx-deployment-xxxxx-xxxxx        1/1     Running   0          5m
# nginx-deployment-xxxxx-xxxxx        1/1     Running   0          5m
# nginx-deployment-xxxxx-xxxxx        0/1     Pending   0          5s  ← 新規Pod
# nginx-deployment-xxxxx-xxxxx        0/1     Pending   0          5s
# ...
```

---

### Step 26：ノードが自動追加されることを確認

```bash
# ノード数を確認
kubectl get nodes

# 結果（約2分後）:
# NAME           STATUS   ROLES    AGE   VERSION
# ip-10-0-1-123  Ready    <none>   10m   v1.31.x  ← 既存ノード
# ip-10-0-2-234  Ready    <none>   2m    v1.31.x  ← 自動追加！
```

**Auto Modeが自動的に2台目のノードを追加した！**

---

### Step 27：レプリカを3個に戻す

```bash
# スケールダウン
kubectl scale deployment nginx-deployment --replicas=3

# 約5-10分待つ（コンソリデーション時間）

# ノード数を確認
kubectl get nodes

# 結果:
# NAME           STATUS   ROLES    AGE   VERSION
# ip-10-0-1-123  Ready    <none>   20m   v1.31.x  ← 1台に戻る
```

**不要なノードを自動削除 = コスト最適化**

---

## Part 8：EC2コンソールでノードを確認

### Step 28：EC2インスタンスを確認

1. AWSコンソール → EC2
2. 左メニュー「**インスタンス**」
3. フィルタ: `eks:cluster-name = my-first-auto-cluster`

#### 確認ポイント

- **名前**: `eks-auto-<ランダム文字列>`
- **インスタンスタイプ**: `t3.medium`など
- **セキュリティグループ**: EKS管理
- **IAMロール**: `AmazonEKSAutoNodeRole`
- **タグ**: `eks:cluster-name`, `karpenter.sh/nodepool`

**重要**: これらのインスタンスは直接操作しない（Auto Mode管理下）

---

## Part 9：クリーンアップ

### Step 29：Serviceを削除

```bash
# LoadBalancerを削除（ELBも自動削除される）
kubectl delete service nginx-service

# 確認
kubectl get svc
```

---

### Step 30：Deploymentを削除

```bash
# Deploymentを削除
kubectl delete deployment nginx-deployment

# 確認
kubectl get deployments
kubectl get pods  # Pod数が0になる
```

**約5-10分でノードも自動削除される**

```bash
# ノード確認
kubectl get nodes
# 結果: No resources found
```

---

### Step 31：EKSクラスタを削除

#### コンソールから削除

1. EKSコンソール
2. クラスター一覧で`my-first-auto-cluster`を選択
3. 右上「**削除**」ボタン
4. クラスタ名を入力して確認
5. 「**削除**」をクリック

**所要時間**: 約10-15分

#### CLIから削除

```bash
aws eks delete-cluster --name my-first-auto-cluster --region ap-northeast-1
```

---

### Step 32：VPCの削除（新規作成した場合）

1. VPCコンソール
2. 作成した`eks-auto-vpc`を選択
3. 「**アクション**」→「**VPCを削除**」
4. 確認して削除

**注意**: NATゲートウェイ、EIPも削除される

---

## まとめ

### EKS Auto Mode のメリット

| 項目 | 標準EKS | Auto Mode |
|------|---------|-----------|
| **ノード管理** | 手動（ASG設定必要） | 完全自動 |
| **スケーリング** | 手動設定 | 自動（Karpenter内蔵） |
| **インスタンス選択** | 手動 | 自動最適化 |
| **アップグレード** | 手動 | 自動（21日サイクル） |
| **セキュリティパッチ** | 手動 | 自動 |
| **アドオン管理** | 手動インストール | 組み込み済み |
| **コスト** | 安い | +12%高い |
| **運用工数** | 多い | ほぼゼロ |

### こんな人におすすめ

✅ Kubernetes初心者
✅ インフラ運用工数を削減したい
✅ セキュリティを強化したい
✅ 自動スケーリングしたい

### 注意点

❌ カスタムAMI使用不可
❌ ノードへのSSH/SSMアクセス不可
❌ 約12%のコスト増
❌ ノード最大21日ライフタイム

---

## 次のステップ

### さらに学ぶべきトピック

1. **NodePool カスタマイズ**
   - 特定インスタンスタイプ指定
   - Spotインスタンス利用
   - GPU利用

2. **ネットワーキング高度化**
   - Ingress設定
   - Network Policy
   - Service Mesh（Istio）

3. **モニタリング**
   - CloudWatch Container Insights
   - Prometheus + Grafana
   - コスト分析

4. **CI/CD統合**
   - GitHub Actions
   - AWS CodePipeline
   - ArgoCD

---

## 参考リンク

- [AWS EKS Auto Mode 公式ドキュメント](https://docs.aws.amazon.com/eks/latest/userguide/automode.html)
- [EKS Auto Mode料金ページ](https://aws.amazon.com/eks/pricing/)
- [EKS Auto Mode コンソール手順](https://docs.aws.amazon.com/eks/latest/userguide/automode-get-started-console.html)
- [EKS Auto Mode vs 標準EKS比較](https://docs.aws.amazon.com/eks/latest/best-practices/automode.html)

---

**作成日**: 2026-05-13
**目的**: EKS Auto Modeの概要理解と実践的なコンソール操作を習得する
**前提知識**: Kubernetes基礎（Pod、Deployment、Service）
**費用**: 実施時間に応じたEC2・ELB料金（数ドル程度）
