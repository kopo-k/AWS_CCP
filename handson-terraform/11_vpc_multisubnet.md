# ハンズオン⑪：VPC + マルチサブネット構成

## 学習目標
- VPCを手動で作成する
- パブリック/プライベートサブネットを理解する
- インターネットゲートウェイ・ルートテーブルの役割を知る
- Terraformで同じ構成を再現する

## 学べる概念
- ✅ VPC（Virtual Private Cloud）
- ✅ サブネット（パブリック/プライベート）
- ✅ インターネットゲートウェイ（IGW）
- ✅ ルートテーブル
- ✅ セキュリティグループ

---

## 所要時間
約1時間

## コスト
**無料枠内で完結**

---

## 全体構成図

```
インターネット
    ↓
インターネットゲートウェイ（IGW）
    ↓
┌────────────────────────────────────────┐
│ VPC（10.0.0.0/16）                      │
│                                        │
│ ┌─────────────────┐  ┌──────────────┐│
│ │パブリックサブネット│  │プライベート   ││
│ │10.0.1.0/24      │  │サブネット     ││
│ │                 │  │10.0.2.0/24   ││
│ │ EC2（Web）      │  │              ││
│ │ パブリックIP有   │  │ パブリックIP無││
│ └─────────────────┘  └──────────────┘│
└────────────────────────────────────────┘
```

---

## Part 1：コンソールでVPCを作成

### Step 1：VPCを作成

1. AWSコンソール → **VPC**
2. 「**VPCを作成**」
3. 設定：

| 項目 | 設定値 |
|------|--------|
| VPC名 | `my-vpc` |
| IPv4 CIDR | `10.0.0.0/16` |

4. 「VPCを作成」

---

### Step 2：パブリックサブネットを作成

1. 左メニュー → 「**サブネット**」
2. 「**サブネットを作成**」
3. 設定：

| 項目 | 設定値 |
|------|--------|
| VPC | `my-vpc` |
| サブネット名 | `public-subnet` |
| アベイラビリティゾーン | `ap-northeast-1a` |
| IPv4 CIDR | `10.0.1.0/24` |

4. 「サブネットを作成」

---

### Step 3：プライベートサブネットを作成

同じ手順でもう1つ作成：

| 項目 | 設定値 |
|------|--------|
| VPC | `my-vpc` |
| サブネット名 | `private-subnet` |
| アベイラビリティゾーン | `ap-northeast-1a` |
| IPv4 CIDR | `10.0.2.0/24` |

---

### Step 4：インターネットゲートウェイを作成

1. 左メニュー → 「**インターネットゲートウェイ**」
2. 「**インターネットゲートウェイの作成**」
3. 名前：`my-igw`
4. 「作成」
5. 作成したIGWを選択 → 「**アクション**」→ 「**VPCにアタッチ**」
6. VPC：`my-vpc` を選択 → 「アタッチ」

---

### Step 5：ルートテーブルを設定（パブリック用）

1. 左メニュー → 「**ルートテーブル**」
2. 「**ルートテーブルを作成**」
3. 設定：

| 項目 | 設定値 |
|------|--------|
| 名前 | `public-route-table` |
| VPC | `my-vpc` |

4. 「作成」
5. 作成したルートテーブルを選択 → 「**ルート**」タブ → 「**ルートを編集**」
6. 「**ルートを追加**」

| 送信先 | ターゲット |
|--------|-----------|
| `0.0.0.0/0` | `my-igw` |

7. 「変更を保存」

---

### Step 6：サブネットをルートテーブルに関連付け

1. `public-route-table` を選択
2. 「**サブネットの関連付け**」タブ
3. 「**サブネットの関連付けを編集**」
4. `public-subnet` にチェック
5. 「関連付けを保存」

---

### Step 7：パブリックサブネットの自動IP割り当てを有効化

1. 「サブネット」→ `public-subnet` を選択
2. 「**アクション**」→ 「**サブネット設定を編集**」
3. 「**パブリック IPv4 アドレスの自動割り当てを有効化**」にチェック
4. 「保存」

---

### Step 8：セキュリティグループを作成

1. 左メニュー → 「**セキュリティグループ**」
2. 「**セキュリティグループを作成**」
3. 設定：

| 項目 | 設定値 |
|------|--------|
| セキュリティグループ名 | `web-sg` |
| 説明 | `Allow HTTP and SSH` |
| VPC | `my-vpc` |

4. **インバウンドルール**を追加：

| タイプ | ポート | ソース |
|--------|--------|--------|
| SSH | 22 | `0.0.0.0/0` |
| HTTP | 80 | `0.0.0.0/0` |

5. 「セキュリティグループを作成」

---

### Step 9：EC2インスタンスを起動

1. EC2コンソール → 「**インスタンスを起動**」
2. 設定：

| 項目 | 設定値 |
|------|--------|
| 名前 | `web-server` |
| AMI | Amazon Linux 2023 |
| インスタンスタイプ | `t2.micro` |
| **ネットワーク設定** | **編集をクリック** |
| VPC | `my-vpc` |
| サブネット | `public-subnet` |
| パブリックIP自動割り当て | 有効 |
| セキュリティグループ | `web-sg` |

3. 「インスタンスを起動」

---

### Step 10：動作確認（基本）

```bash
# パブリックIPを確認
EC2コンソール → インスタンス → web-server → パブリックIPv4アドレス

# AZ（アベイラビリティゾーン）の確認
EC2コンソール → インスタンス → web-server → 詳細タブ → アベイラビリティゾーン
```

---

### Step 11：キーペアを作成してインスタンスを再作成

**※ Step 9でキーペアなしで作成した場合、SSH接続のために再作成が必要です**

1. EC2コンソール → 左メニュー「**キーペア**」
2. 「**キーペアを作成**」
3. 設定：

| 項目 | 設定値 |
|------|--------|
| 名前 | `my-keypair` |
| キーペアのタイプ | RSA |
| プライベートキーファイル形式 | `.pem`（Mac/Linux） |

4. 「キーペアを作成」→ `my-keypair.pem` が自動ダウンロード
5. **ダウンロードしたファイルを安全な場所に移動**

```bash
# Mac/Linuxの場合
mkdir -p ~/.ssh
mv ~/Downloads/my-keypair.pem ~/.ssh/
chmod 400 ~/.ssh/my-keypair.pem
```

6. **既存のEC2インスタンスを削除**（キーペアなしで作成したもの）
7. **Step 9を再実行**（今度は「キーペア」で `my-keypair` を選択）

---

### Step 12：SSH接続してWebサーバーをセットアップ

1. **パブリックIPを確認**

```bash
# EC2コンソール → インスタンス → web-server → パブリックIPv4アドレス
# 例: 54.123.45.67
```

2. **SSH接続**

```bash
# ターミナルで実行（MacまたはLinux）
ssh -i ~/.ssh/my-keypair.pem ec2-user@43.207.212.120
# ↑ 54.123.45.67 は自分のパブリックIPに置き換える

# 初回接続時の確認メッセージ → yes と入力
Are you sure you want to continue connecting (yes/no)? yes

# 接続成功！
   ,     #_
   ~\_  ####_        Amazon Linux 2023
  ~~  \_#####\
  ~~     \###|
  ~~       \#/ ___   https://aws.amazon.com/linux/amazon-linux-2023
   ~~       V~' '->
    ~~~         /
      ~~._.   _/
         _/ _/
       _/m/'

[ec2-user@ip-10-0-1-10 ~]$  ← EC2の中に入った！
```

3. **Nginxをインストール**

```bash
# パッケージリストを更新
sudo yum update -y

# Nginxをインストール
sudo yum install nginx -y

# インストール確認
nginx -v
# nginx version: nginx/1.24.0 と表示されればOK
```

4. **Nginxを起動**

```bash
# Nginxサービスを起動
sudo systemctl start nginx

# 起動確認
sudo systemctl status nginx
# Active: active (running) と表示されればOK

# 自動起動を有効化（再起動しても自動で起動する）
sudo systemctl enable nginx
```

5. **HTMLファイルを作成**

```bash
# デフォルトのHTMLを編集
sudo vi /usr/share/nginx/html/index.html
```

viエディタで以下を入力：

```html
<!DOCTYPE html>
<html>
<head>
    <title>My First Web Server</title>
</head>
<body>
    <h1>Hello from EC2!</h1>
    <p>VPC: my-vpc (10.0.0.0/16)</p>
    <p>Subnet: public-subnet (10.0.1.0/24)</p>
</body>
</html>
```

viの操作：
- `i` キーで編集モード
- 上記HTMLを貼り付け
- `Esc` キーで編集モード終了
- `:wq` と入力してEnter（保存して終了）

---

### Step 13：ブラウザでアクセス確認

1. **ブラウザを開く**
2. **URLバーに入力**

```
http://54.123.45.67
↑ 自分のパブリックIPに置き換える
```

3. **表示されるはず**

```
Hello from EC2!
VPC: my-vpc (10.0.0.0/16)
Subnet: public-subnet (10.0.1.0/24)
```

✅ **成功！パブリックサブネット上でWebサーバーが動作している**

---

### Step 14：ログとトラブルシューティング

```bash
# Nginxのエラーログを確認
sudo tail -f /var/log/nginx/error.log

# アクセスログを確認
sudo tail -f /var/log/nginx/access.log

# Nginxのプロセス確認
ps aux | grep nginx

# ポート80が開いているか確認
sudo netstat -tlnp | grep :80

# セキュリティグループの確認（コンソールで）
# - HTTP (80) が 0.0.0.0/0 で許可されているか確認

# SSH接続を終了
exit
```

---

## 🧹 後片付け

```
1. EC2インスタンス削除
2. セキュリティグループ削除（web-sg）
3. インターネットゲートウェイをVPCからデタッチ → 削除
4. サブネット削除（public-subnet, private-subnet）
5. ルートテーブル削除（public-route-table）
6. VPC削除（my-vpc）
```

---

## Part 2：Terraformで同じ構成を作る

Part 1で手動作成した構成を、Terraformで自動化します。

### 🎯 やること

**手動（コンソール）で作成した構成**を**コード（Terraform）**で再現します。

---

### Step 1：既存のリソースを削除

**⚠️ 重要：Terraformで管理する前に、手動で作成したリソースを全て削除してください**

```
理由：
- 同じ名前のリソースが存在すると競合する
- Terraformは「自分が作成したリソース」のみ管理する
- 手動作成 + Terraform管理 = 混乱の元
```

削除順序（🧹 後片付けセクション参照）：
1. EC2インスタンス削除
2. セキュリティグループ削除（web-sg）
3. IGWをVPCからデタッチ → 削除
4. サブネット削除（public-subnet, private-subnet）
5. ルートテーブル削除（public-route-table）
6. VPC削除（my-vpc）

---

### Step 2：main.tf を新規作成

```bash
cd /Users/k24032kk/AWS_CCP/handson-terraform
```

新しい `main.tf` ファイルを作成します（次のステップで内容を記述）。

---

### Step 3：Terraformコードを書く

`main.tf` に以下を記述：

```hcl
# プロバイダー設定
provider "aws" {
  region = "ap-northeast-1"
}

# VPC
resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "my-vpc"
  }
}

# パブリックサブネット
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true  # パブリックIP自動割り当て

  tags = {
    Name = "public-subnet"
  }
}

# プライベートサブネット
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "private-subnet"
  }
}

# インターネットゲートウェイ
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my-igw"
  }
}

# パブリック用ルートテーブル
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.my_vpc.id

  # 0.0.0.0/0 → IGW のルート
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# パブリックサブネットとルートテーブルの関連付け
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# セキュリティグループ
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.my_vpc.id

  # SSH（22番ポート）
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP（80番ポート）
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # アウトバウンド（全て許可）
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg"
  }
}

# EC2インスタンス
resource "aws_instance" "web" {
  ami                    = "ami-0a0b7b240264a48d7"  # Amazon Linux 2023
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # キーペアを指定する場合（オプション）
  # key_name = "my-keypair"

  tags = {
    Name = "web-server"
  }
}

# 出力
output "vpc_id" {
  value       = aws_vpc.my_vpc.id
  description = "VPC ID"
}

output "public_subnet_id" {
  value       = aws_subnet.public.id
  description = "パブリックサブネット ID"
}

output "private_subnet_id" {
  value       = aws_subnet.private.id
  description = "プライベートサブネット ID"
}

output "ec2_public_ip" {
  value       = aws_instance.web.public_ip
  description = "EC2のパブリックIP"
}
```

---

### Step 4：Terraform実行

```bash
# 1. 初期化（初回のみ）
terraform init

# 2. プレビュー（何が作成されるか確認）
terraform plan

# 表示される内容：
# Plan: 9 to add, 0 to change, 0 to destroy.
# → VPC, サブネット×2, IGW, ルートテーブル, 関連付け, SG, EC2 = 9個

# 3. 実行（実際に作成）
terraform apply

# "yes" と入力してEnter

# 4. 完了！出力が表示される
Outputs:

ec2_public_ip = "54.123.45.67"
private_subnet_id = "subnet-xxxxx"
public_subnet_id = "subnet-yyyyy"
vpc_id = "vpc-zzzzz"
```

---

### Step 5：動作確認

```bash
# 1. 出力されたパブリックIPをブラウザで開く
http://54.123.45.67

# 2. AWSコンソールで確認
VPC → VPCが作成されている
サブネット → 2つのサブネットが作成されている
EC2 → インスタンスが起動している

# 3. SSH接続する場合（キーペアを指定した場合）
ssh -i ~/.ssh/my-keypair.pem ec2-user@54.123.45.67
```

---

### Step 6：Webサーバーのセットアップ（オプション）

SSH接続してNginxをインストールする場合は、Part 1のStep 12-13を参照。

---

### Step 7：削除

```bash
# 全てのリソースを削除
terraform destroy

# "yes" と入力してEnter

# 確認メッセージ
Destroy complete! Resources: 9 destroyed.
```

✅ **たった1コマンドで全て削除！**

---

## 🔄 コンソール vs Terraform の比較

| 項目 | コンソール（手動） | Terraform（コード） |
|------|-------------------|-------------------|
| 作成時間 | 20-30分 | 2分 |
| 削除時間 | 10分（順番に削除） | 1分（`terraform destroy`） |
| 再現性 | 手順書が必要 | コードがそのまま手順書 |
| ミス | クリックミスの可能性 | コードレビューで防げる |
| チーム共有 | 手順書を共有 | Gitでコード共有 |
| 環境複製 | 同じ手順を繰り返す | コピペで複製 |

---

## 💡 Terraformの便利ポイント

### 1. 依存関係を自動解決

```hcl
# VPCを先に作って、その後サブネットを作る
# → Terraformが自動で順序を決める

resource "aws_vpc" "my_vpc" { ... }
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.my_vpc.id  # ← 参照
}
```

### 2. 変更の差分確認

```bash
terraform plan
# → 何が追加・変更・削除されるかプレビュー
```

### 3. 状態管理

```bash
terraform.tfstate
# → 現在のインフラの状態を記録
# → 次回実行時に差分を検出
```

---

## 💡 重要ポイント

### パブリックサブネットとは？

```
インターネットゲートウェイへのルート（0.0.0.0/0 → IGW）がある
→ パブリックサブネット

ルートがない
→ プライベートサブネット
```

### CIDR表記

| CIDR | 使えるIP数 | 用途 |
|------|-----------|------|
| `/16` | 65,536個 | VPC全体 |
| `/24` | 256個 | サブネット |
| `/32` | 1個 | 特定のIP |

---

## ✅ チェックリスト

**Part 1：基本構成（必須）**
- [ ] VPCを作成した（10.0.0.0/16）
- [ ] パブリックサブネットを作成した（10.0.1.0/24）
- [ ] プライベートサブネットを作成した（10.0.2.0/24）
- [ ] インターネットゲートウェイを作成・アタッチした
- [ ] パブリック用ルートテーブルを作成・設定した
- [ ] セキュリティグループを作成した
- [ ] EC2をパブリックサブネットに起動した
- [ ] パブリックIPを確認した

**Part 1：Webサーバーセットアップ（オプション）**
- [ ] キーペアを作成した
- [ ] SSH接続できた
- [ ] Nginxをインストールした
- [ ] Nginxを起動した
- [ ] ブラウザでWebページを表示できた

**後片付け**
- [ ] 全て削除した

---

## 次のステップ

→ Terraformで同じ構成を自動化する
