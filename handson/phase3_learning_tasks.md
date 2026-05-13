# Phase 2.5: 学習（Phase 3の前提知識）

## Level 1：Kubernetesローカル基礎（minikube）

- [ ] Podとは何か、YAMLの書き方、ライフサイクルを学ぶ
- [ ] nginxのPodを作成・削除する
- [ ] Deploymentとは何か、YAMLの書き方を学ぶ
- [ ] nginx Deploymentを3レプリカで作成する
- [ ] Deploymentをスケール・更新・ロールバックする
- [ ] Serviceとは何か、DNS名、負荷分散を学ぶ
- [ ] Service の種類（ClusterIP/NodePort/LoadBalancer）を学ぶ
- [ ] ClusterIPとNodePortを試す
- [ ] ServiceとPodの接続（ラベルセレクタ、Endpoints、DNS）を学ぶ
- [ ] 2つのPod間でService経由通信する
- [ ] ConfigMapの基礎を学ぶ
- [ ] ConfigMapを作成してPodにマウントする
- [ ] Secretの基礎を学ぶ
- [ ] Secretを作成してPodで使用する

## Level 2：Kubernetes中級

- [ ] StatefulSetとは何か、Deploymentとの違いを学ぶ
- [ ] StatefulSet YAMLの書き方を学ぶ
- [ ] 簡単なStatefulSetを作成する
- [ ] StatefulSetをスケールする
- [ ] PV・PVCとは何か学ぶ
- [ ] PVC YAMLの書き方を学ぶ
- [ ] PVCを作成してPodにマウントする
- [ ] StorageClassの動的プロビジョニングを学ぶ
- [ ] Ingressとは何か、ServiceのLoadBalancerとの違いを学ぶ
- [ ] Ingress YAMLの書き方を学ぶ
- [ ] minikubeでIngress Addonを有効化して試す
- [ ] Ingress Controllerの理解（Nginx Ingress, AWS Load Balancer Controller）
- [ ] HPAとは何か、Metrics Serverを学ぶ
- [ ] HPA YAMLの書き方を学ぶ
- [ ] nginxに負荷をかけてHPAでスケールさせる

## Level 3：AWS基礎復習（VPC・IAM）

- [ ] VPC設計を復習する（Public/Private Subnet、NAT Gateway、Internet Gateway、ルートテーブル）
- [ ] EKS用VPCの要件を学ぶ（最低2つのAZ、SubnetのタグKubernetes.io/role/elb）
- [ ] IAM Roleの基礎を復習する（Trust Relationship、Policy Attachment）
- [ ] EKS用IAM Roleを理解する（Cluster Role、Node Role）
- [ ] IRSA（IAM Roles for Service Accounts）の概念を学ぶ

## Level 4：EKS標準モード

- [ ] EKSとは何か、アーキテクチャ（Control Plane、Data Plane）を学ぶ
- [ ] eksctlをHomebrewでインストールする
- [ ] eksctl基本コマンドを学ぶ（create cluster、create nodegroup、delete cluster）
- [ ] 最小構成でEKSクラスタを作成→削除する
- [ ] eksctl設定ファイル（YAML形式）の書き方を学ぶ
- [ ] 設定ファイルからEKSクラスタを作成する
- [ ] マネージドノードグループとは何か学ぶ
- [ ] ノードグループを追加・削除する
- [ ] Karpenterとは何か、Cluster Autoscalerとの違いを学ぶ
- [ ] KarpenterをHelmでインストールする（IRSA設定含む）
- [ ] Provisioner/NodePoolを作成する
- [ ] Podをスケールアウトして新ノード起動を確認する
- [ ] ノードの自動削除を確認する
- [ ] EBS CSI Driverとは何か、動的プロビジョニングを学ぶ
- [ ] EBS CSI DriverをEKS Addonとして追加する（IRSA設定含む）
- [ ] StorageClass（gp3、volumeBindingMode）を作成する
- [ ] StorageClassを使ってPVCをテストする
- [ ] AWS Load Balancer Controllerとは何か学ぶ（ALB/NLB自動作成）
- [ ] ALB ControllerをHelmでインストールする（IRSA設定含む）
- [ ] ALB Ingressを作成する
- [ ] Ingressアノテーション（alb.ingress.kubernetes.io/*）を理解する
- [ ] サンプルアプリをALBで公開する
- [ ] Helmとは何か、Chartを学ぶ
- [ ] Helm基本コマンドを学ぶ（repo add、install、list、uninstall）
- [ ] サンプルChartをインストールする

## Phase 3 直前の準備

- [ ] nginx Deployment + Serviceをminikubeで作成する
- [ ] PostgreSQL StatefulSet + PVC + Serviceをminikubeで作成する
- [ ] Ingress（minikube addon）でnginxにHTTPアクセスする
- [ ] nginx → PostgreSQL 接続を確認する
- [ ] Phase 3用のnginx-deployment.yamlを準備する
- [ ] Phase 3用のnginx-service.yamlを準備する
- [ ] Phase 3用のpostgres-statefulset.yamlを準備する
- [ ] Phase 3用のpostgres-pvc.yamlを準備する
- [ ] Phase 3用のpostgres-service.yamlを準備する
- [ ] Phase 3用のingress.yamlを準備する
- [ ] 標準EKS用のeksctl設定ファイルを準備する
- [ ] Auto Mode用のeksctl設定ファイルを準備する
- [ ] VPC設定を確認する
- [ ] コスト見積もりを確認する（標準EKS約$50-60、Auto Mode約$50-60、合計$100-120）
