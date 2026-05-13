# ハンズオン⑫：ローカルKubernetes入門

## 学習目標
- Kubernetesの基本概念を理解する
- minikubeでローカルクラスターを構築する
- Pod、Deployment、Serviceを実際に作成する
- kubectlコマンドに慣れる

## 学べる概念
- ✅ Kubernetes（クーバネティス / クバネテス）
- ✅ minikube（ミニクーブ）
- ✅ kubectl（キューブシーティーエル / クーベコントロール）
- ✅ Pod（ポッド）
- ✅ Deployment（デプロイメント）
- ✅ Service（サービス）
- ✅ ReplicaSet（レプリカセット）

---

## 所要時間
約1.5時間

## コスト
**完全無料**（ローカル環境のみ）

---

## 📚 用語解説

### Kubernetes（クーバネティス）
```
語源：ギリシャ語の「κυβερνήτης（舵取り / 操舵手）」
英語：Kubernetes（K8s = K + ubernete（8文字）+ s）
読み：クーバネティス / クバネテス

意味：
コンテナを操縦する（管理する）システム
→ 大量のコンテナを自動で管理してくれる
```

### Pod（ポッド）
```
語源：英語の「pod（さや / 小集団）」
例：エンドウ豆のさや（pea pod）

意味：
コンテナをまとめる最小単位
→ 1つ以上のコンテナが入った「さや」
```

### Deployment（デプロイメント）
```
語源：英語の「deploy（配置する / 展開する）」
軍事用語：部隊を配置すること

意味：
Podを指定した数だけ展開・管理する仕組み
→ 「このアプリを3個展開して、常に3個維持して」
```

### Service（サービス）
```
語源：英語の「service（奉仕 / サービス）」

意味：
Podへのアクセス窓口
→ 内部でPodが入れ替わっても、固定のアドレスでアクセスできる
```

---

## 全体構成図

```
あなたのMac
┌────────────────────────────────────────────┐
│ minikube（Kubernetesクラスター）            │
│                                            │
│  ┌──────────────────────────────────────┐ │
│  │ Deployment: nginx-deployment         │ │
│  │                                      │ │
│  │  ┌─────────┐  ┌─────────┐           │ │
│  │  │ Pod 1   │  │ Pod 2   │           │ │
│  │  │ nginx   │  │ nginx   │           │ │
│  │  └─────────┘  └─────────┘           │ │
│  └──────────────────────────────────────┘ │
│             ↑                              │
│  ┌──────────────────────────────────────┐ │
│  │ Service: nginx-service               │ │
│  │ （アクセス窓口）                      │ │
│  └──────────────────────────────────────┘ │
│             ↑                              │
└─────────────┼──────────────────────────────┘
              │
         ブラウザでアクセス
```

---

## Part 1：環境構築

### Step 1：Homebrewのインストール確認

```bash
# Homebrewがインストールされているか確認
brew --version

# もしインストールされていなければ
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

---

### Step 2：Dockerのインストール確認

**minikubeはDockerを使ってKubernetesを動かします**

```bash
# Dockerがインストールされているか確認
docker --version

# もしインストールされていなければ
# Docker Desktopをダウンロード
https://www.docker.com/products/docker-desktop/

# インストール後、Docker Desktopを起動
```

---

### Step 3：minikubeのインストール

```bash
# minikubeをインストール
brew install minikube

# インストール確認
minikube version
# minikube version: v1.33.0
```

---

### Step 4：kubectlのインストール

```bash
# kubectlをインストール
brew install kubectl

# インストール確認
kubectl version --client
# Client Version: v1.30.0
```

---

### Step 5：minikubeクラスターを起動

```bash
# クラスターを起動（初回は数分かかる）
minikube start

# 出力例：
😄  minikube v1.33.0 on Darwin 14.0 (arm64)
✨  Automatically selected the docker driver
👍  Starting control plane node minikube in cluster minikube
🚜  Pulling base image ...
🔥  Creating docker container (CPUs=2, Memory=4000MB) ...
🐳  Preparing Kubernetes v1.30.0 on Docker 26.0.1 ...
🔗  Configuring bridge CNI (Container Networking Interface) ...
🔎  Verifying Kubernetes components...
🌟  Enabled addons: storage-provisioner, default-storageclass
🏄  Done! kubectl is now configured to use "minikube" cluster
```

---

### Step 6：クラスターの状態確認

```bash
# クラスターの状態確認
minikube status

# 出力：
minikube
type: Control Plane
host: Running       ← ホストが動いている
kubelet: Running    ← kubelet（ノード管理）が動いている
apiserver: Running  ← APIサーバーが動いている
kubeconfig: Configured

# ノード（サーバー）の確認
kubectl get nodes

# 出力：
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   1m    v1.30.0
         ↑
      ノードが1台動いている
```

---

## 💡 今何が起きた？

```
あなたのMac
├── Docker Desktop（起動中）
│   └── minikubeコンテナ
│       └── Kubernetesクラスター ✅
│           ├── APIサーバー
│           ├── スケジューラー
│           └── コントローラー
└── kubectl（クライアント）

→ Mac上にKubernetesクラスターができた！
```

---

## Part 2：最初のPodを作成

### Step 1：Podとは何か？

```
Pod = コンテナを包む「さや」

┌───────────────────┐
│ Pod（さや）        │
│  ┌─────────────┐  │
│  │ nginx       │  │ ← コンテナ
│  │ コンテナ    │  │
│  └─────────────┘  │
└───────────────────┘

→ 通常1Pod = 1コンテナ
→ 特殊な場合は1Pod = 複数コンテナ
```

---

### Step 2：Podを作成（コマンド版）

```bash
# nginx（Webサーバー）のPodを作成
kubectl run nginx-pod --image=nginx:latest

# 出力：
pod/nginx-pod created

# Podの確認
kubectl get pods

# 出力：
NAME        READY   STATUS    RESTARTS   AGE
nginx-pod   1/1     Running   0          10s
            ↑       ↑
         1個中1個   起動中
```

---

### Step 3：Podの詳細を確認

```bash
# Podの詳細情報
kubectl describe pod nginx-pod

# 重要な部分：
Name:             nginx-pod
Namespace:        default
Node:             minikube/192.168.49.2
Status:           Running
IP:               10.244.0.4  ← PodのIPアドレス
Containers:
  nginx-pod:
    Image:        nginx:latest
    Port:         <none>
    State:        Running
```

---

### Step 4：Podにアクセスしてみる

```bash
# Podのログを確認
kubectl logs nginx-pod

# Pod内でコマンド実行
kubectl exec -it nginx-pod -- /bin/bash

# Pod内に入った！
root@nginx-pod:/#

# nginxが動いているか確認
root@nginx-pod:/# curl localhost
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...

# 終了
root@nginx-pod:/# exit
```

---

### Step 5：ポートフォワードでアクセス

```bash
# ローカルの8080番ポートをPodの80番ポートに転送
kubectl port-forward nginx-pod 8080:80

# 出力：
Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80

# 別のターミナルを開いて確認
curl http://localhost:8080
# または
# ブラウザで http://localhost:8080 を開く

# Ctrl+C で停止
```

---

### Step 6：Podを削除

```bash
# Podを削除
kubectl delete pod nginx-pod

# 出力：
pod "nginx-pod" deleted

# 確認
kubectl get pods
# No resources found in default namespace.
```

---

## Part 3：Deployment（本命）

### Step 1：Deploymentとは？

```
問題：Podを手動で作ると...
- Podが死んだら終わり（自動復旧しない）
- 複数Podを管理できない
- ローリングアップデートできない

解決：Deployment
→ Podを自動管理してくれる上司
```

---

### Step 2：Deployment用のYAMLファイル作成

```bash
# ディレクトリ移動
cd /Users/k24032kk/AWS_CCP/handson-kubernetes

# YAMLファイル作成（次のステップで内容を記述）
touch nginx-deployment.yaml
```

---

### Step 3：nginx-deployment.yamlの内容

ファイルに以下を記述：

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3  # Podを3個作成
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
        image: nginx:1.27
        ports:
        - containerPort: 80
```

---

### Step 4：Deploymentを作成

```bash
# YAMLファイルからDeploymentを作成
kubectl apply -f nginx-deployment.yaml

# 出力：
deployment.apps/nginx-deployment created

# Deploymentの確認
kubectl get deployments

# 出力：
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   3/3     3            3           10s
                   ↑
                3個中3個準備完了
```

---

### Step 5：Podを確認

```bash
# Podの一覧
kubectl get pods

# 出力：
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-7c79c4bf97-4x2qw   1/1     Running   0          20s
nginx-deployment-7c79c4bf97-8nkjp   1/1     Running   0          20s
nginx-deployment-7c79c4bf97-x5m9h   1/1     Running   0          20s
↑
3個のPodが自動で作成された！
```

---

### Step 6：Podを削除してみる（自動復旧テスト）

```bash
# Podを1つ削除
kubectl delete pod nginx-deployment-7c79c4bf97-4x2qw

# すぐに確認
kubectl get pods

# 出力：
NAME                                READY   STATUS              RESTARTS   AGE
nginx-deployment-7c79c4bf97-4x2qw   1/1     Terminating         0          2m
nginx-deployment-7c79c4bf97-8nkjp   1/1     Running             0          2m
nginx-deployment-7c79c4bf97-x5m9h   1/1     Running             0          2m
nginx-deployment-7c79c4bf97-zk8pl   0/1     ContainerCreating   0          2s
                                            ↑
                                        新しいPodが自動で作成される！

# 数秒後
kubectl get pods

# 出力：
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-7c79c4bf97-8nkjp   1/1     Running   0          3m
nginx-deployment-7c79c4bf97-x5m9h   1/1     Running   0          3m
nginx-deployment-7c79c4bf97-zk8pl   1/1     Running   0          30s
                                    ↑
                                また3個に戻った！
```

---

## Part 4：Service（アクセス窓口）

### Step 1：Serviceとは？

```
問題：
- Podは死んだら別のPodが作られる
- 新しいPodはIPアドレスが変わる
- どのIPにアクセスすればいい？

解決：Service
→ 固定のアクセス窓口を提供
→ 裏でPodが入れ替わっても大丈夫
```

---

### Step 2：Service用のYAMLファイル作成

```bash
# YAMLファイル作成
touch nginx-service.yaml
```

ファイルに以下を記述：

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: NodePort  # 外部からアクセスできるようにする
  selector:
    app: nginx  # app=nginxのラベルを持つPodに転送
  ports:
  - protocol: TCP
    port: 80         # Serviceのポート
    targetPort: 80   # Podのポート
    nodePort: 30080  # 外部公開ポート（30000-32767の範囲）
```

---

### Step 3：Serviceを作成

```bash
# Serviceを作成
kubectl apply -f nginx-service.yaml

# 出力：
service/nginx-service created

# Serviceの確認
kubectl get services

# 出力：
NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
kubernetes      ClusterIP   10.96.0.1       <none>        443/TCP        10m
nginx-service   NodePort    10.96.123.45    <none>        80:30080/TCP   5s
                            ↑                             ↑
                        内部IP                        外部ポート
```

---

### Step 4：ブラウザでアクセス

```bash
# minikubeのIPアドレスを確認
minikube ip

# 出力例：
192.168.49.2

# minikubeのサービスURLを取得
minikube service nginx-service --url

# 出力例：
http://192.168.49.2:30080

# または自動でブラウザを開く
minikube service nginx-service

# ブラウザが開いて、Nginxのページが表示される！
```

---

## Part 5：スケーリング

### Step 1：Podを増やす

```bash
# Podを3個→5個に増やす
kubectl scale deployment nginx-deployment --replicas=5

# 出力：
deployment.apps/nginx-deployment scaled

# 確認
kubectl get pods

# 出力：5個に増えた！
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-7c79c4bf97-8nkjp   1/1     Running   0          10m
nginx-deployment-7c79c4bf97-x5m9h   1/1     Running   0          10m
nginx-deployment-7c79c4bf97-zk8pl   1/1     Running   0          8m
nginx-deployment-7c79c4bf97-abc12   1/1     Running   0          5s
nginx-deployment-7c79c4bf97-def34   1/1     Running   0          5s
```

---

### Step 2：Podを減らす

```bash
# Podを5個→2個に減らす
kubectl scale deployment nginx-deployment --replicas=2

# 確認
kubectl get pods

# 出力：2個に減った！
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-7c79c4bf97-8nkjp   1/1     Running   0          11m
nginx-deployment-7c79c4bf97-x5m9h   1/1     Running   0          11m
```

---

## Part 6：ローリングアップデート

### Step 1：現在のバージョン確認

```bash
# Deploymentの詳細確認
kubectl describe deployment nginx-deployment | grep Image

# 出力：
Image: nginx:1.27
```

---

### Step 2：新しいバージョンにアップデート

```bash
# nginx:1.27 → nginx:1.28 に更新
kubectl set image deployment/nginx-deployment nginx=nginx:1.28

# 出力：
deployment.apps/nginx-deployment image updated

# リアルタイムで確認
kubectl get pods --watch

# 出力：古いPodが順次終了し、新しいPodが起動
NAME                                READY   STATUS              RESTARTS   AGE
nginx-deployment-7c79c4bf97-8nkjp   1/1     Running             0          15m
nginx-deployment-7c79c4bf97-x5m9h   1/1     Running             0          15m
nginx-deployment-556b8d7f9b-abc12   0/1     ContainerCreating   0          2s
nginx-deployment-556b8d7f9b-def34   1/1     Running             0          5s
nginx-deployment-7c79c4bf97-8nkjp   1/1     Terminating         0          15m
...

# Ctrl+C で停止
```

---

### Step 3：ロールアウト履歴確認

```bash
# アップデート履歴
kubectl rollout history deployment/nginx-deployment

# 出力：
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
```

---

### Step 4：ロールバック（前のバージョンに戻す）

```bash
# 1つ前のバージョンに戻す
kubectl rollout undo deployment/nginx-deployment

# 出力：
deployment.apps/nginx-deployment rolled back

# 確認
kubectl describe deployment nginx-deployment | grep Image
# 出力：
Image: nginx:1.27  ← 戻った！
```

---

## Part 7：便利なコマンド

```bash
# 全リソースを確認
kubectl get all

# 特定のPodの詳細
kubectl describe pod <pod名>

# Podのログ確認
kubectl logs <pod名>

# Podのログをリアルタイム監視
kubectl logs -f <pod名>

# Pod内でコマンド実行
kubectl exec -it <pod名> -- /bin/bash

# リソースの削除
kubectl delete deployment <deployment名>
kubectl delete service <service名>

# YAMLファイルから削除
kubectl delete -f nginx-deployment.yaml

# 全Podを削除
kubectl delete pods --all

# 名前空間のリソース一覧
kubectl get all -n default
```

---

## 🧹 後片付け

```bash
# Serviceを削除
kubectl delete -f nginx-service.yaml

# Deploymentを削除
kubectl delete -f nginx-deployment.yaml

# 確認
kubectl get all
# No resources found in default namespace.

# minikubeクラスターを停止
minikube stop

# minikubeクラスターを完全削除（必要な場合）
minikube delete
```

---

## 💡 重要ポイント

### Kubernetesの階層

```
Deployment（管理者）
    ↓ 作成・管理
ReplicaSet（中間管理職）
    ↓ 作成・管理
Pod（実際のワーカー）
    ↓ 包む
Container（アプリケーション）
```

### Podの特徴

```
✅ 1Pod = 通常1コンテナ
✅ Podは使い捨て（死んだら新しいPodが作られる）
✅ Pod単体では自動復旧しない
❌ 手動でPodを作らない（Deploymentを使う）
```

### Deploymentの役割

```
✅ 指定した数のPodを維持
✅ Podが死んだら自動で再作成
✅ ローリングアップデート
✅ ロールバック
```

### Serviceの役割

```
✅ Podへの固定アクセス窓口
✅ 負荷分散（複数Podに振り分け）
✅ サービスディスカバリ
```

---

## ✅ チェックリスト

- [ ] minikubeをインストールした
- [ ] kubectlをインストールした
- [ ] minikubeクラスターを起動した
- [ ] 最初のPodを作成した
- [ ] Podにアクセスした
- [ ] Deploymentを作成した（YAML）
- [ ] Podの自動復旧を確認した
- [ ] Serviceを作成した
- [ ] ブラウザでアクセスした
- [ ] スケーリング（増減）を試した
- [ ] ローリングアップデートを試した
- [ ] ロールバックを試した
- [ ] 全て削除した

---

## 次のステップ

### 基礎固め
- ConfigMap（設定の外部化）
- Secret（機密情報の管理）
- Volume（永続化ストレージ）
- Namespace（環境分離）

### 実践
- 複数サービスの連携（マイクロサービス）
- Ingress（HTTPルーティング）
- Helm（パッケージ管理）

### AWS連携
- Amazon ECS（AWS版コンテナオーケストレーション）
- Amazon EKS（AWS版Kubernetes）

---

## 🎓 学習リソース

### 公式ドキュメント
- Kubernetes公式: https://kubernetes.io/ja/docs/home/
- minikube公式: https://minikube.sigs.k8s.io/docs/

### チュートリアル
- Kubernetes基礎: https://kubernetes.io/ja/docs/tutorials/kubernetes-basics/

---

## トラブルシューティング

### minikube start が失敗する

```bash
# Docker Desktopが起動しているか確認
docker ps

# minikubeを削除して再作成
minikube delete
minikube start
```

### Podが起動しない

```bash
# Pod の詳細を確認
kubectl describe pod <pod名>

# イベントログを確認
kubectl get events --sort-by=.metadata.creationTimestamp
```

### ポートフォワードができない

```bash
# Podが起動しているか確認
kubectl get pods

# Podの名前が正しいか確認
kubectl get pods | grep nginx
```

---

**これでローカルKubernetesの基礎は完璧です！🎉**
