# ハンズオン⑮：Kubernetes基礎完全マスター（Phase 3準備）

**ファイルパス**: `/Users/k24032kk/AWS_CCP/handson-kubernetes/15_kubernetes_fundamentals_handson.md`

**目的**: Phase 3（EKS検証環境構築）に必要なKubernetes基礎を実践的に習得する

**所要時間**: 約4-5時間

**前提条件**:
- minikubeがインストール済み
- kubectlがインストール済み

---

## 事前準備

### minikubeを起動

```bash
# minikube起動
minikube start

# バージョン確認
kubectl version --short

# クラスタ情報確認
kubectl cluster-info
```

**期待される結果**:
```
Kubernetes control plane is running at https://192.168.49.2:8443
CoreDNS is running at https://192.168.49.2:8443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

---

## Part 1：Pod の基礎

### 1-1：Podとは何か

**Pod（ポッド）**:
- Kubernetesの**最小デプロイ単位**
- 1つ以上のコンテナをまとめたもの
- 固有のIPアドレスを持つ
- コンテナ間でネットワークとストレージを共有

**なぜPodが必要？**
- コンテナだけでは不十分（Kubernetesがコンテナを直接管理しない）
- 複数の密結合コンテナを1つの単位として扱える
- ネットワーク・ストレージの共有が簡単

### 1-2：Pod YAMLを書く

`nginx-pod.yaml` を作成します。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
  # nginxをインスト＝る
    image: nginx:latest
    ports:
    - containerPort: 80
    resources:
    # 最低限保証されるリソース
      requests:
      # 10%のCPUを使用する mac m2は８コア 1000m*8 データ処理
        cpu: 100m
      # データ保存
        memory: 128Mi
      limits:
      # podが使えるリソースの限界
      # 処理が遅くなるが、podは動き続ける　処理が遅くなるだけ
        cpu: 200m
        # 超えたらOOM(out of memory)停止する
        memory: 256Mi
```

**YAMLの構造**:

| フィールド | 説明 |
|-----------|------|
| `apiVersion` | 使用するKubernetes APIのバージョン |
| `kind` | リソースの種類（Pod, Deployment, Serviceなど） |
| `metadata` | 名前、ラベル、アノテーション |
| `spec` | リソースの詳細設定 |

**リソース制限**:
- `requests`: 最低限必要なリソース（スケジューリングに使用）
- `limits`: 最大使用可能リソース（超えると制限される）

### 1-3：Podを作成・確認

```bash
# Podを作成
kubectl apply -f nginx-pod.yaml

# Podを確認
kubectl get pods

# 詳細情報を確認
kubectl get pods -o wide

# Podの詳細を確認
kubectl describe pod nginx-pod
```

**結果例**:
```
NAME        READY   STATUS    RESTARTS   AGE   IP           NODE
nginx-pod   1/1     Running   0          10s   10.244.0.4   minikube
```

### 1-4：Podのライフサイクル

**Podのステータス**:

| Status | 説明 |
|--------|------|
| `Pending` | スケジューリング待ち、イメージダウンロード中 |
| `Running` | 正常に実行中 |
| `Succeeded` | 正常終了（バッチ処理など） |
| `Failed` | エラーで終了 |
| `Unknown` | ノードとの通信エラー |

```bash
# Podのログを確認
kubectl logs nginx-pod

# Podの中でコマンド実行
kubectl exec nginx-pod -- nginx -v

# Podの中に入る（インタラクティブ）
kubectl exec -it nginx-pod -- /bin/bash
# コンテナ内で
curl localhost
exit
```

### 1-5：Podを削除

```bash
# Podを削除
kubectl delete pod nginx-pod

# 削除確認
kubectl get pods
# 結果: No resources found
```

**重要**: Podを直接作成すると、削除されたら終わり（自動復旧しない）

---

## Part 2：Deployment の基礎

### 2-1：Deploymentとは何か

**Deployment（デプロイメント）**:
- 複数のPodを管理する
- レプリカ数を指定できる
- **セルフヒーリング**：Podが死んだら自動で再作成
- **ローリングアップデート**：ダウンタイムなしで更新

**PodとDeploymentの違い**:

| | Pod | Deployment |
|---|-----|------------|
| 自動復旧 | ❌ なし | ✅ あり |
| レプリカ管理 | ❌ なし | ✅ あり |
| ローリングアップデート | ❌ なし | ✅ あり |
| 本番利用 | ❌ 非推奨 | ✅ 推奨 |

### 2-2：Deployment YAMLを書く

`nginx-deployment.yaml` を作成します。

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
```

**重要なフィールド**:

| フィールド | 説明 |
|-----------|------|
| `replicas` | Podの数 |
| `selector.matchLabels` | 管理するPodを選択するラベル |
| `template` | Podの雛形（Pod定義と同じ） |

**ラベルとセレクタの関係**:
```
Deployment
  ↓ selector.matchLabels: app=nginx
[Pod1] app=nginx
[Pod2] app=nginx
[Pod3] app=nginx
```

### 2-3：Deploymentを作成

```bash
# Deploymentを作成
kubectl apply -f nginx-deployment.yaml

# Deploymentを確認
kubectl get deployments

# Podを確認（3個作成される）
kubectl get pods

# 詳細情報
kubectl get pods -o wide
```

**結果例**:
```
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-6d6f487f8d-abcde   1/1     Running   0          10s
nginx-deployment-6d6f487f8d-fghij   1/1     Running   0          10s
nginx-deployment-6d6f487f8d-klmno   1/1     Running   0          10s
```

**Pod名の形式**: `<deployment名>-<replicaset-hash>-<random>`

### 2-4：セルフヒーリングを確認

```bash
# Podを1つ削除
kubectl delete pod nginx-deployment-6d6f487f8d-abcde

# すぐにPodを確認
kubectl get pods
```

**結果**:
```
NAME                                READY   STATUS              RESTARTS   AGE
nginx-deployment-6d6f487f8d-fghij   1/1     Running             0          2m
nginx-deployment-6d6f487f8d-klmno   1/1     Running             0          2m
nginx-deployment-6d6f487f8d-pqrst   0/1     ContainerCreating   0          1s  ← 新しいPodが自動作成
```

**Deploymentが自動的に新しいPodを作成して、常に3個を維持する**

### 2-5：Deploymentをスケールする

```bash
# レプリカ数を5に増やす
kubectl scale deployment nginx-deployment --replicas=5

# Podを確認
kubectl get pods

# レプリカ数を2に減らす
kubectl scale deployment nginx-deployment --replicas=2

# Podを確認（3個が削除される）
kubectl get pods
```

### 2-6：Deploymentを更新する

```bash
# nginxのイメージを1.21 → 1.22に更新
kubectl set image deployment/nginx-deployment nginx=nginx:1.22

# ローリングアップデートの様子を確認
kubectl rollout status deployment/nginx-deployment

# 更新履歴を確認
kubectl rollout history deployment/nginx-deployment
```

**ローリングアップデート**:
```
1. 新しいバージョンのPodを1つ作成
2. 古いPodを1つ削除
3. 繰り返し（ダウンタイムなし）
```

### 2-7：Deploymentをロールバックする

```bash
# 1つ前のバージョンに戻す
kubectl rollout undo deployment/nginx-deployment

# ステータス確認
kubectl rollout status deployment/nginx-deployment

# イメージバージョン確認
kubectl describe deployment nginx-deployment | grep Image
# 結果: Image: nginx:1.21 (戻った)
```

---

## Part 3：Service の基礎

### 3-1：Serviceとは何か

**Service（サービス）**:
- Podへの**固定アクセスポイント**
- **固定IP**と**DNS名**を提供
- 複数Podへ**負荷分散**

**なぜServiceが必要？**
- PodのIPアドレスは変わる（再作成されるたび）
- 複数Podに対して1つのアクセスポイントが欲しい
- DNS名でアクセスしたい

### 3-2：Service の種類

| Type | 説明 | 用途 |
|------|------|------|
| **ClusterIP** | クラスタ内部のみアクセス可能 | DB、内部API |
| **NodePort** | ノードのポートで外部公開 | 開発環境 |
| **LoadBalancer** | クラウドのLBで外部公開 | 本番環境（AWS ELB） |

### 3-3：ClusterIP Serviceを作成

`nginx-service-clusterip.yaml` を作成します。

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: ClusterIP
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
```

**ポートの説明**:
- `port`: Serviceのポート（他のPodからアクセスするポート）
- `targetPort`: Podのポート（コンテナが待ち受けているポート）

```bash
# Serviceを作成
kubectl apply -f nginx-service-clusterip.yaml

# Serviceを確認
kubectl get svc nginx-service
```

**結果例**:
```
NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
nginx-service   ClusterIP   10.96.123.45    <none>        80/TCP    5s
```

### 3-4：ServiceとPodの接続を確認

**ラベルセレクタの仕組み**:
```
Service (selector: app=nginx)
    ↓
[Pod1] app=nginx ✅
[Pod2] app=nginx ✅
[Pod3] app=other ❌ (選ばれない)
```

```bash
# Endpointsを確認（Serviceが転送する先のPodのIP）
kubectl get endpoints nginx-service
```

**結果例**:
```
NAME            ENDPOINTS                                      AGE
nginx-service   10.244.0.7:80,10.244.0.8:80                   1m
```

### 3-5：ServiceのIPでアクセス

テスト用Podを作成します。

```bash
# テスト用Podを作成（busybox）
kubectl run test-pod --image=busybox:latest --command -- sleep 3600

# test-podからServiceのIPでアクセス
kubectl exec test-pod -- wget -qO- 10.96.123.45
```

**結果**: Nginxのデフォルトページが表示される

```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
```

### 3-6：ServiceのDNS名でアクセス

**Kubernetes の内部DNS**:
- 全てのServiceに自動的にDNS名が割り当てられる
- 形式: `<service名>.<namespace>.svc.cluster.local`

```bash
# DNS名でアクセス（完全形）
kubectl exec test-pod -- wget -qO- nginx-service.default.svc.cluster.local

# DNS名でアクセス（短縮形、同じNamespaceなら）
kubectl exec test-pod -- wget -qO- nginx-service
```

**どちらも成功！**

### 3-7：負荷分散を確認

```bash
# 何度もアクセスして、異なるPodに振り分けられることを確認
kubectl exec test-pod -- sh -c 'for i in 1 2 3 4 5; do wget -qO- nginx-service | grep "Server address"; done'
```

**結果例**:
```
Server address: 10.244.0.7:80
Server address: 10.244.0.8:80
Server address: 10.244.0.7:80
Server address: 10.244.0.8:80
Server address: 10.244.0.7:80
```

**Serviceがラウンドロビンで複数Podに負荷分散している**

### 3-8：NodePort Serviceを作成

`nginx-service-nodeport.yaml` を作成します。

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-nodeport
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
    nodePort: 30080
```

```bash
# NodePort Serviceを作成
kubectl apply -f nginx-service-nodeport.yaml

# Serviceを確認
kubectl get svc nginx-nodeport
```

**結果例**:
```
NAME             TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
nginx-nodeport   NodePort   10.96.200.10    <none>        80:30080/TCP   5s
```

### 3-9：NodePortで外部からアクセス

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
minikube service nginx-nodeport
```

**ブラウザでNginxのページが表示される！**

### 3-10：ポートの3段階を理解

**通信の流れ**:
```
ブラウザ
    ↓
③ nodePort: 30080（ノードの30080番ポート）
    ↓
① port: 80（Serviceの80番ポート）
    ↓
② targetPort: 80（Podの80番ポート）
    ↓
コンテナのNginx
```

---

## Part 4：2つのPod間でService経由通信

### 4-1：2つのPodを作成

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

```bash
# 2つのPodを作成
kubectl apply -f pod-a.yaml
kubectl apply -f pod-b.yaml

# PodのIPを確認
kubectl get pods -o wide
```

**結果例**:
```
NAME    READY   STATUS    RESTARTS   AGE   IP
pod-a   1/1     Running   0          10s   10.244.0.10
pod-b   1/1     Running   0          5s    10.244.0.11
```

### 4-2：Pod-AにServiceを作成

`service-a.yaml` を作成します。

```yaml
apiVersion: v1
kind: Service
metadata:
  name: service-a
spec:
  type: ClusterIP
  selector:
    app: pod-a
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
```

```bash
# Serviceを作成
kubectl apply -f service-a.yaml

# Serviceを確認
kubectl get svc service-a
```

### 4-3：Pod-BからPod-AにService経由でアクセス

```bash
# ServiceのIPでアクセス
kubectl exec pod-b -- wget -qO- service-a

# DNS名でアクセス
kubectl exec pod-b -- wget -qO- service-a.default.svc.cluster.local
```

**どちらも成功！** Nginxのページが表示される

### 4-4：Pod-Aを削除→再作成してもアクセスできる

```bash
# Pod-Aを削除
kubectl delete pod pod-a

# 再作成（IPが変わる）
kubectl apply -f pod-a.yaml

# PodのIPを確認（変わっている）
kubectl get pods -o wide
# 例: pod-a のIPが 10.244.0.10 → 10.244.0.12

# でもServiceのDNS名でアクセスできる
kubectl exec pod-b -- wget -qO- service-a
```

**成功！** ServiceがPodのIPアドレス変更を吸収してくれる

---

## Part 5：ConfigMap の基礎

### 5-1：ConfigMapとは何か

**ConfigMap（コンフィグマップ）**:
- **設定を外部化**する
- 環境変数やファイルとしてPodにマウント
- 設定変更時にイメージを再ビルド不要

**用途**:
- データベース接続情報（ホスト名、ポート）
- アプリケーション設定
- 環境ごとの設定（dev, staging, prod）

### 5-2：ConfigMapを作成（YAML）

`app-config.yaml` を作成します。

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  database_host: "postgres-service"
  database_port: "5432"
  app_mode: "production"
  config.properties: |
    app.name=MyApp
    app.version=1.0
    app.debug=false
```

```bash
# ConfigMapを作成
kubectl apply -f app-config.yaml

# ConfigMapを確認
kubectl get configmap app-config

# ConfigMapの内容を確認
kubectl describe configmap app-config
```

### 5-3：ConfigMapをコマンドで作成

```bash
# キーバリュー形式で作成
kubectl create configmap my-config \
  --from-literal=database_host=postgres-service \
  --from-literal=database_port=5432

# ファイルから作成
echo "app.name=MyApp" > config.properties
kubectl create configmap file-config --from-file=config.properties

# 確認
kubectl get configmap
```

### 5-4：ConfigMapを環境変数としてPodで使用

`pod-with-configmap-env.yaml` を作成します。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod-env
spec:
  containers:
  - name: busybox
    image: busybox:latest
    command: ['sh', '-c', 'echo "DB Host: $DATABASE_HOST"; echo "DB Port: $DATABASE_PORT"; sleep 3600']
    env:
    - name: DATABASE_HOST
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: database_host
    - name: DATABASE_PORT
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: database_port
```

```bash
# Podを作成
kubectl apply -f pod-with-configmap-env.yaml

# ログを確認（環境変数が設定されている）
kubectl logs app-pod-env
```

**結果**:
```
DB Host: postgres-service
DB Port: 5432
```

### 5-5：ConfigMapをファイルとしてPodにマウント

`pod-with-configmap-volume.yaml` を作成します。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod-volume
spec:
  containers:
  - name: busybox
    image: busybox:latest
    command: ['sh', '-c', 'cat /etc/config/config.properties; sleep 3600']
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
  volumes:
  - name: config-volume
    configMap:
      name: app-config
      items:
      - key: config.properties
        path: config.properties
```

```bash
# Podを作成
kubectl apply -f pod-with-configmap-volume.yaml

# ログを確認（ファイルの内容が表示される）
kubectl logs app-pod-volume
```

**結果**:
```
app.name=MyApp
app.version=1.0
app.debug=false
```

---

## Part 6：Secret の基礎

### 6-1：Secretとは何か

**Secret（シークレット）**:
- **機密情報**を管理する
- パスワード、APIキー、証明書など
- ConfigMapとの違い：Base64エンコードされる

**注意**: 暗号化ではない（Base64はエンコード）

### 6-2：Secretを作成（YAML）

`db-secret.yaml` を作成します。

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
type: Opaque
data:
  username: cG9zdGdyZXM=        # postgres をBase64エンコード
  password: bXlwYXNzd29yZDEyMw==  # mypassword123 をBase64エンコード
```

**Base64エンコード方法**:
```bash
# エンコード
echo -n "postgres" | base64
# 結果: cG9zdGdyZXM=

echo -n "mypassword123" | base64
# 結果: bXlwYXNzd29yZDEyMw==

# デコード（確認用）
echo "cG9zdGdyZXM=" | base64 -d
# 結果: postgres
```

```bash
# Secretを作成
kubectl apply -f db-secret.yaml

# Secretを確認
kubectl get secret db-secret

# Secretの内容を確認（値は隠される）
kubectl describe secret db-secret
```

### 6-3：Secretをコマンドで作成（推奨）

```bash
# コマンドで作成（Base64エンコード不要）
kubectl create secret generic db-secret-2 \
  --from-literal=username=postgres \
  --from-literal=password=mypassword123

# 確認
kubectl get secret db-secret-2
```

### 6-4：Secretを環境変数としてPodで使用

`pod-with-secret-env.yaml` を作成します。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod-secret
spec:
  containers:
  - name: busybox
    image: busybox:latest
    command: ['sh', '-c', 'echo "User: $DB_USERNAME"; echo "Pass: $DB_PASSWORD"; sleep 3600']
    env:
    - name: DB_USERNAME
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: username
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: password
```

```bash
# Podを作成
kubectl apply -f pod-with-secret-env.yaml

# ログを確認
kubectl logs app-pod-secret
```

**結果**:
```
User: postgres
Pass: mypassword123
```

### 6-5：Secretをファイルとしてマウント

`pod-with-secret-volume.yaml` を作成します。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod-secret-volume
spec:
  containers:
  - name: busybox
    image: busybox:latest
    command: ['sh', '-c', 'cat /etc/secret/username; cat /etc/secret/password; sleep 3600']
    volumeMounts:
    - name: secret-volume
      mountPath: /etc/secret
      readOnly: true
  volumes:
  - name: secret-volume
    secret:
      secretName: db-secret
```

```bash
# Podを作成
kubectl apply -f pod-with-secret-volume.yaml

# ログを確認
kubectl logs app-pod-secret-volume
```

**結果**:
```
postgres
mypassword123
```

---

## Phase 3への準備完了チェック

以下のタスクが全て実行できたら、Level 1完了です。

### ✅ チェックリスト

- [ ] Podとは何か説明できる
- [ ] Pod YAMLを書いて作成できる
- [ ] PodのライフサイクルとStatusを理解している
- [ ] Deploymentとは何か、Podとの違いを説明できる
- [ ] Deployment YAMLを書いて3レプリカ作成できる
- [ ] Deploymentをスケール・更新・ロールバックできる
- [ ] Serviceとは何か、なぜ必要か説明できる
- [ ] Service の3種類（ClusterIP/NodePort/LoadBalancer）の違いを説明できる
- [ ] ClusterIP Serviceを作成してクラスタ内からアクセスできる
- [ ] NodePort Serviceを作成してブラウザからアクセスできる
- [ ] ServiceとPodの接続（ラベルセレクタ、Endpoints）を理解している
- [ ] ServiceのDNS名（短縮形・完全形）でアクセスできる
- [ ] 2つのPod間でService経由で通信できる
- [ ] ConfigMapを作成してPodで環境変数として使用できる
- [ ] ConfigMapをファイルとしてPodにマウントできる
- [ ] Secretを作成してPodで環境変数として使用できる
- [ ] SecretをファイルとしてPodにマウントできる

---

## クリーンアップ

```bash
# 全てのリソースを削除
kubectl delete deployment nginx-deployment
kubectl delete service nginx-service
kubectl delete service nginx-nodeport
kubectl delete service service-a
kubectl delete pod pod-a
kubectl delete pod pod-b
kubectl delete pod test-pod
kubectl delete pod app-pod-env
kubectl delete pod app-pod-volume
kubectl delete pod app-pod-secret
kubectl delete pod app-pod-secret-volume
kubectl delete configmap app-config
kubectl delete configmap my-config
kubectl delete configmap file-config
kubectl delete secret db-secret
kubectl delete secret db-secret-2

# 確認
kubectl get all
# 結果: service/kubernetes のみ残る（これは正常）
```

---

## Phase 3で使うスキル

このハンズオンで習得したスキルは、Phase 3で以下のように活用します：

| スキル | Phase 3での用途 |
|--------|----------------|
| **Deployment** | nginx Deployment（Web層）を作成 |
| **Service (ClusterIP)** | PostgreSQL Service（DB層）を作成 |
| **Service (LoadBalancer)** | nginx Service（ALB経由）を作成 |
| **ConfigMap** | PostgreSQL接続情報を管理 |
| **Secret** | PostgreSQLパスワードを管理 |
| **ラベルセレクタ** | ServiceとPodを接続 |
| **DNS名** | nginx → PostgreSQL 通信 |

---

## 次のステップ

- **Level 2**: StatefulSet、PVC、Ingress、HPA
- **参考ファイル**: `/Users/k24032kk/AWS_CCP/handson-kubernetes/16_kubernetes_intermediate_handson.md`（次回作成）

---

**作成日**: 2026-05-13
**目的**: Phase 3検証環境構築に必要なKubernetes基礎を実践的に習得
**所要時間**: 約4-5時間
