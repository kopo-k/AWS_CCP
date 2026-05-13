# ハンズオン⑭：Kubernetesネットワーク入門

## Kubernetesネットワークとは

**Pod同士、Pod⇔外部がどのように通信するかの仕組み**

### 重要な原則

1. **全てのPodは固有のIPアドレスを持つ**
2. **Pod間は直接通信できる**（同じノード内でも別ノードでも）
3. **Serviceを使って安定したアクセスポイントを提供**

---

## Part 1：Pod間通信の基礎

### Step 1：2つのPodを作成

`pod-a.yaml` を作成します。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-a
  labels:
    app: pod-a
spec:
  containers:
  - name: nginx
    image: nginx:latest
    ports:
    - containerPort: 80
```

`pod-b.yaml` を作成します。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-b
  labels:
    app: pod-b
spec:
  containers:
  - name: busybox
    image: busybox:latest
    command: ['sh', '-c', 'sleep 3600']
```

### Step 2：Podを作成してIPアドレスを確認

```bash
kubectl apply -f pod-a.yaml
kubectl apply -f pod-b.yaml

# PodのIPアドレスを確認
kubectl get pods -o wide
```

**結果例**:
```
NAME    READY   STATUS    RESTARTS   AGE   IP           NODE
pod-a   1/1     Running   0          10s   10.244.0.4   minikube
pod-b   1/1     Running   0          5s    10.244.0.5   minikube
```

### Step 3：Pod-BからPod-Aにアクセスしてみる

```bash
# Pod-BからPod-AのIPに直接アクセス
kubectl exec pod-b -- wget -qO- 10.244.0.4
```

**結果**: Nginxのデフォルトページが表示される

```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
```

### 何が起きた？

```
Pod-B（10.244.0.5）
    ↓ wget 10.244.0.4
Pod-A（10.244.0.4）
    ↓ Nginxが応答
HTML返却
```

**重要**：PodのIPアドレスは直接通信できる

---

## Part 2：問題点 - PodのIPアドレスは変わる

### Step 4：Pod-Aを削除して再作成

```bash
# 削除
kubectl delete pod pod-a

# 再作成
kubectl apply -f pod-a.yaml

# IPアドレスを確認
kubectl get pods -o wide
```

**結果例**:
```
NAME    READY   STATUS    RESTARTS   AGE   IP           NODE
pod-a   1/1     Running   0          5s    10.244.0.6   minikube  ← IPが変わった！
pod-b   1/1     Running   0          2m    10.244.0.5   minikube
```

### 問題

```bash
# 古いIPにアクセス → 失敗
kubectl exec pod-b -- wget -qO- 10.244.0.4 --timeout=2
# エラー: wget: can't connect to remote host
```

**PodのIPアドレスは固定されていない → 直接IPでアクセスするのは危険**

---

## Part 3：Service で安定したアクセスを提供

### Service の役割

**Service = PodへのアクセスポイントとなるDNS名とIPアドレスを提供**

```
クライアント
    ↓
Service（固定IP・DNS名）
    ↓ ラベルセレクタで転送
Pod-A（IPが変わっても大丈夫）
```

### Step 5：Serviceを作成

`service-a.yaml` を作成します。

```yaml
apiVersion: v1
kind: Service
metadata:
  name: service-a
spec:
  selector:
    app: pod-a  # app=pod-aのラベルを持つPodに転送
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: ClusterIP  # クラスタ内部のみアクセス可能
```

```bash
kubectl apply -f service-a.yaml

# Serviceを確認
kubectl get svc
```

**結果例**:
```
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service-a    ClusterIP   10.96.123.45    <none>        80/TCP    5s
```

### Step 6：ServiceのIPでアクセス

```bash
# ServiceのIPでアクセス
kubectl exec pod-b -- wget -qO- 10.96.123.45
```

**成功！** Nginxのページが表示される

### Step 7：Pod-Aを削除→再作成してもアクセスできる

```bash
# Pod-Aを削除
kubectl delete pod pod-a

# 再作成（IPが変わる）
kubectl apply -f pod-a.yaml

# PodのIPを確認（変わっている）
kubectl get pods -o wide

# でも、ServiceのIPでアクセスできる
kubectl exec pod-b -- wget -qO- 10.96.123.45
```

**ServiceのIPは変わらない → 安定したアクセス**

---

## Part 4：DNS による名前解決

### Kubernetes の内部DNS

**全てのServiceにDNS名が自動的に割り当てられる**

```
Service名.Namespace名.svc.cluster.local
```

例：
- Service名: `service-a`
- Namespace: `default`
- DNS名: `service-a.default.svc.cluster.local`

### Step 8：DNS名でアクセス

```bash
# 完全なDNS名でアクセス
kubectl exec pod-b -- wget -qO- service-a.default.svc.cluster.local

# 同じNamespaceなら短縮形でもOK
kubectl exec pod-b -- wget -qO- service-a
```

**どちらも成功！**

### DNS解決の仕組み

```
Pod-B
    ↓ wget service-a
Kubernetes DNS（CoreDNS）
    ↓ service-a → 10.96.123.45
Service（10.96.123.45）
    ↓ ラベルセレクタ
Pod-A
```

### Step 9：nslookupで確認

```bash
# DNSの名前解決を確認
kubectl exec pod-b -- nslookup service-a
```

**結果例**:
```
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      service-a
Address 1: 10.96.123.45 service-a.default.svc.cluster.local
```

---

## Part 5：Serviceの種類

### 1. ClusterIP（デフォルト）

**クラスタ内部のみアクセス可能**

```yaml
spec:
  type: ClusterIP
  ports:
  - port: 80
```

- 用途：内部サービス間通信
- アクセス元：Pod、他のService
- 外部から：アクセス不可

### 2. NodePort

**ノードのポートを使って外部公開**

`service-a-nodeport.yaml` を作成します。

```yaml
apiVersion: v1
kind: Service
metadata:
  name: service-a-nodeport
spec:
  type: NodePort
  selector:
    app: pod-a
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
    nodePort: 30080  # 30000-32767の範囲
```

```bash
kubectl apply -f service-a-nodeport.yaml

# Serviceを確認
kubectl get svc
```

**結果例**:
```
NAME                  TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
service-a-nodeport    NodePort    10.96.200.10    <none>        80:30080/TCP   5s
```

### 外部からアクセス

```bash
# minikubeのIPアドレスを確認
minikube ip
# 例: 192.168.49.2

# ブラウザでアクセス
# http://192.168.49.2:30080
```

または

```bash
# minikubeのサービスURLを開く
minikube service service-a-nodeport
```

### 3. LoadBalancer（クラウド環境用）

**クラウドのロードバランサーを使って外部公開**

```yaml
spec:
  type: LoadBalancer
  ports:
  - port: 80
```

- AWS ELB、GCP Load Balancer などを自動作成
- ローカル環境（minikube）では使えない

---

## Part 6：ポートの3段階を理解する

### Service定義の復習

```yaml
ports:
- protocol: TCP
  port: 80         # ① Serviceのポート
  targetPort: 80   # ② Podのポート
  nodePort: 30080  # ③ ノードのポート（NodePortの場合のみ）
```

### 通信の流れ

```
外部ブラウザ
    ↓
③ nodePort: 30080（ノードの30080番ポート）
    ↓
① port: 80（Serviceの80番ポート）
    ↓
② targetPort: 80（Podの80番ポート）
    ↓
コンテナのNginx（80番で待ち受け）
```

### 具体例

**ClusterIP の場合**:
```
Pod-B
    ↓
service-a:80 ← ① Serviceのポート
    ↓
Pod-A:80 ← ② Podのポート
```

**NodePort の場合**:
```
外部ブラウザ
    ↓
192.168.49.2:30080 ← ③ ノードのポート
    ↓
service-a-nodeport:80 ← ① Serviceのポート
    ↓
Pod-A:80 ← ② Podのポート
```

---

## Part 7：Deployment + Service の実践

### Step 10：Deploymentを作成

`nginx-deployment-network.yaml` を作成します。

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
```

`nginx-service-network.yaml` を作成します。

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx  # app=nginxのラベルを持つ全てのPodに転送
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: ClusterIP
```

### Step 11：作成して確認

```bash
kubectl apply -f nginx-deployment-network.yaml
kubectl apply -f nginx-service-network.yaml

# Podを確認（3個作成される）
kubectl get pods -o wide

# Serviceを確認
kubectl get svc nginx-service
```

### Step 12：ServiceがPodを負荷分散していることを確認

```bash
# Pod-Bから何度もアクセス
kubectl exec pod-b -- sh -c 'for i in 1 2 3 4 5; do wget -qO- nginx-service | grep "Server address"; done'
```

**結果例**:
```
Server address: 10.244.0.7:80
Server address: 10.244.0.8:80
Server address: 10.244.0.7:80
Server address: 10.244.0.9:80
Server address: 10.244.0.8:80
```

**ServiceがラベルセレクタでPodを見つけ、ラウンドロビンで負荷分散している**

---

## Part 8：Endpointsの確認

### Serviceがどのように動いているか

```bash
# Endpointsを確認
kubectl get endpoints nginx-service
```

**結果例**:
```
NAME            ENDPOINTS                                      AGE
nginx-service   10.244.0.7:80,10.244.0.8:80,10.244.0.9:80     2m
```

**Endpoints = Serviceが転送する先のPodのIPアドレス一覧**

### Podを削除するとEndpointsも変わる

```bash
# Podを1つ削除
kubectl delete pod nginx-deployment-xxxxx-xxxxx

# すぐに確認
kubectl get endpoints nginx-service
```

新しいPodが作成されると、Endpointsも自動的に更新される。

---

## ネットワーク構成図

```
┌─────────────────────────────────────────────────┐
│ Kubernetes Cluster (minikube)                   │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │ Namespace: default                       │  │
│  │                                          │  │
│  │  [Service: nginx-service]               │  │
│  │  Type: ClusterIP                        │  │
│  │  ClusterIP: 10.96.123.45                │  │
│  │  DNS: nginx-service.default.svc         │  │
│  │                                          │  │
│  │         ↓ (selector: app=nginx)         │  │
│  │                                          │  │
│  │  ┌─────────────────────────────────┐    │  │
│  │  │ Deployment: nginx-deployment    │    │  │
│  │  │ Replicas: 3                     │    │  │
│  │  │                                 │    │  │
│  │  │  [Pod1]     [Pod2]     [Pod3]  │    │  │
│  │  │  IP: .7     IP: .8     IP: .9  │    │  │
│  │  │  Port: 80   Port: 80   Port: 80│    │  │
│  │  └─────────────────────────────────┘    │  │
│  │                                          │  │
│  │  [Pod-B]                                 │  │
│  │  IP: 10.244.0.5                          │  │
│  │  → wget nginx-service                    │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  [CoreDNS]                                      │
│  - 名前解決サービス                              │
│  - nginx-service → 10.96.123.45                │
└─────────────────────────────────────────────────┘

外部（あなたのブラウザ）
    ↓ (NodePort: 30080の場合)
minikube Node IP: 192.168.49.2:30080
```

---

## まとめ

### Kubernetesネットワークの基本

1. **Pod間通信**
   - 全てのPodは固有のIPを持つ
   - Pod同士は直接通信可能
   - でもPodのIPは変わる → 直接使わない

2. **Service**
   - 固定のClusterIPとDNS名を提供
   - ラベルセレクタでPodを見つける
   - 複数Podへ負荷分散

3. **DNS**
   - `<service名>.<namespace>.svc.cluster.local`
   - 同じNamespaceなら短縮形でアクセス可能

4. **Serviceの種類**
   - **ClusterIP**: 内部のみ
   - **NodePort**: ノードのポートで外部公開
   - **LoadBalancer**: クラウドのLB使用

5. **ポートの3段階**
   - nodePort: ノードのポート
   - port: Serviceのポート
   - targetPort: Podのポート

---

## クリーンアップ

```bash
kubectl delete pod pod-a
kubectl delete pod pod-b
kubectl delete svc service-a
kubectl delete svc service-a-nodeport
kubectl delete deployment nginx-deployment
kubectl delete svc nginx-service
```

---

## 次のステップ

- **Ingress**: HTTP/HTTPSルーティング（複数Serviceを1つのIPで公開）
- **Network Policy**: Pod間通信の制御（ファイアウォール）
- **Service Mesh**: より高度なトラフィック管理（Istio、Linkerd）

---

**作成日**: 2026-05-11
**目的**: Kubernetesのネットワークの仕組みを実践的に理解する
