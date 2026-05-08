# ハンズオン⑩：AWS EKS（Elastic Kubernetes Service）入門

## 学習目標
- EKS とは何かを理解する
- AWSコンソールからクラスタを構築する
- Deployment・Service をデプロイする
- LoadBalancer でインターネット公開する

## 学べる概念
- ✅ EKS（Elastic Kubernetes Service）
- ✅ ノードグループ（EC2）
- ✅ IAM ロールと Kubernetes の連携
- ✅ LoadBalancer Service（ELB）
- ✅ kubectl の基本操作

---

## 所要時間
約2〜3時間

## コスト
⚠️ **有料！使い終わったら必ず削除**
- EKS クラスタ：$0.10/時間（約15円/時間）
- EC2 ノード（t3.medium x2）：約$0.08/時間 x2
- **放置すると1日で約500円かかる**

---

## kind と EKS の違い

| | kind | EKS |
|--|------|-----|
| 場所 | **ローカルPC** | **AWS クラウド** |
| コスト | 無料 | 有料 |
| 用途 | 学習・開発 | **本番環境** |
| スケール | PC のスペック次第 | ほぼ無制限 |
| 可用性 | PCが落ちたら終わり | **マルチAZ対応** |

---

## 全体構成図

```
あなたのPC（kubectl）
       ↓ コマンド送信
  EKS コントロールプレーン（AWS管理）
       ↓ 指示
  ┌──────────────────────────────┐
  │  VPC                         │
  │  ├── AZ-a: EC2 Node          │
  │  └── AZ-c: EC2 Node          │
  └──────────────────────────────┘
       ↓
  ELB（LoadBalancer）
       ↓
  インターネット
```

---

## Step 0：事前準備（kubectl のインストール）

GUIでクラスタを作った後、**操作は kubectl（コマンド）** で行う。

```bash
# Mac
brew install kubectl

# 確認
kubectl version --client
```

---

## Step 1：IAM ロールを作成

EKS はクラスタとノードに IAM ロールが必要。

### 1-1. クラスタ用 IAM ロール

1. AWSコンソール → 「**IAM**」
2. 左メニュー「ロール」→「**ロールを作成**」
3. 「**AWSのサービス**」→「**EKS**」→「**EKS - Cluster**」
4. 「次へ」→「次へ」
5. ロール名：`eks-cluster-role`
6. 「ロールを作成」

### 1-2. ノード用 IAM ロール

1. 「ロールを作成」
2. 「**EC2**」を選択
3. 以下の3つのポリシーをアタッチ：
   - `AmazonEKSWorkerNodePolicy`
   - `AmazonEKS_CNI_Policy`
   - `AmazonEC2ContainerRegistryReadOnly`
4. ロール名：`eks-node-role`
5. 「ロールを作成」

---

## Step 2：EKS クラスタを作成

### 2-1. EKS コンソールへ

1. AWSコンソールで「**EKS**」を検索
2. 「**クラスターを作成**」をクリック

### 2-2. クラスタの設定

| 項目 | 設定値 |
|------|--------|
| クラスタ名 | `my-eks-cluster` |
| Kubernetes バージョン | 最新版 |
| クラスタサービスロール | `eks-cluster-role` |

「次へ」

### 2-3. ネットワーク設定

| 項目 | 設定値 |
|------|--------|
| VPC | デフォルト VPC |
| サブネット | 複数AZのサブネットを選択 |
| セキュリティグループ | デフォルト |
| クラスターエンドポイントアクセス | **パブリック** |

「次へ」→「次へ」→「作成」

⚠️ 作成完了まで **10〜15分** かかる

### 2-4. 作成完了を確認

ステータスが「**アクティブ**」になれば OK

---

## Step 3：ノードグループを追加

クラスタができても、まだ Pod が動く EC2 がない。ノードグループを追加する。

### 3-1. ノードグループの作成

1. 作成したクラスタをクリック
2. 「**コンピューティング**」タブ
3. 「**ノードグループを追加**」

### 3-2. 設定

| 項目 | 設定値 |
|------|--------|
| 名前 | `ng-1` |
| ノードの IAM ロール | `eks-node-role` |

「次へ」

| 項目 | 設定値 |
|------|--------|
| AMI タイプ | Amazon Linux 2 |
| インスタンスタイプ | `t3.medium` |
| 希望するサイズ | `2`（台数） |
| 最小サイズ | `1` |
| 最大サイズ | `3` |

「次へ」→「次へ」→「作成」

⚠️ ノード作成まで **3〜5分** かかる

---

## Step 4：kubectl をクラスタに接続

### 4-1. kubeconfig を更新

```bash
aws eks update-kubeconfig \
  --region ap-northeast-1 \
  --name my-eks-cluster
```

### 4-2. ノードを確認

```bash
kubectl get nodes
```

```
NAME                                              STATUS   AGE
ip-192-168-1-10.ap-northeast-1.compute.internal  Ready    3m
ip-192-168-1-20.ap-northeast-1.compute.internal  Ready    3m
```

✅ 2台が `Ready` になれば成功

---

## Step 5：Nginx をデプロイ

### 5-1. Deployment を作成

`nginx-deployment.yaml`：

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
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
          image: nginx:1.25
          ports:
            - containerPort: 80
```

```bash
kubectl apply -f nginx-deployment.yaml
kubectl get pods
```

### 5-2. LoadBalancer Service を作成

`nginx-service.yaml`：

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
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
```

### 5-3. ELB の URL を確認

```bash
kubectl get service nginx-service
```

`EXTERNAL-IP` に URL が表示されるまで2〜3分待つ。

### 5-4. ブラウザでアクセス

```
http://[EXTERNAL-IPのURL]
```

✅ Nginx のページが表示されれば成功！

### 5-5. コンソールでも確認できる

EC2 コンソール → 「ロードバランサー」
→ EKS が自動で作成した ELB が表示されている

---

## Step 6：スケールを体験

### コマンドで増減

```bash
# 6台に増やす
kubectl scale deployment nginx-deployment --replicas=6

# 確認
kubectl get pods

# 2台に戻す
kubectl scale deployment nginx-deployment --replicas=2
```

### コンソールでも確認

EKS コンソール → クラスタ → 「ワークロード」タブ
→ Deployment の状態が確認できる

---

## 🧹 後片付け（必須・課金防止）

### 順番通りに削除する

```bash
# Service を削除（ELB も自動削除）
kubectl delete -f nginx-service.yaml
kubectl delete -f nginx-deployment.yaml
```

### コンソールでクラスタを削除

1. EKS コンソール → クラスタを選択
2. 「**コンピューティング**」タブ → ノードグループを選択 → 「**削除**」
3. ノードグループの削除完了を待つ（5分）
4. クラスタを選択 → 「**削除**」→ クラスタ名を入力して削除

### IAM ロールを削除

1. IAM コンソール → ロール
2. `eks-cluster-role` を削除
3. `eks-node-role` を削除

⚠️ **削除完了を必ず確認する！**

---

## ✅ チェックリスト

- [ ] IAM ロールを2つ作成した
- [ ] EKS クラスタを作成した（コンソール）
- [ ] ノードグループを追加した（EC2 x2）
- [ ] kubectl をクラスタに接続した
- [ ] Nginx をデプロイした
- [ ] LoadBalancer でインターネット公開した
- [ ] スケールアップ・ダウンを体験した
- [ ] **ノードグループ・クラスタ・IAMロールを削除した（課金防止）**

---

## 🎯 CCP 試験で問われるポイント

| 問題例 | 答え |
|--------|------|
| マネージド Kubernetes サービスは？ | **EKS** |
| コンテナ管理サービスは？（K8s 以外） | **ECS** |
| サーバーレスコンテナ実行は？ | **Fargate** |
| K8s のコントロールプレーンを管理するのは？ | **AWS（EKSの場合）** |

---

## 次のステップ
- → ECK on EKS（Elasticsearch を EKS 上で動かす）
- → Fargate でサーバーレスコンテナ
- → ArgoCD で GitOps を実践
- → HPA（水平自動スケール）を設定する
