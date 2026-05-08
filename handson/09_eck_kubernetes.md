# ハンズオン⑨：ECK（Elastic Cloud on Kubernetes）で Elasticsearch を動かす

## 学習目標
- ECK とは何かを理解する
- kind でローカル Kubernetes クラスタを構築する
- ECK Operator をインストールする
- Elasticsearch・Kibana を Kubernetes 上にデプロイする
- Kibana にアクセスしてデータを確認する

## 学べる概念
- ✅ Kubernetes の基本（Pod / Deployment / Service / CRD）
- ✅ Operator パターン
- ✅ ECK（Elastic Cloud on Kubernetes）
- ✅ Elasticsearch / Kibana の基礎
- ✅ kubectl の操作

---

## 所要時間
約2時間（5ステップ）

## コスト
**無料**（すべてローカル環境で完結）

---

## 前提知識

### ECK とは？

**ECK** = **E**lastic **C**loud on **K**ubernetes（エラスティック・クラウド・オン・クーバネティス）

```
Elastic社が提供する Kubernetes Operator。
Elasticsearch・Kibana などの Elastic Stack を
Kubernetes 上で簡単に管理できる。
```

### Operator パターンとは？

```
通常の Kubernetes：
  人間が手動で Pod を管理・監視・修復

Operator パターン：
  専用のコントローラー（Operator）が
  自動で管理・監視・修復してくれる
```

💡 例え：自動掃除ロボット（ルンバ）が部屋を勝手に掃除してくれる

### Elasticsearch / Kibana とは？

| サービス | 役割 |
|---------|------|
| **Elasticsearch** | 大量データを高速検索できる検索エンジン |
| **Kibana** | Elasticsearch のデータを可視化するダッシュボード |

---

## 全体構成図

```
ローカルPC
└── kind（Kubernetes クラスタ）
    ├── ECK Operator（管理役）
    ├── Elasticsearch Pod
    └── Kibana Pod
             ↓
      ブラウザで Kibana にアクセス
```

---

## 必要なツール

| ツール | 用途 | インストール |
|--------|------|-----------|
| Docker Desktop | コンテナ実行環境 | 事前にインストール済みであること |
| kind | ローカル K8s クラスタ | Step 0 でインストール |
| kubectl | K8s 操作コマンド | Step 0 でインストール |

---

## Step 0：ツールのインストール（Mac）

### 0-1. Homebrew でインストール

```bash
# kubectl（クーブシーティーエル）
brew install kubectl

# kind（カインド）
brew install kind

# インストール確認
kubectl version --client
kind version
```

### 0-2. Docker Desktop が起動しているか確認

```bash
docker ps
```

エラーが出なければ OK。

---

## Step 1：kind でローカル Kubernetes クラスタを作成

### 1-1. kind とは？

**kind** = **K**ubernetes **in** **D**ocker

```
Docker コンテナの中に Kubernetes クラスタを作る
→ 本番環境を壊さずローカルで練習できる
```

### 1-2. クラスタ設定ファイルを作成

```bash
mkdir ~/eck-handson && cd ~/eck-handson
```

`kind-config.yaml` を作成：

```yaml
apiVersion: kind.x-k8s.io/v1alpha4
kind: Cluster
name: eck-cluster
nodes:
  - role: control-plane
  - role: worker
  - role: worker
```

### 1-3. クラスタを作成

```bash
kind create cluster --config kind-config.yaml
```

完了まで約3分。

```
Creating cluster "eck-cluster" ...
 ✓ Ensuring node image (kindest/node:v1.31.0) 🖼
 ✓ Preparing nodes 📦 📦 📦
 ✓ Writing configuration 📜
 ✓ Starting control-plane 🕹️
 ✓ Installing CNI 🔌
 ✓ Installing StorageClass 💾
 ✓ Joining worker nodes 🚜
Set kubectl context to "kind-eck-cluster"
```

### 1-4. クラスタを確認

```bash
kubectl get nodes
```

```
NAME                        STATUS   ROLES           AGE
eck-cluster-control-plane   Ready    control-plane   2m
eck-cluster-worker          Ready    <none>          2m
eck-cluster-worker2         Ready    <none>          2m
```

✅ 3つの Node が `Ready` になっていれば OK

---

## Step 2：ECK Operator をインストール

### 2-1. CRD（カスタムリソース定義）をインストール

**CRD** = Custom Resource Definition（カスタム・リソース・デフィニション）

```
Kubernetes はデフォルトで Pod / Service / Deployment を知っている。
CRD を追加すると「Elasticsearch」「Kibana」も
Kubernetes のリソースとして扱えるようになる。
```

```bash
kubectl create -f https://download.elastic.co/downloads/eck/2.14.0/crds.yaml
```

### 2-2. ECK Operator をインストール

```bash
kubectl apply -f https://download.elastic.co/downloads/eck/2.14.0/operator.yaml
```

### 2-3. Operator の起動を確認

```bash
kubectl -n elastic-system get pods --watch
```

```
NAME                 READY   STATUS    RESTARTS
elastic-operator-0   1/1     Running   0
```

`Running` になったら `Ctrl+C` で終了。

---

## Step 3：Elasticsearch をデプロイ

### 3-1. Elasticsearch マニフェストを作成

`elasticsearch.yaml` を作成：

```yaml
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: quickstart
spec:
  version: 8.15.0
  nodeSets:
    - name: default
      count: 1                   # Node 数（本番では3以上推奨）
      config:
        node.store.allow_mmap: false
      podTemplate:
        spec:
          containers:
            - name: elasticsearch
              resources:
                requests:
                  memory: 1Gi
                  cpu: 500m
                limits:
                  memory: 2Gi
```

### 3-2. デプロイ

```bash
kubectl apply -f elasticsearch.yaml
```

### 3-3. 起動を確認（3〜5分かかる）

```bash
kubectl get elasticsearch --watch
```

```
NAME         HEALTH   NODES   VERSION   PHASE
quickstart   green    1       8.15.0    Ready
```

`HEALTH: green`・`PHASE: Ready` になれば完了。

### 3-4. 🎯 学習ポイント：Kubernetes の自動修復を体験

Pod を強制削除してみる：

```bash
# Pod 名を確認
kubectl get pods -l elasticsearch.k8s.elastic.co/cluster-name=quickstart

# Pod を削除
kubectl delete pod quickstart-es-default-0
```

→ **ECK Operator が自動で Pod を再作成する！**

```bash
kubectl get pods --watch
# 数十秒で新しい Pod が起動する
```

これが **Operator パターン** の自動修復。

---

## Step 4：Kibana をデプロイ

### 4-1. Kibana マニフェストを作成

`kibana.yaml` を作成：

```yaml
apiVersion: kibana.k8s.elastic.co/v1
kind: Kibana
metadata:
  name: quickstart
spec:
  version: 8.15.0
  count: 1
  elasticsearchRef:
    name: quickstart        # 先ほど作った Elasticsearch を参照
  podTemplate:
    spec:
      containers:
        - name: kibana
          resources:
            requests:
              memory: 512Mi
              cpu: 250m
            limits:
              memory: 1Gi
```

### 4-2. デプロイ

```bash
kubectl apply -f kibana.yaml
```

### 4-3. 起動を確認

```bash
kubectl get kibana --watch
```

```
NAME         HEALTH   NODES   VERSION
quickstart   green    1       8.15.0
```

---

## Step 5：Kibana にアクセス

### 5-1. パスワードを取得

ECK は自動で `elastic` ユーザーのパスワードを生成し、Secret に保存する。

```bash
kubectl get secret quickstart-es-elastic-user \
  -o go-template='{{.data.elastic | base64decode}}'
```

メモしておく（例：`abc123xyz`）

### 5-2. ポートフォワードを設定

```bash
kubectl port-forward service/quickstart-kb-http 5601
```

### 5-3. ブラウザでアクセス

```
https://localhost:5601
```

⚠️ 証明書の警告が出たら「詳細設定」→「アクセスする」を選択

### 5-4. ログイン

- ユーザー名：`elastic`
- パスワード：Step 5-1 で取得したもの

✅ Kibana ダッシュボードが表示されれば成功！

---

## Step 6：Elasticsearch にデータを投入してみる（応用）

### 6-1. Elasticsearch の URL を確認

```bash
kubectl port-forward service/quickstart-es-http 9200 &
```

### 6-2. パスワードを変数に保存

```bash
PASSWORD=$(kubectl get secret quickstart-es-elastic-user \
  -o go-template='{{.data.elastic | base64decode}}')
```

### 6-3. データを投入（curl）

```bash
# インデックスにドキュメントを追加
curl -k -u "elastic:$PASSWORD" \
  -X POST "https://localhost:9200/my-index/_doc" \
  -H "Content-Type: application/json" \
  -d '{"name": "田中太郎", "age": 25, "city": "東京"}'
```

### 6-4. 検索してみる

```bash
curl -k -u "elastic:$PASSWORD" \
  "https://localhost:9200/my-index/_search?pretty"
```

### 6-5. Kibana で可視化

1. Kibana → 「Discover」
2. インデックスパターン `my-index` を作成
3. データが表示される！

---

## 🧹 後片付け

```bash
# Kibana・Elasticsearch を削除
kubectl delete -f kibana.yaml
kubectl delete -f elasticsearch.yaml

# kind クラスタを削除
kind delete cluster --name eck-cluster
```

---

## 🎓 学習ポイントまとめ

### Kubernetes の主要リソース

| リソース | 役割 |
|---------|------|
| **Pod** | コンテナの最小単位 |
| **Deployment** | Pod の管理・スケール |
| **Service** | Pod へのネットワークアクセス |
| **CRD** | カスタムリソースの定義 |
| **Secret** | パスワード等の機密情報 |

### ECK のアーキテクチャ

```
kubectl apply -f elasticsearch.yaml
         ↓
ECK Operator が検知
         ↓
Elasticsearch の Pod・Service・Secret を自動作成
         ↓
障害が起きたら自動修復
```

### Operator パターンのメリット

```
✅ 複雑なステートフルアプリを Kubernetes で管理できる
✅ 障害時に自動修復
✅ スケールアップ/ダウンが宣言的に行える
✅ バージョンアップも自動化できる
```

---

## ✅ チェックリスト

- [ ] kind でローカル Kubernetes クラスタを作成した
- [ ] ECK Operator をインストールした
- [ ] Elasticsearch をデプロイして `HEALTH: green` を確認した
- [ ] Pod 削除 → 自動再作成を体験した（Operator パターン）
- [ ] Kibana をデプロイしてブラウザからアクセスした
- [ ] Elasticsearch にデータを投入・検索した
- [ ] クラスタを削除した（後片付け）

---

## 💡 さらに発展させるには

### マルチノード Elasticsearch

```yaml
nodeSets:
  - name: master
    count: 3          # master node を3台に
  - name: data
    count: 3          # data node を3台に
```

### Logstash と連携

```
アプリログ → Logstash（加工） → Elasticsearch → Kibana
```

### AWS EKS 上で動かす

```
kind（ローカル）→ EKS（本番）に移行
マニフェストはほぼそのまま使える
```

---

## 次のステップ

- → ArgoCD との連携（GitOps で ECK を管理）
- → Prometheus + Grafana でメトリクス監視
- → AWS EKS 上に ECK を構築する
