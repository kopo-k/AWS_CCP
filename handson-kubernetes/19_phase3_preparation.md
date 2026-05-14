# Phase 3直前の準備 ハンズオン

**ファイルパス**: `/Users/k24032kk/AWS_CCP/handson-kubernetes/19_phase3_preparation.md`

**前提**: Level 1-4を完了していること

**環境**: minikube（予行演習）

**所要時間**: 約7時間（2-3日、毎日2-3時間）

**目的**: Phase 3本番前にminikubeでnginx + PostgreSQL構成を完全に作り上げる

---

## 📋 このハンズオンで学ぶこと

- ✅ nginx + PostgreSQL構成をminikubeで構築
- ✅ Phase 3で使う全YAMLファイルを準備
- ✅ eksctl設定ファイルを準備
- ✅ コスト見積もりを確認

---

## なぜPhase 3直前の準備が必要？

### Phase 3で作る構成

```
標準EKS（48時間、約$50-60）
  ├── nginx Deployment + Service + Ingress
  ├── PostgreSQL StatefulSet + PVC + Service
  ├── Karpenter
  ├── EBS CSI Driver
  └── ALB Controller

Auto Mode（48時間、約$50-60）
  └── 同じ構成
```

**合計コスト**: $100-120

### 問題

もしPhase 3で**いきなり本番環境（EKS）**を作り始めると...

```
❌ YAMLの書き方を忘れている
❌ 構成の全体像が掴めていない
❌ トラブルシューティングに時間がかかる
❌ 無駄に課金時間が伸びる
```

### 解決策：minikubeで予行演習

```
✅ minikube（無料）でnginx + PostgreSQL構成を完全に作る
✅ Phase 3で使うYAMLファイルを準備
✅ 全体の流れを把握
✅ Phase 3では準備したYAMLを使うだけ
```

**結果**: Phase 3がスムーズに進む + コスト削減

---

# Part 1: nginx + PostgreSQL構成をminikubeで構築（3-4時間）

## タスク1: nginx Deployment + Serviceをminikubeで作成する（1時間）

### minikube起動確認

```bash
minikube status
```

起動していなければ:

```bash
minikube start
```

### ディレクトリ作成

```bash
cd /Users/k24032kk/AWS_CCP
mkdir -p phase3-yamls
cd phase3-yamls
```

### nginx Deployment作成

```bash
cat > nginx-deployment.yaml << 'EOF'
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
        image: nginx:1.21
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
        env:
        - name: POSTGRES_HOST
          value: "postgres-service"
        - name: POSTGRES_PORT
          value: "5432"
EOF
```

```bash
kubectl apply -f nginx-deployment.yaml
```

### nginx Service作成

```bash
cat > nginx-service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  labels:
    app: nginx
spec:
  type: ClusterIP
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
EOF
```

```bash
kubectl apply -f nginx-service.yaml
```

### 確認

```bash
# Pod確認
kubectl get pods -l app=nginx

# Service確認
kubectl get svc nginx-service

# アクセステスト
kubectl run test --image=busybox -it --rm --restart=Never -- wget -O- nginx-service
```

**期待される出力**: nginxのHTMLが表示される

---

## タスク2: PostgreSQL StatefulSet + PVC + Serviceをminikubeで作成する（1.5時間）

### PostgreSQL用のSecret作成

```bash
cat > postgres-secret.yaml << 'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
type: Opaque
data:
  username: cG9zdGdyZXM=  # "postgres" in base64
  password: cGFzc3dvcmQxMjM=  # "password123" in base64
EOF
```

```bash
kubectl apply -f postgres-secret.yaml
```

### PostgreSQL StatefulSet作成

```bash
cat > postgres-statefulset.yaml << 'EOF'
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres-service
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:14
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_USER
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: username
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        - name: POSTGRES_DB
          value: "mydb"
        - name: PGDATA
          value: "/var/lib/postgresql/data/pgdata"
        resources:
          requests:
            cpu: 500m
            memory: 512Mi
          limits:
            cpu: 1000m
            memory: 1Gi
        volumeMounts:
        - name: postgres-data
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: postgres-data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
EOF
```

```bash
kubectl apply -f postgres-statefulset.yaml
```

### PostgreSQL Service（Headless）作成

```bash
cat > postgres-service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
  labels:
    app: postgres
spec:
  clusterIP: None
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
    protocol: TCP
EOF
```

```bash
kubectl apply -f postgres-service.yaml
```

### 確認

```bash
# Pod確認
kubectl get pods -l app=postgres

# StatefulSet確認
kubectl get statefulset postgres

# PVC確認
kubectl get pvc

# Service確認
kubectl get svc postgres-service
```

### データベース接続テスト

```bash
# PostgreSQL Pod内でpsqlコマンド実行
kubectl exec -it postgres-0 -- psql -U postgres -d mydb
```

**Pod内で実行**:
```sql
-- テーブル作成
CREATE TABLE test (id SERIAL PRIMARY KEY, name VARCHAR(50));

-- データ挿入
INSERT INTO test (name) VALUES ('Phase 3 Test');

-- データ確認
SELECT * FROM test;

-- 終了
\q
```

**期待される出力**:
```
 id |     name
----+--------------
  1 | Phase 3 Test
(1 row)
```

---

## タスク3: Ingress（minikube addon）でnginxにHTTPアクセスする（30分）

### Ingress Addon有効化

```bash
minikube addons enable ingress
```

### Ingress作成

```bash
cat > ingress.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: nginx.local
    http:
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
kubectl apply -f ingress.yaml
```

### /etc/hostsに追加

```bash
echo "$(minikube ip) nginx.local" | sudo tee -a /etc/hosts
```

### アクセステスト

```bash
curl http://nginx.local
```

**期待される出力**: nginxのHTMLが表示される

---

## タスク4: nginx → PostgreSQL 接続を確認する（30分）

### nginx Podからpostgres接続テスト

```bash
# nginx Podの名前を取得
NGINX_POD=$(kubectl get pods -l app=nginx -o jsonpath='{.items[0].metadata.name}')

# nginx PodからPostgreSQL接続
kubectl exec -it $NGINX_POD -- sh
```

**Pod内で実行**:
```sh
# PostgreSQLクライアントをインストール
apt-get update && apt-get install -y postgresql-client

# 接続テスト
psql -h postgres-service -U postgres -d mydb -c "SELECT * FROM test;"

# 終了
exit
```

**期待される出力**:
```
 id |     name
----+--------------
  1 | Phase 3 Test
(1 row)
```

**成功**: nginx → PostgreSQL接続確認完了 ✅

---

# Part 2: Phase 3用のYAMLファイル準備（2時間）

## タスク5-10: Phase 3用のYAMLファイルを準備する

### 現在のYAMLファイル確認

```bash
ls -la /Users/k24032kk/AWS_CCP/phase3-yamls
```

**確認項目**:
- ✅ nginx-deployment.yaml
- ✅ nginx-service.yaml
- ✅ postgres-secret.yaml
- ✅ postgres-statefulset.yaml
- ✅ postgres-service.yaml
- ✅ ingress.yaml

### Phase 3用にIngressを修正（ALB用）

```bash
cat > ingress-alb.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/healthcheck-path: /
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

### Phase 3用にStatefulSetを修正（StorageClass指定）

```bash
cat > postgres-statefulset-eks.yaml << 'EOF'
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres-service
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:14
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_USER
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: username
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        - name: POSTGRES_DB
          value: "mydb"
        - name: PGDATA
          value: "/var/lib/postgresql/data/pgdata"
        resources:
          requests:
            cpu: 500m
            memory: 512Mi
          limits:
            cpu: 1000m
            memory: 1Gi
        volumeMounts:
        - name: postgres-data
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: postgres-data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: gp3  # ← EKS用に変更
      resources:
        requests:
          storage: 10Gi
EOF
```

### 全YAMLファイル一覧

```bash
ls -la /Users/k24032kk/AWS_CCP/phase3-yamls
```

**Phase 3で使うファイル**:
```
nginx-deployment.yaml        ← そのまま使える
nginx-service.yaml           ← そのまま使える
postgres-secret.yaml         ← そのまま使える
postgres-statefulset-eks.yaml ← EKS用（gp3指定）
postgres-service.yaml        ← そのまま使える
ingress-alb.yaml             ← ALB用
```

---

# Part 3: eksctl設定ファイル準備（1時間）

## タスク11: 標準EKS用のeksctl設定ファイルを準備する

### 標準EKS設定ファイル作成

```bash
cd /Users/k24032kk/AWS_CCP
mkdir -p phase3-eks-configs
cd phase3-eks-configs

cat > eks-standard-cluster.yaml << 'EOF'
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: phase3-standard-cluster
  region: ap-northeast-1
  version: "1.28"
  tags:
    environment: phase3
    comparison: standard-vs-auto

# IAM OIDC Provider（IRSA用）
iam:
  withOIDC: true

# VPC設定
vpc:
  cidr: 10.0.0.0/16
  nat:
    gateway: HighlyAvailable

# マネージドノードグループ
managedNodeGroups:
  - name: standard-nodes
    instanceType: t3.small
    desiredCapacity: 2
    minSize: 1
    maxSize: 5
    volumeSize: 20
    labels:
      role: standard
      phase: 3
    tags:
      Name: phase3-standard-node
      nodegroup-type: standard
    iam:
      withAddonPolicies:
        ebs: true
        albIngress: true

# Karpenter設定
karpenter:
  version: v0.33.0

# Addons
addons:
  - name: vpc-cni
  - name: coredns
  - name: kube-proxy
  - name: aws-ebs-csi-driver
    serviceAccountRoleARN: arn:aws:iam::${AWS_ACCOUNT_ID}:role/AmazonEKS_EBS_CSI_DriverRole
EOF
```

**注意**: `${AWS_ACCOUNT_ID}` は実際のAWSアカウントIDに置き換える

---

## タスク12: Auto Mode用のeksctl設定ファイルを準備する

### Auto Mode設定ファイル作成

```bash
cat > eks-auto-mode-cluster.yaml << 'EOF'
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: phase3-auto-cluster
  region: ap-northeast-1
  version: "1.28"
  tags:
    environment: phase3
    comparison: standard-vs-auto

# IAM OIDC Provider
iam:
  withOIDC: true

# Auto Mode設定
autoMode:
  enabled: true

# VPC設定（Auto Modeでも必要）
vpc:
  cidr: 10.0.0.0/16

# Addons（Auto Modeでも明示的に指定）
addons:
  - name: vpc-cni
  - name: coredns
  - name: kube-proxy
  - name: aws-ebs-csi-driver
    serviceAccountRoleARN: arn:aws:iam::${AWS_ACCOUNT_ID}:role/AmazonEKS_EBS_CSI_DriverRole_Auto
EOF
```

---

## タスク13: VPC設定を確認する

### VPC要件チェックリスト

Phase 3で使うVPC（eksctlが自動作成）:

- [x] 2つ以上のアベイラビリティゾーン
- [x] 各AZにPublic SubnetとPrivate Subnet
- [x] NAT Gateway × 2（HighlyAvailable）
- [x] Internet Gateway
- [x] 適切なタグ設定

**タグ設定（eksctlが自動設定）**:

Public Subnet:
```
kubernetes.io/role/elb: 1
kubernetes.io/cluster/<cluster-name>: shared
```

Private Subnet:
```
kubernetes.io/role/internal-elb: 1
kubernetes.io/cluster/<cluster-name>: shared
```

---

# Part 4: コスト見積もり確認（30分）

## タスク14: コスト見積もりを確認する

### Phase 3の全体コスト

#### 標準EKS（48時間）

| リソース | 時間単価 | 48時間 |
|---------|---------|--------|
| **EKSクラスタ** | $0.10/時間 | $4.80 |
| **EC2（t3.small × 2）** | $0.025 × 2/時間 | $2.40 |
| **NAT Gateway × 2** | $0.045 × 2/時間 | $4.32 |
| **EBS（20GB × 2）** | $0.01/GB/月 | $0.03 |
| **Data Transfer** | 少量 | $0.50 |
| **ALB** | $0.0225/時間 | $1.08 |
| **小計** | | **$13.13** |

**実際のコスト**: 約$15-20（削除漏れ含む）

**48時間 × 2回（試行錯誤）**: **$30-40**

---

#### Auto Mode（48時間）

| リソース | 時間単価 | 48時間 |
|---------|---------|--------|
| **EKSクラスタ** | $0.10/時間 | $4.80 |
| **Compute（Auto Mode料金）** | 変動 | $5-10 |
| **NAT Gateway × 2** | $0.045 × 2/時間 | $4.32 |
| **Data Transfer** | 少量 | $0.50 |
| **ALB** | $0.0225/時間 | $1.08 |
| **小計** | | **$15.70-20.70** |

**実際のコスト**: 約$20-25

**48時間 × 2回**: **$40-50**

---

### Phase 3全体（標準 + Auto Mode）

| 項目 | コスト |
|------|--------|
| **標準EKS** | $30-40 |
| **Auto Mode** | $40-50 |
| **合計** | **$70-90** |

**予算**: **$100**（余裕を持った見積もり）

---

### コスト削減のポイント

1. **削除を徹底**
   ```bash
   # 検証終了後すぐに削除
   eksctl delete cluster --name phase3-standard-cluster
   eksctl delete cluster --name phase3-auto-cluster
   ```

2. **夜間は削除**
   - 作業終了時に削除
   - 翌日再作成

3. **最小構成**
   - Node数: 2個（標準）
   - インスタンスタイプ: t3.small

4. **削除確認**
   ```bash
   # クラスタ削除確認
   eksctl get cluster

   # VPC削除確認（手動削除の場合）
   aws ec2 describe-vpcs --filters "Name=tag:Name,Values=*phase3*"

   # NAT Gateway削除確認（重要！）
   aws ec2 describe-nat-gateways --filter "Name=state,Values=available" --query "NatGateways[*].[NatGatewayId,VpcId,State]" --output table
   ```

---

# Phase 3直前の準備 全体まとめ

## 完了したタスク

- [x] nginx Deployment + Serviceをminikubeで作成する
- [x] PostgreSQL StatefulSet + PVC + Serviceをminikubeで作成する
- [x] Ingress（minikube addon）でnginxにHTTPアクセスする
- [x] nginx → PostgreSQL 接続を確認する
- [x] Phase 3用のnginx-deployment.yamlを準備する
- [x] Phase 3用のnginx-service.yamlを準備する
- [x] Phase 3用のpostgres-statefulset.yamlを準備する
- [x] Phase 3用のpostgres-pvc.yamlを準備する
- [x] Phase 3用のpostgres-service.yamlを準備する
- [x] Phase 3用のingress.yamlを準備する
- [x] 標準EKS用のeksctl設定ファイルを準備する
- [x] Auto Mode用のeksctl設定ファイルを準備する
- [x] VPC設定を確認する
- [x] コスト見積もりを確認する（標準EKS約$30-40、Auto Mode約$40-50、合計$70-90）

## 準備完了！

### 確認項目

- [x] minikubeでnginx + PostgreSQL構成が動作している
- [x] Phase 3用のYAMLファイルが全て揃っている
- [x] eksctl設定ファイルが準備できている
- [x] コスト見積もりを理解している
- [x] 削除手順を理解している

## Phase 3実行の心構え

### 準備できていること

✅ **Level 1-4の知識**
- Kubernetes基礎（Pod, Deployment, Service）
- Kubernetes中級（StatefulSet, PVC, Ingress）
- AWS基礎（VPC, IAM, IRSA）
- EKS実践（eksctl, Karpenter, EBS CSI, ALB Controller）

✅ **YAMLファイル**
- nginx関連（Deployment, Service）
- PostgreSQL関連（StatefulSet, Service, Secret）
- Ingress（ALB用）
- eksctl設定（標準、Auto Mode）

✅ **コスト理解**
- 見積もり: $70-90
- 削除手順を理解
- NAT Gatewayの削除確認が重要

### Phase 3の流れ（予定）

```
Day 1-2: 標準EKS構築（24時間）
  1. EKSクラスタ作成（eksctl）
  2. Karpenter導入
  3. EBS CSI Driver導入
  4. ALB Controller導入
  5. nginx + PostgreSQL デプロイ
  6. 動作確認・負荷テスト
  7. データ収集
  8. 削除

Day 3-4: Auto Mode構築（24時間）
  1. EKSクラスタ作成（Auto Mode）
  2. nginx + PostgreSQL デプロイ
  3. 動作確認・負荷テスト
  4. データ収集
  5. 削除

Day 5: 比較分析
  1. データ整理
  2. 比較表作成
  3. 記事執筆開始
```

## 最終チェック

### ファイル確認

```bash
# YAMLファイル
ls -la /Users/k24032kk/AWS_CCP/phase3-yamls

# eksctl設定
ls -la /Users/k24032kk/AWS_CCP/phase3-eks-configs
```

### AWS認証情報確認

```bash
# AWSアカウント確認
aws sts get-caller-identity

# リージョン確認
aws configure get region
```

### kubectl確認

```bash
kubectl version --client
```

### eksctl確認

```bash
eksctl version
```

### Helm確認

```bash
helm version
```

---

## Phase 3実行準備完了 ✅

**次のステップ**: Phase 3（検証環境構築）を実行

これであなたは：
- Kubernetes基礎から実践まで完全に理解
- AWS/EKSの知識を習得
- Phase 3で使う全YAMLファイルを準備
- コスト見積もりを理解

**Phase 3で確実に成功できます！** 🎯

---

**作成日**: 2026-05-14
**目的**: Phase 3検証環境構築の最終準備
**対象者**: Level 1-4を完了した人
**次**: Phase 3実行 → 比較記事執筆 → 🎉
