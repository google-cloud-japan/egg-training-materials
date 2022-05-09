# EGG ハンズオン #5 Cloud Run 編

## **Google Cloud プロジェクトの選択**

ハンズオンを行う Google Cloud プロジェクトを選択して **Start/開始** をクリックしてください。

<walkthrough-project-setup>
</walkthrough-project-setup>

<walkthrough-watcher-constant key="repo_name" value="egg5-2"></walkthrough-watcher-constant>
<walkthrough-watcher-constant key="instance_id" value="demo"></walkthrough-watcher-constant>
<walkthrough-watcher-constant key="database_id" value="ranking"></walkthrough-watcher-constant>
<walkthrough-watcher-constant key="region" value="asia-northeast1"></walkthrough-watcher-constant>
<walkthrough-watcher-constant key="sa_name" value="spanner-demo"></walkthrough-watcher-constant>

## [解説] ハンズオンの内容

### **目的と内容**

本ハンズオンは Cloud Run を触ったことのない方向けに、Cloud Run を使ったアプリケーション開発における、最初の 1 歩目のイメージを掴んで頂くことを目的としています。 

Cloud Spanner 編で利用したアプリケーションを、Cloud Run にデプロイし、
Cloud Run ＋ Cloud Spanner構成のアプリケーションを構築します。 

### **前提条件**

本ハンズオンは、はじめて Cloud Run を触られる方を想定しておりますが、Cloud Run にデプロイする
アプリケーションに関して、詳細な説明は行いません。Cloud Run の機能になるべくフォーカスして
ハンズオンを進めていきます。

## [演習]1. ハンズオンの事前準備

Spanner 編で利用したアプリケーションを引き続き利用します。
以下のようなディレクトリ構成となっている想定です。

```
.
├── README.md
├── spanner-sqlalchemy-demo
│   ├── app
│   ├── Dockerfile
│   ├── poetry.lock
│   ├── pyproject.toml
│   ├── README.md
│   └── tests
├── tutorial.md
└── tutorial-run.md
```

### 環境変数の設定

後続の手順で利用しますので、環境変数の設定を行います。
Atrifact Registy のリポジトリ名を設定します。
適当な名前を事前に入力していますが、任意のリポジトリ名でも問題ありません。

```bash
export REPOSITORY_NAME="{{repo_name}}"
```

Cloud Spanner 編の手順で利用した環境変数も利用します。
Cloud Spanner 編で設定している名前を事前に入力してありますが、任意の値に変更している場合は、そちらに合わせて設定してください。
※Cloud Shell の接続が切れた場合も実行してください。

```shell
export PROJECT_ID="{{project-id}}"
export INSTANCE_ID="{{instance_id}}"
export DATABASE_ID="{{database_id}}"
export SA_NAME="{{sa_name}}"
```

Cloud Run へアプリケーションをデプロイする際、リージョンの指定が必要です。
今回は Cloud Spanner のインスタンスと同じリージョンを指定しておきましょう。
```bash
export LOCATION="{{region}}"
```

### gcloud ツールの設定
gcloud ツールのプロジェクト設定を行います。
※プロジェクト ID が黄色文字で表示されている方はスキップして構いません。
```bash
gcloud config set project ${PROJECT_ID}
```

### APIの有効化
Cloud Run編で利用する API を有効化します。

```bash
gcloud services enable \
artifactregistry.googleapis.com \
run.googleapis.com \
cloudbuild.googleapis.com
```

## [演習]2. Dockerfile を使用してローカルでコンテナを作成、Artifact Registry 経由でデプロイする（先に実施する作業
### **リポジトリを作成（Artifact Registry）**

リポジトリを作成します。
```bash
gcloud artifacts repositories create ${REPOSITORY_NAME} --repository-format=docker --location=${LOCATION} --description="Docker repository for Cloud Run hands-on"
```

念の為、レポジトリが作成されたことを確認します。
```bash
gcloud artifacts repositories list
```
※[コンソール](https://console.cloud.google.com/artifacts)から、リポジトリの確認が可能です。

リポジトリにコンテナイメージを Push するための権限を付与
```bash
gcloud auth configure-docker asia-northeast1-docker.pkg.dev
```

## [解説]3. コンテナイメージの作成と Cloud Run へのデプロイ
スライドでご紹介します。

## [演習]2. Dockerfile を使用してローカルでコンテナを作成、Artifact Registry 経由でデプロイする（続き

### **1. コンテナイメージを作成**

clone したディレクトリに移動します。
```bash
cd spanner-sqlalchemy-demo 
```

docker build コマンドで、コンテナイメージを作成します。
```bash
docker build -t asia-northeast1-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY_NAME}/spanner-sqlalchemy-demo:1.0.0 .
```

### **2. コンテナイメージを、Artifact Registry に Push
```bash
docker push asia-northeast1-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY_NAME}/spanner-sqlalchemy-demo:1.0.0
```

### **3. Cloud Runへデプロイ**
```bash
gcloud run deploy spanner-sqlalchemy-demo \
--image asia-northeast1-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY_NAME}/spanner-sqlalchemy-demo:1.0.0 \
--allow-unauthenticated \
--set-env-vars=PROJECT_ID=${PROJECT_ID},INSTANCE_ID=${INSTANCE_ID},DATABASE_ID=${DATABASE_ID} \
--service-account=${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com \
--region=${LOCATION} 
```

### **4. サービスの動作確認**

```bash
APP_URL=$(gcloud run services describe spanner-sqlalchemy-demo --region=${LOCATION} --format json | jq -r '.status.address.url')
curl ${APP_URL}/run-info/ && echo
```

### **5. サービスの削除**

```bash
gcloud run services delete spanner-sqlalchemy-demo --quiet
```

## [解説]4. サービスアカウント
いま、みなさんが Cloud Run にデプロイしたアプリケーションは
Cloud Spannerにも接続ができています。
Cloud Run から Cloud Spanner へはサービスアカウントを利用して接続しています。

## [演習]5. Buildpacks、Cloud Buildを使用してデプロイする

### **1. Dockerfile の削除（移動）**

Dockerfile 無しでデプロイできることを確かめるために、Dockerfile を退避します。

```bash
mv Dockerfile ../
```

**ヒント**: Buildpacks というソフトウェアを使い、Dockerfile 無しでのデプロイを実現しています。
詳細は[こちら](https://cloud.google.com/blog/ja/products/containers-kubernetes/google-cloud-now-supports-buildpacks)を参照してください。

### **2. 一括でデプロイ**

Cloud Run のデプロイ先のリージョンを指定します。
```bash
gcloud config set run/region ${LOCATION}
```

以下のコマンドで、一括デプロイが可能です。
```bash
gcloud run deploy spanner-sqlalchemy-demo --source ./ --allow-unauthenticated
```

**Tips**: gcloud config系の便利コマンド
```shell
## 設定を確認する
gcloud config list

## 設定セットを利用する
gcloud config configurations list
gcloud config configurations create <config name>
gcloud config configurations activate <config name>
```

## [解説]6. トラフィックコントロール
スライドでご紹介します。

## [演習]7. カナリアリリース

Cloud Run でカナリアリリースを実現する場合、新リビジョンをトラフィックを流さない状態でデプロイし、徐々にトラフィックを流すように設定します。

```bash
 gcloud run deploy spanner-sqlalchemy-demo --source ./ --allow-unauthenticated  --no-traffic
```

この時点では、１つ前ののリビジョンにトラフィックがルーティングされており、新しいアプリケーションは公開されていません。以下のコマンドで確認します。

```bash
APP_URL=$(gcloud run services describe spanner-sqlalchemy-demo --format json | jq -r '.status.address.url')
curl ${APP_URL}/run-info/ && echo
```

最新のリビジョンと、１つ前のリビジョンを取得して起きましょう。
```bash
export NEW_REV=$(gcloud run revisions list --format json | jq -r '.[].metadata.name' | grep 'spanner-sqlalchemy-demo' | sort -r | sed -n 1p)
export OLD_REV=$(gcloud run revisions list --format json | jq -r '.[].metadata.name' | grep 'spanner-sqlalchemy-demo' | sort -r | sed -n 2p)
echo NEW:${NEW_REV}
echo OLD:${OLD_REV}
```

新リビジョンが10%、旧リビジョンが90%の割合で、トラフィックを分割します。
```bash
gcloud run services update-traffic spanner-sqlalchemy-demo --to-revisions=${NEW_REV}=10,${OLD_REV}=90
```

[コンソール](https://console.cloud.google.com/run/detail/{{region}}/spanner-sqlalchemy-demo/revisions)を確認し、最新のリビジョンにはトラフィックが 10% となっていることを確認します。

また複数回、/runinfo/にアクセスして、トラフィックが分割されているか確認してみましょう。
```
while true; do curl ${APP_URL}/run-info/ && echo;sleep 0.5s; done
```
※Ctrl + c で停止してください。

## [演習]8. ブルーグリーンデプロイ

解説で紹介した、コールドスタートを回避するブルーグリーンデプロイを実施してみましょう。

一度新しいアプリケーションをデプロイしトラフィックを向けておきます。
Minimum Instances も設定しておきましょう。
こちらが、ブルーグリーンデプロイにおけるブルー環境となります。
```shell
gcloud run deploy spanner-sqlalchemy-demo --source ./ --allow-unauthenticated --min-instances=3
```

再度アプリケーションをDeployします。
こちらがは、ブルーグリーンデプロイにおけるグリーン環境となります。
```bash
 gcloud run deploy spanner-sqlalchemy-demo --source ./ --allow-unauthenticated  \
 --no-traffic \
 --tag=abcdegg \
 --min-instances=3
```
[コンソール](https://console.cloud.google.com/run/detail/{{region}}/spanner-sqlalchemy-demo/revisions)を確認し、最新のリビジョンにはトラフィックが 0% となっていることを確認します。

また [Cloud Monitoring](https://console.cloud.google.com/monitoring/metrics-explorer?pageState=%7B%22xyChart%22:%7B%22dataSets%22:%5B%7B%22timeSeriesFilter%22:%7B%22filter%22:%22metric.type%3D%5C%22run.googleapis.com%2Fcontainer%2Finstance_count%5C%22%20resource.type%3D%5C%22cloud_run_revision%5C%22%20resource.label.%5C%22service_name%5C%22%3D%5C%22spanner-sqlalchemy-demo%5C%22%20resource.label.%5C%22project_id%5C%22%3D%5C%22{{project-id}}%5C%22%20resource.label.%5C%22location%5C%22%3D%5C%22{{region}}%5C%22%22,%22minAlignmentPeriod%22:%2260s%22,%22aggregations%22:%5B%7B%22perSeriesAligner%22:%22ALIGN_MAX%22,%22crossSeriesReducer%22:%22REDUCE_SUM%22,%22alignmentPeriod%22:%2260s%22,%22groupByFields%22:%5B%22metric.label.%5C%22state%5C%22%22,%22resource.label.%5C%22service_name%5C%22%22,%22resource.label.%5C%22revision_name%5C%22%22%5D%7D,%7B%22perSeriesAligner%22:%22ALIGN_NONE%22,%22crossSeriesReducer%22:%22REDUCE_NONE%22,%22alignmentPeriod%22:%2260s%22,%22groupByFields%22:%5B%5D%7D%5D%7D,%22targetAxis%22:%22Y1%22,%22plotType%22:%22LINE%22%7D%5D,%22options%22:%7B%22mode%22:%22COLOR%22%7D,%22constantLines%22:%5B%5D,%22timeshiftDuration%22:%220s%22,%22y1Axis%22:%7B%22label%22:%22y1Axis%22,%22scale%22:%22LINEAR%22%7D%7D,%22isAutoRefresh%22:true,%22timeSelection%22:%7B%22timeRange%22:%221h%22%7D%7D&project={{project-id}}) で、コンテナインスタンスの数が、どのように変化しているかも確認してみましょう。




## [解説]9. より実践的な使い方
スライドでご紹介します。

## [演習]10. 環境のクリーンアップ

すべての演習が終わったら、リソースを削除します。

### 1.**プロジェクトを削除できる方**

プロジェクトごと削除します。
```
gcloud projects delete ${PROJECT_ID}
```

### 2.**プロジェクトを削除できない方**

Artifact Registry リポジトリを削除します。
```shell
gcloud artifacts repositories delete cloud-run-source-deploy
gcloud artifacts repositories delete ${REPOSITORY_NAME}
```

Cloud Run アプリケーションを削除します。
```shell
gcloud run services delete spanner-sqlalchemy-demo
```

Cloud Storage のバケットを削除します。
```shell
gcloud alpha storage delete $(gcloud alpha storage ls) --recursive
```

Google Service Account を削除します。
※これで、Cloud Shell に残っているサービス アカウント キーも無効となります。
```shell
gcloud iam service-accounts delete ${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com
```


Cloud Spanner のインスタンスを削除します。
```shell
gcloud spanner instances delete ${INSTANCE_ID}
```

## **Thank You!**

以上で、今回の Cloud Run ハンズオンは完了です。
おつかれさまでした！