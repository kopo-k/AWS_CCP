# ハンズオン⑬：ConfigMap入門（設定の外部化）

## ConfigMap とは

**設定情報をPodの外に出して、別管理する仕組み**

### 語源

**Config** + **Map** の組み合わせ

- **Config（コンフィグ）**: Configuration（設定、構成）の略
- **Map（マップ）**: キーと値のペア（辞書のようなもの）

### なぜ必要？

**問題**: 設定をコンテナイメージに埋め込むと、設定変更のたびにイメージを再ビルド・再デプロイが必要

**解決**: ConfigMapで設定を外部化すれば、イメージはそのまま、設定だけ変更可能

---

## Part 1：ConfigMap を使わない場合（問題点を体験）

### Step 1：設定が埋め込まれたPodを作成

`app-no-configmap.yaml` を作成します。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-no-configmap
spec:
  containers:
  - name: nginx
    image: nginx:latest
    env:
    # 環境変数を直接Pod定義に埋め込み
    - name: ENVIRONMENT
      value: "development"
    - name: LOG_LEVEL
      value: "debug"
    - name: MAX_CONNECTIONS
      value: "50"
```

### Step 2：Podを作成して環境変数を確認

```bash
kubectl apply -f app-no-configmap.yaml

# 環境変数を確認
kubectl exec app-no-configmap -- env | grep -E "ENVIRONMENT|LOG_LEVEL|MAX_CONNECTIONS"
```

**結果**:
```
ENVIRONMENT=development
LOG_LEVEL=debug
MAX_CONNECTIONS=50
```

---

### Step 3：設定を変更したい場合（問題発生）

**シナリオ**: 本番環境用に設定を変更したい

- `ENVIRONMENT` を `production` に変更
- `LOG_LEVEL` を `info` に変更
- `MAX_CONNECTIONS` を `200` に変更

**どうする？**

❌ **Pod定義ファイルを編集 → 削除 → 再作成**

```bash
# YAMLファイルを編集
# value: "development" → value: "production" など

# 削除して再作成
kubectl delete -f app-no-configmap.yaml
kubectl apply -f app-no-configmap.yaml
```

### 問題点

1. **設定変更のたびにPodの再起動が必要**
2. **開発・ステージング・本番で別々のYAMLファイルが必要**
3. **設定が複数ファイルに分散して管理が大変**

---

## Part 2：ConfigMap を使う場合（問題解決）

### Step 1：ConfigMap を作成

`app-config-dev.yaml` を作成します（開発環境用）。

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config-dev
data:
  ENVIRONMENT: "development"
  LOG_LEVEL: "debug"
  MAX_CONNECTIONS: "50"
```

`app-config-prod.yaml` を作成します（本番環境用）。

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config-prod
data:
  ENVIRONMENT: "production"
  LOG_LEVEL: "info"
  MAX_CONNECTIONS: "200"
```

### Step 2：開発用ConfigMapを適用

```bash
kubectl apply -f app-config-dev.yaml

# 確認
kubectl get configmaps
kubectl describe configmap app-config-dev
```

---

### Step 3：ConfigMapを使うPodを作成

`app-with-configmap.yaml` を作成します。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-configmap
spec:
  containers:
  - name: nginx
    image: nginx:latest
    # ConfigMapから環境変数を注入
    envFrom:
    - configMapRef:
        name: app-config-dev  # ここでConfigMapを指定
```

### Step 4：Podを作成して確認

```bash
kubectl apply -f app-with-configmap.yaml

# 環境変数を確認
kubectl exec app-with-configmap -- env | grep -E "ENVIRONMENT|LOG_LEVEL|MAX_CONNECTIONS"
```

**結果**:
```
ENVIRONMENT=development
LOG_LEVEL=debug
MAX_CONNECTIONS=50
```

---

### Step 5：本番環境用に切り替える

**本番用ConfigMapを適用**:

```bash
kubectl apply -f app-config-prod.yaml
```

**Pod定義を編集**（`app-with-configmap.yaml`）:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-configmap
spec:
  containers:
  - name: nginx
    image: nginx:latest
    envFrom:
    - configMapRef:
        name: app-config-prod  # dev → prod に変更
```

**再作成**:

```bash
kubectl delete pod app-with-configmap
kubectl apply -f app-with-configmap.yaml

# 環境変数を確認
kubectl exec app-with-configmap -- env | grep -E "ENVIRONMENT|LOG_LEVEL|MAX_CONNECTIONS"
```

**結果**:
```
ENVIRONMENT=production
LOG_LEVEL=info
MAX_CONNECTIONS=200
```

---

## Part 3：ConfigMap の個別キー参照

### 全部じゃなくて一部だけ使いたい場合

`app-with-configmap-key.yaml` を作成します。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-configmap-key
spec:
  containers:
  - name: nginx
    image: nginx:latest
    env:
    # ConfigMapから個別にキーを参照
    - name: ENV
      valueFrom:
        configMapKeyRef:
          name: app-config-prod
          key: ENVIRONMENT
    - name: LOG
      valueFrom:
        configMapKeyRef:
          name: app-config-prod
          key: LOG_LEVEL
    # 固定値も混在可能
    - name: CUSTOM_VALUE
      value: "my-custom-setting"
```

```bash
kubectl apply -f app-with-configmap-key.yaml
kubectl exec app-with-configmap-key -- env | grep -E "ENV|LOG|CUSTOM"
```

---

## Part 4：ConfigMap をファイルとしてマウント

### 設定ファイルとして使う場合

`nginx-html-config.yaml` を作成します。

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-html-config
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head><title>ConfigMap Test</title></head>
    <body>
      <h1>This HTML is from ConfigMap!</h1>
      <p>Environment: Production</p>
    </body>
    </html>
```

`nginx-with-html-config.yaml` を作成します。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-with-html
spec:
  containers:
  - name: nginx
    image: nginx:latest
    ports:
    - containerPort: 80
    # ConfigMapをボリュームとしてマウント
    volumeMounts:
    - name: html-volume
      mountPath: /usr/share/nginx/html
  volumes:
  - name: html-volume
    configMap:
      name: nginx-html-config
```

```bash
kubectl apply -f nginx-html-config.yaml
kubectl apply -f nginx-with-html-config.yaml

# HTMLファイルが配置されたか確認
kubectl exec nginx-with-html -- cat /usr/share/nginx/html/index.html

# ポートフォワードでアクセス
kubectl port-forward nginx-with-html 8080:80
# ブラウザで http://localhost:8080 にアクセス
```

---

## 比較表：ConfigMap を使う場合 vs 使わない場合

| 項目 | ConfigMap なし | ConfigMap あり |
|------|---------------|---------------|
| **設定の場所** | Pod定義に直接埋め込み | ConfigMapで別管理 |
| **設定変更** | Pod定義を編集→削除→再作成 | ConfigMapだけ更新 |
| **環境ごとの管理** | 環境ごとに別YAMLファイル | ConfigMapだけ切り替え |
| **再利用性** | 低い（設定が分散） | 高い（設定を集約） |
| **保守性** | 悪い | 良い |

---

## まとめ

### ConfigMap のメリット

1. **設定とコードの分離** → 設定だけ変更できる
2. **環境ごとの切り替えが簡単** → dev/prod で同じPod定義を使える
3. **設定の一元管理** → ConfigMapに集約
4. **再利用性が高い** → 複数のPodで同じConfigMapを使える

### 使い分け

- **ConfigMap なし**: テスト用の使い捨てPod
- **ConfigMap あり**: 本番運用するアプリケーション

---

## クリーンアップ

```bash
kubectl delete pod app-no-configmap
kubectl delete pod app-with-configmap
kubectl delete pod app-with-configmap-key
kubectl delete pod nginx-with-html
kubectl delete configmap app-config-dev
kubectl delete configmap app-config-prod
kubectl delete configmap nginx-html-config
```

---

## 次のステップ

- **Secret**: パスワードやAPIキーなど機密情報の管理（ConfigMapの暗号化版）
- **Volume**: 永続化データの管理
- **Namespace**: リソースの論理的な分離

---

**作成日**: 2026-05-11
**目的**: ConfigMapの必要性を「使わない場合」と比較して体験的に理解する
