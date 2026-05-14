# Level 2: Kubernetes中級 ハンズオン

**ファイルパス**: `/Users/k24032kk/AWS_CCP/handson-kubernetes/16_kubernetes_intermediate_handson.md`

**前提**: Level 1（Pod, Deployment, Service, ConfigMap, Secret）を完了していること

**環境**: minikube

**所要時間**: 約13時間（1週間、毎日2時間）

**Phase 3での使い道**: PostgreSQL StatefulSet、PVC、Ingress、HPA

---

## 📋 このハンズオンで学ぶこと

- ✅ StatefulSet（ステートフルなアプリケーション用）
- ✅ PV・PVC（永続ストレージ）
- ✅ Ingress（HTTP/HTTPSルーティング）
- ✅ HPA（水平Podオートスケーラー）

---

# Part 1: StatefulSet の基礎（3.5時間）

## タスク1: StatefulSetとは何か、Deploymentとの違いを学ぶ（30分）

### StatefulSetとは？

**StatefulSet** = **Stateful（状態を持つ）** + **Set（セット）**

- **Stateful**: ラテン語の「status（スタトゥス）」= 状態
- **意味**: データや状態を保持するアプリケーション用のPod管理

### DeploymentとStatefulSetの違い

| 項目 | Deployment | StatefulSet |
|------|-----------|------------|
| **用途** | ステートレスアプリ<br/>（nginx, Webサーバーなど） | ステートフルアプリ<br/>（データベース、キャッシュなど） |
| **Pod名** | ランダム<br/>`nginx-deployment-abc123` | 固定・順序付き<br/>`postgres-0`, `postgres-1` |
| **起動順序** | 並列（同時に起動） | 順序付き（0→1→2の順） |
| **削除順序** | ランダム | 逆順（2→1→0の順） |
| **ネットワーク** | 不安定（Pod再起動でIP変更） | 安定（Headless Service経由で名前解決） |
| **ストレージ** | 共有可能 | Pod固有（PVC個別割り当て） |

### いつ使う？

#### Deployment を使う場面
```
✅ Webサーバー（nginx, Apache）
✅ APIサーバー（Node.js, Go）
✅ フロントエンド（React, Vue）
✅ どのPodでも同じ処理ができる
```

#### StatefulSet を使う場面
```
✅ データベース（PostgreSQL, MySQL, MongoDB）
✅ キャッシュ（Redis, Memcached）
✅ メッセージキュー（Kafka, RabbitMQ）
✅ Pod個別に状態やデータを持つ必要がある
```

---

## タスク2: StatefulSet YAMLの書き方を学ぶ（1時間）

### 基本構造

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: "nginx-service"  # Headless Service名（必須）
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:  # Podテンプレート（Deploymentと同じ）
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
```

### Deploymentとの違い

```yaml
# Deploymentの場合
apiVersion: apps/v1
kind: Deployment  # ← ここが違う
metadata:
  name: web-deployment
spec:
  # serviceName は不要
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    # 以下同じ

# StatefulSetの場合
apiVersion: apps/v1
kind: StatefulSet  # ← ここが違う
metadata:
  name: web
spec:
  serviceName: "nginx-service"  # ← これが必須
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    # 以下同じ
```

### Headless Service とは？

**通常のService**:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  clusterIP: 10.96.0.1  # ← ClusterIPが割り当てられる
  selector:
    app: nginx
  ports:
  - port: 80
```

**Headless Service**:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  clusterIP: None  # ← Noneにする（これがHeadless）
  selector:
    app: nginx
  ports:
  - port: 80
```

**違い**:
- **通常のService**: 1つのIPで全Podに負荷分散
- **Headless Service**: 各Pod個別にDNS名でアクセス可能

**DNS名の例**:
```
通常のService:
  nginx-service.default.svc.cluster.local → 10.96.0.1（全Podに負荷分散）

Headless Service:
  web-0.nginx-service.default.svc.cluster.local → web-0のIP
  web-1.nginx-service.default.svc.cluster.local → web-1のIP
  web-2.nginx-service.default.svc.cluster.local → web-2のIP
```

---

## タスク3: 簡単なStatefulSetを作成する（1時間）

### ファイル作成

```bash
cd /Users/k24032kk/AWS_CCP/handson-kubernetes
```

#### 1. Headless Service作成

```bash
cat > nginx-headless-service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  labels:
    app: nginx
spec:
  clusterIP: None  # Headless Service
  selector:
    app: nginx
  ports:
  - port: 80
    name: web
EOF
```

#### 2. StatefulSet作成

```bash
cat > nginx-statefulset.yaml << 'EOF'
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: "nginx-service"
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
          name: web
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
EOF
```

### 適用

```bash
# 1. Headless Serviceを先に作成
kubectl apply -f nginx-headless-service.yaml

# 2. StatefulSetを作成
kubectl apply -f nginx-statefulset.yaml
```

**期待される出力**:
```
service/nginx-service created
statefulset.apps/web created
```

### 確認

```bash
# Podの起動を確認（順番に起動する様子を観察）
kubectl get pods -w
```

**期待される出力**:
```
NAME    READY   STATUS              RESTARTS   AGE
web-0   0/1     ContainerCreating   0          5s
web-0   1/1     Running             0          10s
web-1   0/1     Pending             0          0s
web-1   0/1     ContainerCreating   0          2s
web-1   1/1     Running             0          8s
web-2   0/1     Pending             0          0s
web-2   0/1     ContainerCreating   0          2s
web-2   1/1     Running             0          8s
```

**ポイント**: `web-0` → `web-1` → `web-2` の順に起動

Ctrl+C で終了

```bash
# 最終確認
kubectl get pods
```

**期待される出力**:
```
NAME    READY   STATUS    RESTARTS   AGE
web-0   1/1     Running   0          1m
web-1   1/1     Running   0          50s
web-2   1/1     Running   0          40s
```

### StatefulSetの詳細確認

```bash
kubectl describe statefulset web
```

**重要な出力**:
```
Name:               web
Namespace:          default
Service:            nginx-service  ← Headless Service
Replicas:           3 desired | 3 total
Pods Status:        3 Running / 0 Waiting / 0 Succeeded / 0 Failed
```

---

## タスク4: StatefulSetをスケールする（1時間）

### スケールアウト（3→5）

```bash
kubectl scale statefulset web --replicas=5
```

**確認**:
```bash
kubectl get pods -w
```

**期待される出力**:
```
NAME    READY   STATUS              RESTARTS   AGE
web-0   1/1     Running             0          5m
web-1   1/1     Running             0          4m50s
web-2   1/1     Running             0          4m40s
web-3   0/1     Pending             0          0s
web-3   0/1     ContainerCreating   0          2s
web-3   1/1     Running             0          8s
web-4   0/1     Pending             0          0s
web-4   0/1     ContainerCreating   0          2s
web-4   1/1     Running             0          8s
```

**ポイント**: `web-3` → `web-4` の順に追加される

Ctrl+C で終了

### スケールイン（5→2）

```bash
kubectl scale statefulset web --replicas=2
```

**確認**:
```bash
kubectl get pods -w
```

**期待される出力**:
```
NAME    READY   STATUS        RESTARTS   AGE
web-0   1/1     Running       0          6m
web-1   1/1     Running       0          5m50s
web-2   1/1     Running       0          5m40s
web-3   1/1     Running       0          1m
web-4   1/1     Running       0          50s
web-4   1/1     Terminating   0          52s
web-4   0/1     Terminating   0          53s
web-3   1/1     Terminating   0          1m2s
web-3   0/1     Terminating   0          1m3s
```

**ポイント**: `web-4` → `web-3` → `web-2` の逆順に削除される

Ctrl+C で終了

### 最終確認

```bash
kubectl get pods
```

**期待される出力**:
```
NAME    READY   STATUS    RESTARTS   AGE
web-0   1/1     Running   0          7m
web-1   1/1     Running   0          6m50s
```

### DNS確認（重要）

```bash
# 一時的なPodを起動してDNS確認
kubectl run -it --rm debug --image=busybox --restart=Never -- sh
```

**Podの中で実行**:
```sh
# web-0のDNS確認
nslookup web-0.nginx-service.default.svc.cluster.local

# web-1のDNS確認
nslookup web-1.nginx-service.default.svc.cluster.local

# 終了
exit
```

**期待される出力**:
```
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      web-0.nginx-service.default.svc.cluster.local
Address 1: 10.244.0.5 web-0.nginx-service.default.svc.cluster.local

Name:      web-1.nginx-service.default.svc.cluster.local
Address 1: 10.244.0.6 web-1.nginx-service.default.svc.cluster.local
```

**ポイント**: 各PodがDNS名で個別にアクセス可能

---

## Part 1 まとめ

- [x] StatefulSetとDeploymentの違いを理解した
- [x] StatefulSet YAMLの書き方を学んだ
- [x] StatefulSetを作成して動作確認した
- [x] スケール操作を理解した

**Phase 3での使い道**: PostgreSQL StatefulSetの作成

**次**: Part 2（PV・PVC）

---

# Part 2: PV・PVC の基礎（3.5時間）

## タスク5: PV・PVCとは何か学ぶ（30分）

### 用語

**PV = Persistent Volume（パーシステント・ボリューム）** = 永続ボリューム
**PVC = Persistent Volume Claim（パーシステント・ボリューム・クレーム）** = 永続ボリューム要求

- **Persistent**: ラテン語の「persistere（ペルシステーレ）」= 持続する、残り続ける
- **Volume**: ラテン語の「volumen（ボルメン）」= 巻物 → 容量
- **Claim**: ラテン語の「clamare（クラマーレ）」= 叫ぶ、要求する

### なぜ必要？

**問題**: Podを削除すると、Pod内のデータも消える

```bash
# Podの中にファイルを作る
kubectl exec web-0 -- sh -c "echo 'Hello' > /tmp/test.txt"
kubectl exec web-0 -- cat /tmp/test.txt
# 出力: Hello

# Podを削除して再作成
kubectl delete pod web-0
kubectl wait --for=condition=Ready pod/web-0

# ファイルが消えている
kubectl exec web-0 -- cat /tmp/test.txt
# 出力: cat: /tmp/test.txt: No such file or directory
```

**解決策**: PVCを使ってデータを永続化

### PVとPVCの関係

```
PV（ストレージの実体）
  ↑ バインド
PVC（ストレージの要求）
  ↑ マウント
Pod（アプリケーション）
```

**例え**:
- **PV** = 賃貸物件（実際の部屋）
- **PVC** = 入居申込書（部屋を借りたい）
- **Pod** = 入居者（部屋を使う人）

### 種類

| タイプ | 説明 | 用途 |
|--------|------|------|
| **hostPath** | Nodeのローカルディレクトリ | minikube（開発環境）|
| **emptyDir** | Pod内の一時ディレクトリ | コンテナ間共有 |
| **nfs** | NFSサーバー | オンプレミス |
| **ebs** | AWS EBS | AWS（Phase 3で使用） |
| **gcePersistentDisk** | Google Persistent Disk | GCP |

---

## タスク6: PVC YAMLの書き方を学ぶ（1時間）

### PV YAML（手動作成の場合）

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-example
spec:
  capacity:
    storage: 1Gi  # 容量
  accessModes:
    - ReadWriteOnce  # アクセスモード
  hostPath:
    path: /mnt/data  # Nodeのパス
  storageClassName: manual  # StorageClass名
```

### PVC YAML

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-example
spec:
  accessModes:
    - ReadWriteOnce  # PVと同じにする
  resources:
    requests:
      storage: 500Mi  # 必要な容量
  storageClassName: manual  # PVと同じにする
```

### アクセスモード

| モード | 略称 | 意味 |
|--------|------|------|
| **ReadWriteOnce** | RWO | 1つのNodeから読み書き可能 |
| **ReadOnlyMany** | ROX | 複数のNodeから読み取り専用 |
| **ReadWriteMany** | RWX | 複数のNodeから読み書き可能 |

**Phase 3で使用**: **ReadWriteOnce**（PostgreSQL用）

### PodでPVCを使う

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-pvc
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: storage
      mountPath: /data  # マウント先
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: pvc-example  # PVC名
```

---

## タスク7: PVCを作成してPodにマウントする（1.5時間）

### ファイル作成

#### 1. PV作成（minikube用）

```bash
cat > pv-manual.yaml << 'EOF'
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-manual
  labels:
    type: local
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /mnt/data
  storageClassName: manual
EOF
```

#### 2. PVC作成

```bash
cat > pvc-manual.yaml << 'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-manual
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
  storageClassName: manual
EOF
```

#### 3. Pod作成

```bash
cat > pod-with-pvc.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-pvc
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: storage
      mountPath: /data
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: pvc-manual
EOF
```

### 適用

```bash
# 1. PV作成
kubectl apply -f pv-manual.yaml

# 2. PVC作成
kubectl apply -f pvc-manual.yaml

# 3. Pod作成
kubectl apply -f pod-with-pvc.yaml
```

### 確認

#### PV確認

```bash
kubectl get pv
```

**期待される出力**:
```
NAME        CAPACITY   ACCESS MODES   STATUS   CLAIM                STORAGECLASS   AGE
pv-manual   1Gi        RWO            Bound    default/pvc-manual   manual         1m
```

**STATUS**:
- **Available**: 利用可能（未使用）
- **Bound**: バインド済み（PVCと紐付いている）
- **Released**: 解放済み（PVC削除後）

#### PVC確認

```bash
kubectl get pvc
```

**期待される出力**:
```
NAME         STATUS   VOLUME      CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc-manual   Bound    pv-manual   1Gi        RWO            manual         1m
```

#### Pod確認

```bash
kubectl get pods
```

**期待される出力**:
```
NAME            READY   STATUS    RESTARTS   AGE
pod-with-pvc    1/1     Running   0          1m
```

### データ永続化テスト

```bash
# 1. ファイル作成
kubectl exec pod-with-pvc -- sh -c "echo 'Persistent Data' > /data/test.txt"

# 2. 確認
kubectl exec pod-with-pvc -- cat /data/test.txt
# 出力: Persistent Data

# 3. Pod削除
kubectl delete pod pod-with-pvc

# 4. Pod再作成
kubectl apply -f pod-with-pvc.yaml

# 5. データが残っているか確認
kubectl exec pod-with-pvc -- cat /data/test.txt
# 出力: Persistent Data  ← データが残っている！
```

**成功**: データが永続化された ✅

---

## タスク8: StorageClassの動的プロビジョニングを学ぶ（30分）

### 静的プロビジョニング vs 動的プロビジョニング

| 方式 | 手順 | 利点 | 欠点 |
|------|------|------|------|
| **静的** | PVを手動作成 → PVC作成 | シンプル | 管理が大変 |
| **動的** | PVCだけ作成 → PVが自動作成 | 楽 | StorageClass設定が必要 |

### StorageClass とは？

**StorageClass** = PVを自動作成するための設定テンプレート

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: standard
provisioner: k8s.io/minikube-hostpath  # どのプロビジョナーを使うか
volumeBindingMode: Immediate  # いつバインドするか
```

### minikubeのデフォルトStorageClass

```bash
kubectl get storageclass
```

**期待される出力**:
```
NAME                 PROVISIONER                RECLAIMPOLICY   AGE
standard (default)   k8s.io/minikube-hostpath   Delete          10d
```

**(default)** = デフォルトのStorageClass

### 動的プロビジョニングを試す

#### PVC作成（storageClassNameを指定）

```bash
cat > pvc-dynamic.yaml << 'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-dynamic
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: standard  # StorageClassを指定
EOF
```

```bash
kubectl apply -f pvc-dynamic.yaml
```

#### 確認

```bash
# PVC確認
kubectl get pvc
```

**期待される出力**:
```
NAME          STATUS   VOLUME                                     CAPACITY   AGE
pvc-dynamic   Bound    pvc-12345678-1234-1234-1234-123456789abc   1Gi        5s
```

**ポイント**: PVが自動作成されている

```bash
# PV確認
kubectl get pv
```

**期待される出力**:
```
NAME                                       CAPACITY   ACCESS MODES   STATUS   CLAIM
pvc-12345678-1234-1234-1234-123456789abc   1Gi        RWO            Bound    default/pvc-dynamic
```

**PVが自動作成された！** ✅

---

## Part 2 まとめ

- [x] PV・PVCの概念を理解した
- [x] PVC YAMLの書き方を学んだ
- [x] PVCを作成してPodにマウントした
- [x] データ永続化を確認した
- [x] StorageClassの動的プロビジョニングを理解した

**Phase 3での使い道**: PostgreSQL用のPVC作成、EBS CSI Driverとの連携

**次**: Part 3（Ingress）

---

# Part 3: Ingress の基礎（3.5時間）

## タスク9: Ingressとは何か、ServiceのLoadBalancerとの違いを学ぶ（30分）

### Ingressとは？

**Ingress（イングレス）** = ラテン語の「ingressus（イングレッサス）」= 入り口、進入

**意味**: クラスタ外からクラスタ内のServiceへのHTTP/HTTPSアクセスを管理する

### ServiceのLoadBalancerとの違い

#### パターン1: LoadBalancer Service（従来）

```
Internet
    ↓
LoadBalancer 1 (外部IP 1) → Service A → Pod A
LoadBalancer 2 (外部IP 2) → Service B → Pod B
LoadBalancer 3 (外部IP 3) → Service C → Pod C
```

**問題**:
- ❌ Service毎にLoadBalancerが必要（コスト高）
- ❌ HTTPSはService毎に設定が必要
- ❌ パスベースルーティングができない

#### パターン2: Ingress（推奨）

```
Internet
    ↓
Ingress (外部IP 1)
    ├→ /api   → Service A → Pod A
    ├→ /web   → Service B → Pod B
    └→ /admin → Service C → Pod C
```

**利点**:
- ✅ 1つのLoadBalancerで複数Serviceを公開（コスト削減）
- ✅ HTTPSを一元管理
- ✅ パスベースルーティング
- ✅ ホストベースルーティング

### Ingress Controllerとは？

**Ingress** = 設定（ルール）
**Ingress Controller** = 実際にルーティングを行うプログラム

| Ingress Controller | 説明 | 用途 |
|-------------------|------|------|
| **Nginx Ingress** | Nginxベース | 一般的、minikubeデフォルト |
| **AWS Load Balancer Controller** | ALB/NLBを自動作成 | AWS（Phase 3で使用） |
| **Traefik** | 動的設定が得意 | マイクロサービス |
| **Istio** | サービスメッシュ | 高度なトラフィック制御 |

---

## タスク10: Ingress YAMLの書き方を学ぶ（1時間）

### 基本構造

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
spec:
  rules:
  - host: example.com  # ホスト名
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service  # Service名
            port:
              number: 80
```

### pathType

| タイプ | 意味 | 例 |
|--------|------|-----|
| **Prefix** | 前方一致 | `/api` → `/api`, `/api/users` |
| **Exact** | 完全一致 | `/api` → `/api` のみ |
| **ImplementationSpecific** | Controllerに依存 | 使用非推奨 |

### 複数パスのルーティング

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-path-ingress
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

### ホストベースルーティング

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: host-based-ingress
spec:
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 8080
  - host: web.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

---

## タスク11: minikubeでIngress Addonを有効化して試す（1.5時間）

### Ingress Addon有効化

```bash
# Ingress Controllerを有効化
minikube addons enable ingress
```

**期待される出力**:
```
💡  ingress is an addon maintained by Kubernetes. For any concerns contact minikube on GitHub.
You can view the list of minikube maintainers at: https://github.com/kubernetes/minikube/blob/master/OWNERS
    ▪ Using image registry.k8s.io/ingress-nginx/controller:v1.9.4
    ▪ Using image registry.k8s.io/ingress-nginx/kube-webhook-certgen:v20231011-8b53cabe0
🔎  Verifying ingress addon...
🌟  The 'ingress' addon is enabled
```

### 確認

```bash
kubectl get pods -n ingress-nginx
```

**期待される出力**:
```
NAME                                        READY   STATUS      RESTARTS   AGE
ingress-nginx-admission-create-xxxxx        0/1     Completed   0          1m
ingress-nginx-admission-patch-xxxxx         0/1     Completed   0          1m
ingress-nginx-controller-xxxxxxx-xxxxx      1/1     Running     0          1m
```

### テスト用のDeploymentとServiceを作成

#### 1. Deployment作成

```bash
cat > hello-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello
spec:
  replicas: 2
  selector:
    matchLabels:
      app: hello
  template:
    metadata:
      labels:
        app: hello
    spec:
      containers:
      - name: hello
        image: hashicorp/http-echo
        args:
          - "-text=Hello from Kubernetes!"
        ports:
        - containerPort: 5678
EOF
```

#### 2. Service作成

```bash
cat > hello-service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: hello-service
spec:
  type: ClusterIP
  selector:
    app: hello
  ports:
  - port: 5678
    targetPort: 5678
EOF
```

#### 3. Ingress作成

```bash
cat > hello-ingress.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: hello.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: hello-service
            port:
              number: 5678
EOF
```

### 適用

```bash
kubectl apply -f hello-deployment.yaml
kubectl apply -f hello-service.yaml
kubectl apply -f hello-ingress.yaml
```

### 確認

```bash
# Ingress確認
kubectl get ingress
```

**期待される出力**:
```
NAME            CLASS   HOSTS         ADDRESS        PORTS   AGE
hello-ingress   nginx   hello.local   192.168.49.2   80      1m
```

### /etc/hostsに追加

```bash
# minikubeのIPを取得
minikube ip
# 出力例: 192.168.49.2

# /etc/hostsに追加
echo "$(minikube ip) hello.local" | sudo tee -a /etc/hosts
```

### テスト

```bash
curl http://hello.local
```

**期待される出力**:
```
Hello from Kubernetes!
```

**成功！** ✅

---

## タスク12: Ingress Controllerの理解（30分）

### Nginx Ingress Controllerの仕組み

```
1. IngressリソースをWatch
2. Nginxの設定ファイルを動的生成
3. Nginxをリロード
4. トラフィックをルーティング
```

### 設定確認

```bash
# Ingress Controller Pod名を取得
INGRESS_POD=$(kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller -o jsonpath='{.items[0].metadata.name}')

# Nginx設定を確認
kubectl exec -n ingress-nginx $INGRESS_POD -- cat /etc/nginx/nginx.conf | grep -A 20 "hello.local"
```

**出力例**:
```nginx
server {
    server_name hello.local ;

    location / {
        proxy_pass http://upstream_balancer;
        ...
    }
}
```

---

## Part 3 まとめ

- [x] IngressとLoadBalancer Serviceの違いを理解した
- [x] Ingress YAMLの書き方を学んだ
- [x] minikubeでIngress Addonを有効化した
- [x] Ingressを使ってアプリを公開した
- [x] Ingress Controllerの仕組みを理解した

**Phase 3での使い道**: nginx用のALB Ingressを作成

**次**: Part 4（HPA）

---

# Part 4: HPA の基礎（2.5時間）

## タスク13: HPAとは何か、Metrics Serverを学ぶ（30分）

### HPAとは？

**HPA = Horizontal Pod Autoscaler（ホリゾンタル・ポッド・オートスケーラー）** = 水平Podオートスケーラー

- **Horizontal**: ラテン語の「horizon（ホライゾン）」= 水平線 → 横に拡張
- **Autoscaler**: 自動的に規模を調整する

### スケーリングの種類

| 種類 | 説明 | 例 |
|------|------|-----|
| **Vertical（垂直）** | リソースを増やす | CPU 1コア → 2コア |
| **Horizontal（水平）** | インスタンスを増やす | Pod 1個 → 3個 |

**HPA = 水平スケーリング**（Pod数を増やす）

### Metrics Serverとは？

**Metrics Server** = PodのCPU・メモリ使用率を収集するコンポーネント

```
Metrics Server
    ↓ 収集
各PodのCPU/メモリ使用率
    ↓ 参照
HPA（スケール判断）
```

### HPAの動作

```
1. Metrics ServerからPodのCPU使用率を取得
2. 目標値と比較
3. 必要なPod数を計算
4. Deployment/StatefulSetのreplicasを変更
```

**計算式**:
```
必要なPod数 = 現在のPod数 × (現在のCPU使用率 / 目標CPU使用率)

例:
  現在: 2 Pod、CPU使用率 80%
  目標: CPU使用率 50%
  → 必要なPod数 = 2 × (80 / 50) = 3.2 → 4 Pod
```

---

## タスク14: HPA YAMLの書き方を学ぶ（30分）

### 基本構造

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: example-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment  # 対象リソース
    name: example-deployment
  minReplicas: 1  # 最小Pod数
  maxReplicas: 10  # 最大Pod数
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50  # 目標CPU使用率（%）
```

### メトリクスタイプ

| タイプ | 説明 | 例 |
|--------|------|-----|
| **Resource** | CPU/メモリ | `cpu`, `memory` |
| **Pods** | Podカスタムメトリクス | リクエスト数/秒 |
| **Object** | Kubernetesオブジェクト | Ingressのリクエスト数 |
| **External** | 外部メトリクス | CloudWatchメトリクス |

**Phase 3で使用**: **Resource（CPU）**

### kubectl コマンドで作成（簡易版）

```bash
kubectl autoscale deployment example-deployment --cpu-percent=50 --min=1 --max=10
```

---

## タスク15: nginxに負荷をかけてHPAでスケールさせる（1.5時間）

### Metrics Server有効化（minikube）

```bash
minikube addons enable metrics-server
```

**確認**:
```bash
kubectl get apiservice v1beta1.metrics.k8s.io
```

**期待される出力**:
```
NAME                     SERVICE                      AVAILABLE   AGE
v1beta1.metrics.k8s.io   kube-system/metrics-server   True        1m
```

### テスト用Deployment作成

```bash
cat > php-apache.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: php-apache
spec:
  replicas: 1
  selector:
    matchLabels:
      app: php-apache
  template:
    metadata:
      labels:
        app: php-apache
    spec:
      containers:
      - name: php-apache
        image: registry.k8s.io/hpa-example
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 200m
          limits:
            cpu: 500m
---
apiVersion: v1
kind: Service
metadata:
  name: php-apache
spec:
  ports:
  - port: 80
  selector:
    app: php-apache
EOF
```

```bash
kubectl apply -f php-apache.yaml
```

### HPA作成

```bash
kubectl autoscale deployment php-apache --cpu-percent=50 --min=1 --max=10
```

**または YAML で作成**:

```bash
cat > php-apache-hpa.yaml << 'EOF'
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: php-apache
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: php-apache
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
EOF
```

```bash
kubectl apply -f php-apache-hpa.yaml
```

### HPA確認

```bash
kubectl get hpa
```

**期待される出力**:
```
NAME         REFERENCE               TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
php-apache   Deployment/php-apache   0%/50%    1         10        1          1m
```

### 負荷をかける

**ターミナル1（負荷生成）**:
```bash
kubectl run -it --rm load-generator --image=busybox --restart=Never -- sh -c "while true; do wget -q -O- http://php-apache; done"
```

**ターミナル2（監視）**:
```bash
# HPAを監視
kubectl get hpa -w
```

**期待される出力**:
```
NAME         REFERENCE               TARGETS    MINPODS   MAXPODS   REPLICAS   AGE
php-apache   Deployment/php-apache   0%/50%     1         10        1          2m
php-apache   Deployment/php-apache   250%/50%   1         10        1          3m
php-apache   Deployment/php-apache   250%/50%   1         10        5          3m
php-apache   Deployment/php-apache   100%/50%   1         10        5          4m
```

**ターミナル3（Pod数監視）**:
```bash
kubectl get pods -l app=php-apache -w
```

**期待される出力**:
```
NAME                          READY   STATUS    RESTARTS   AGE
php-apache-xxxxxxxxx-xxxxx    1/1     Running   0          5m
php-apache-xxxxxxxxx-xxxxx    0/1     Pending   0          0s
php-apache-xxxxxxxxx-xxxxx    0/1     ContainerCreating   0          1s
php-apache-xxxxxxxxx-xxxxx    1/1     Running   0          5s
（以下、Pod数が増える）
```

**ポイント**: CPU使用率が50%を超えると、Podが自動的に追加される ✅

### 負荷停止

ターミナル1で `Ctrl+C` を押して負荷生成を停止

**数分待つと**:
```bash
kubectl get hpa
```

**期待される出力**:
```
NAME         REFERENCE               TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
php-apache   Deployment/php-apache   0%/50%    1         10        1          10m
```

Pod数が1に戻る（スケールイン）✅

---

## Part 4 まとめ

- [x] HPAの概念を理解した
- [x] Metrics Serverを有効化した
- [x] HPA YAMLの書き方を学んだ
- [x] 負荷をかけてスケールアウトを確認した
- [x] 負荷停止でスケールインを確認した

**Phase 3での使い道**: nginx DeploymentのHPA設定

---

# Level 2 全体まとめ

## 完了したタスク

- [x] StatefulSetとは何か、Deploymentとの違いを学ぶ
- [x] StatefulSet YAMLの書き方を学ぶ
- [x] 簡単なStatefulSetを作成する
- [x] StatefulSetをスケールする
- [x] PV・PVCとは何か学ぶ
- [x] PVC YAMLの書き方を学ぶ
- [x] PVCを作成してPodにマウントする
- [x] StorageClassの動的プロビジョニングを学ぶ
- [x] Ingressとは何か、ServiceのLoadBalancerとの違いを学ぶ
- [x] Ingress YAMLの書き方を学ぶ
- [x] minikubeでIngress Addonを有効化して試す
- [x] Ingress Controllerの理解（Nginx Ingress, AWS Load Balancer Controller）
- [x] HPAとは何か、Metrics Serverを学ぶ
- [x] HPA YAMLの書き方を学ぶ
- [x] nginxに負荷をかけてHPAでスケールさせる

## 習得したスキル

| スキル | Phase 3での使い道 |
|--------|------------------|
| **StatefulSet** | PostgreSQL StatefulSetの作成 |
| **PVC** | PostgreSQLのデータ永続化 |
| **Ingress** | nginxへのALBアクセス |
| **HPA** | 負荷テスト時の自動スケール |

## 次のステップ

**Level 3: AWS基礎復習（VPC・IAM）** に進む

---

**作成日**: 2026-05-14
**目的**: Phase 3検証環境構築に向けたKubernetes中級スキル習得
**対象者**: Level 1を完了した人
