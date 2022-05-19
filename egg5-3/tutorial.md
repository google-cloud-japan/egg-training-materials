# EGG ハンズオン #5-3

## Google Cloud プロジェクトの選択

ハンズオンを行う Google Cloud プロジェクトを作成し、 Google Cloud プロジェクトを選択して **Start/開始** をクリックしてください。

**なるべく新しいプロジェクトを作成してください。**

<walkthrough-project-setup>
</walkthrough-project-setup>

## [解説] ハンズオンの内容

### **内容と目的**

本ハンズオンでは、Datastream を触ったことない方向けに、Cloud SQL インスタンスを立てて Change Data Capture(CDC) を体験していただきます。

本ハンズオンを通じて、Google Cloud 上での CDC の最初の 1 歩目のイメージを掴んでもらうことが目的です。

本ハンズオンで目指す、システムの構成は以下の通りです。

![システム構成1](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/goal1.png?raw=true)

### **前提条件**

本ハンズオンははじめて Datastream を触られる方を想定しておりますが、Datastream の基本的なコンセプトや、Cloud SQL の詳細などは、ハンズオン中では説明しません。
事前知識がなくとも本ハンズオンの進行には影響ありませんが、Datastream の基本コンセプトについては、Coursera などの教材を使い学んでいただくことをお勧めします。 

## [解説] 1. ハンズオンで使用するスキーマの説明

今回のハンズオンでは以下のように、1つのテーブルを利用します。これは、あるゲームにおいて、ゲームのプレイヤー情報やイベント情報を管理するテーブルに相当するものを表現しています。

![今回利用するスキーマ](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/1-1.png?raw=true)

## [演習] 2. Cloud SQL インスタンスの作成

現在 Cloud Shell と Editor の画面が開かれている状態だと思いますが、[Google Cloud のコンソール](https://console.cloud.google.com/) を開いていない場合は、コンソールの画面を開いてください。

過去に他の E.G.G のハンズオンを同一環境で実施している場合、***egg-training-materials-0*** や ***egg-training-materials-1*** のように末尾に数字がついたディレクトリを、今回の egg5- 用のディレクトリとしている場合があります。誤って過去のハンズオンで使ったディレクトリを使ってしまわぬよう、**今いる今回利用してるディレクトリを覚えておいてください。**

### **Cloud SQL インスタンスの作成**

![システム構成2](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/goal2.png?raw=true)

#### **gcloud CLI の設定**

Cloud SQL インスタンスは gcloud CLI を使用して作成します。その前に gcloud CLI の設定を行います。
以下のコマンドを Cloud Shell で実行し、プロジェクト ID を設定してください。

```bash
gcloud config set project {{project-id}}
```

続いて、環境変数 `GOOGLE_CLOUD_PROJECT` に、各自で利用しているプロジェクトの ID を格納しておきます。以下のコマンドを、Cloud Shell のターミナルで実行してください。

```bash
export GOOGLE_CLOUD_PROJECT=$(gcloud config list project --format "value(core.project)")
```

以下のコマンドで、正しく格納されているか確認してください。
echo の結果が空の場合、1つ前の手順で gcloud コマンドでプロジェクト ID を取得できていません。gcloud config set project コマンドで現在お使いのプロジェクトを正しく設定してくださ
い。

```bash
echo ${GOOGLE_CLOUD_PROJECT}
```

#### **プライベートサービスアクセスの構成**

Cloud SQL は Public IP を持つタイプと Private IP を持つタイプ または両方のいずれか一つの接続方法を選ぶ必要があります。
本ハンズオンでは、Private IP を持つタイプの Cloud SQL インスタンスを作成します。
Private IP を持つ場合、[プライベートサービスアクセス](https://cloud.google.com/sql/docs/mysql/configure-private-services-access) を構成します。

プライベートサービスアクセスを有効にして、次の構成図の構成を作成します。

![プライベートサービスアクセス](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/2-1.png?raw=true)

Compute 系の API を使うため、API を有効化します。

```bash
gcloud services enable compute.googleapis.com
```

Cloud SQL の Private IP が利用する VPC ネットワークを作成します。

```bash
gcloud compute networks create cloudsql --subnet-mode auto
```

VPC ネットワークの作成には数分かかります。

`asia-northeast1` リージョンのサブネットの Private Google Access を有効化します。

```bash
gcloud compute networks subnets update cloudsql \
    --region=asia-northeast1 \
    --enable-private-ip-google-access
```

プライベート サービス アクセスの構成プロセスとして、Cloud SQL インスタンス用に IP アドレス範囲を割り振ります。

```bash
gcloud compute addresses create google-managed-services-cloudsql --global \
    --purpose=VPC_PEERING \
    --addresses=192.168.0.0 \
    --prefix-length=16 \
    --network=projects/${GOOGLE_CLOUD_PROJECT}/global/networks/cloudsql
```

VPC Peering を実行するために、Service Networking の API を有効化します。

```bash
gcloud services enable servicenetworking.googleapis.com
```

プライベート接続を作成します。

```bash
gcloud services vpc-peerings connect \
    --service=servicenetworking.googleapis.com \
    --ranges=google-managed-services-cloudsql \
    --network=cloudsql \
    --project=${GOOGLE_CLOUD_PROJECT}
```

これで、プライベートサービスアクセスの構成が完了しました。
次は Cloud SQL for MySQL インスタンスを作成します。

プライベート接続の作成には数分かかります。

#### **Cloud SQL for MySQL インスタンスの作成**

Cloud SQL の API を有効化します。

```bash
gcloud services enable sqladmin.googleapis.com
```

それでは Cloud SQL for MySQL インスタンスを gcloud コマンドで作成します。

```bash
MYSQL_INSTANCE=mysql-db
gcloud beta sql instances create ${MYSQL_INSTANCE} \
    --cpu=2 --memory=10GB \
    --no-assign-ip \
    --network=projects/${GOOGLE_CLOUD_PROJECT}/global/networks/cloudsql \
    --allocated-ip-range-name=google-managed-services-cloudsql \
    --enable-bin-log \
    --region=asia-northeast1 \
    --database-version=MYSQL_8_0 \
    --root-password password123
```

`--no-assign-ip` と `--network` フラグをつけることで、Private IP を持つ Cloud SQL インスタンスが作成されます。代わりに Public IP は付与されません。
`--allocated-ip-range-name` フラグは必要に応じて付けることで、プライベート アドレス範囲の名前を指定出来ます。
また、`--enable-bin-log` フラグは Datastream に連携する場合は必須になります。

Cloud SQL インスタンスの作成は数分かかります。

## [演習] 3. Cloud Storage / Cloud Pub/Sub リソースの作成

### **Cloud Storage バケットの作成**

次の演習では Cloud Storage のバケットを作成します。

![システム構成3](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/goal3.png?raw=true)

これは Datastream がソース MySQL データベースからスキーマ、テーブル、データをストリーミングする宛先バケットです。

```bash
gsutil mb -l asia-northeast1 gs://${GOOGLE_CLOUD_PROJECT}
```

### **Cloud Storage バケットの Pub/Sub 通知を有効にする**

続けて、作成した Cloud Storage バケットの Pub/Sub 通知を有効にします。

![システム構成4](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/goal4.png?raw=true)

これにより、Datastream がバケットに新しいファイルに書き込むと、Dataflow が使用する通知を送信するように、バケットを構成します。これらのファイルには、Datastream がソース MySQL データベースからバケットにストリーミングするデータへの変更が含まれています。

```bash
gcloud pubsub topics create datastream
gcloud pubsub subscriptions create datastream-subscription --topic=datastream
gsutil notification create -f "json" -p "data/" -t "datastream" "gs://${GOOGLE_CLOUD_PROJECT}"
```

これで Pub/Sub のトピックが作成され、またバケットのオブジェクトが更新されると Pub/Sub に通知が飛ぶように構成されました。

Datastream → Cloud Storage → Cloud Pub/Sub という流れのパイプラインが作成されました。
ハンズオンの後半では、Cloud Dataflow → BigQuery へのパイプラインも引き続き作成します。

## [演習] 4. Cloud SQL へのデータのインポート

Cloud SQL にデータをインポートします。
実行する SQL ファイルを Cloud Storage 上にアップロードします。

実行ファイルをまずは Cloud Shell 上に作成します。

```
cat <<EOF >>create_mysql.sql
CREATE DATABASE IF NOT EXISTS game;
USE game;
CREATE TABLE IF NOT EXISTS game.game_event (
game_id VARCHAR(54) NOT NULL PRIMARY KEY,
game_server VARCHAR(36),
game_type VARCHAR(19),
game_map VARCHAR(10),
event_datetime DATETIME,
player VARCHAR(17),
killed VARCHAR(17),
weapon VARCHAR(11),
x_cord INT,
y_cord INT
);
INSERT INTO game.game_event (game_id, game_server, game_type, game_map, event_datetime, player, killed, weapon, x_cord, y_cord) VALUES
('wornoutZebra7-9846610-3946251292168118268992823970','Jeff & Julius Resurrection Server','Keyhunt','boil','2019-03-03 02:34:34','goofyWhiting7','boastfulPonie4','Hagar',29,54),
('enviousCaviar1-2811973-5883011126555021604525054585','[WTWRP] Votable','Keyhunt','atelier','2019-03-01 03:19:30','needfulTermite0','abjectTermite7','Hagar',83,82),
('spiritedTeal8-2651047-991418688923765348873793999','exe.pub | Relaxed Running | CTS/XDF','Keyhunt','atelier','2019-03-03 08:10:31','murkyDinosaur5','puzzledPepper6','Hagar',6,33),
('innocentIguana4-3029130-6481117659747845226335614333','[WTWRP] Deathmatch','Complete This Stage','atelier','2019-02-09 03:36:51','resolvedDove6','worriedEagle0','Hagar',86,19),
('mellowRelish7-3773375-501322700940889343206866273','[WTWRP] Deathmatch','Keyhunt','atelier','2019-04-22 07:25:33','importedMuesli6','awedPlover0','Hagar',1,55),
('exactingSardines4-4698944-4718335854529873060120395926','Corcs do Harleys Xonotic Server','Keyhunt','boil','2019-03-18 03:32:35','dopeyThrushe0','pitifulBobolink2','Hagar',43,50),
('ashamedIcecream5-8556566-2736335361664276838110754239','[PAC] Pickup','Keyhunt','atelier','2019-03-18 03:37:06','lyingLard2','amusedMallard3','Hagar',1,60),
('vengefulPup3-8239445-4214337680396181440470745962','exe.pub | Relaxed Running | CTS/XDF','Deathmatch','atelier','2019-04-05 03:03:40','sugaryPie3','artisticOrange2','Hagar',77,18),
('enviousRuffs6-7892691-1550528495727726385159862586','Corcs do Harleys Xonotic Server','Keyhunt','atelier','2019-02-10 03:52:03','lovesickIcecream3','murkyTermite1','Hagar',29,36),
('sheepishSalami1-2471622-138762091842251200148673610','[PAC] Pickup','Keyhunt','atelier','2019-03-01 03:55:55','stressedOatmeal2','bubblyLlama5','Hagar',34,31);
EOF
```

Cloud Shell 上に作成した `create_mysql.sql` ファイルを Cloud Storage に上げてから、Cloud SQL インスタンスにインポートします。

```bash
SERVICE_ACCOUNT=$(gcloud sql instances describe ${MYSQL_INSTANCE} | grep serviceAccountEmailAddress | awk '{print $2;}')
gsutil cp create_mysql.sql gs://${GOOGLE_CLOUD_PROJECT}/resources/create_mysql.sql
gsutil iam ch serviceAccount:${SERVICE_ACCOUNT}:objectViewer gs://${GOOGLE_CLOUD_PROJECT}
gcloud sql import sql ${MYSQL_INSTANCE} gs://${GOOGLE_CLOUD_PROJECT}/resources/create_mysql.sql --quiet
```

これで、Cloud SQL for MySQL インスタンスに本ハンズオンで利用する `game_event` テーブルへのデータ入力が完了しました。

## [演習] 5-1. Datastream リソースの作成 (権限設定)

Datastream を利用するにあたって、「プライベート接続構成」「接続プロファイル」「ストリーム」の 3 つのリソースを作成します。

プライベート接続構成は、VPC ピアリングを使った構成の時に利用します。
本ハンズオンでは、ハンズオン前半に作った VPC / サブネットを繋げることで、Datastream と VPC を接続します。
ただし、下記の注意事項のように、Datastream と Cloud SQL のネットワークは直接繋ぐことができないため、中間に Cloud SQL Auth Proxy サーバーを立てます。

> **Notice!!**  
> プライベート IP アドレスを使用するように Cloud SQL インスタンスを構成する場合は、VPC ネットワークと、Cloud SQL インスタンスが存在する基盤となる Google が管理する VPC ネットワークとの間の VPC ピアリング接続を使用します。
>
> Datastream のネットワークは Cloud SQL のプライベート サービス ネットワークと直接ピアリングできず、VPC ピアリングが推移的ではないため、Datastream から Cloud SQL インスタンスへの接続をブリッジするには Cloud SQL Auth プロキシが必要です。
>
> https://cloud.google.com/datastream/docs/private-connectivity?#cloud-sql-auth-proxy

![プロキシー](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/datastream-cloudsql-auth-proxy.png?raw=true)

### **Cloud SQL Auth Proxy サーバーの作成**

![システム構成5](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/goal5.png?raw=true)

作成する Cloud SQL Auth Proxy サーバーの構成は下図の通りです。

![CloudSQL Auth Proxy Server1](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/cloudsql-auth-proxy-1.png?raw=true)

Datastream → Proxy VM → Cloud SQL の中間に存在する、Proxy サーバーとその周辺リソースを作成します。

![CloudSQL Auth Proxy Server2](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/cloudsql-auth-proxy-2.png?raw=true)

Datastream → Proxy VM 間の通信を許可するファイアウォール ルールを作成します。

```bash
gcloud compute firewall-rules create allow-datastream \
    --direction=INGRESS \
    --priority=1000 \
    --network=cloudsql \
    --action=ALLOW \
    --rules=tcp:3306 \
    --source-ranges=10.120.0.0/20 \
    --target-tags=allow-datastream
```

この `10.120.0.0/20` はハンズオンの以降の手順「プライベート接続構成」で設定する Datastream に割り当てられる IP アドレス範囲になります。
（この IP アドレス範囲は任意の値です）   
`allow-datastream` というネットワークタグが付与されているインスタンスにだけ通信を許可します。

続けて、Cloud SQL Auth Proxy を実行する Compute Engine インスタンスに割り当てられている Service Account に権限を付与します。

```bash
SERVICE_ACCOUNT=$(gcloud iam service-accounts list --filter="displayName:Compute Engine default service account" --format="value(email)")
```

Cloud SQL Client の権限を付与します。これは Cloud SQL Auth Proxy からのアクセスに利用します。

```bash
gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} \
    --member serviceAccount:${SERVICE_ACCOUNT} \
    --role roles/cloudsql.client
```

Logging Writer の権限を付与します。これは Compute Engine のスタートアップ スクリプトで利用します。

```bash
gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} \
    --member serviceAccount:${SERVICE_ACCOUNT} \
    --role roles/logging.logWriter
```

Dataflow Worker の権限を付与します。これは Dataflow Job の実行に利用します。

```bash
gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} \
    --member serviceAccount:${SERVICE_ACCOUNT} \
    --role roles/dataflow.worker
```

Datastream Viewer の権限を付与します。これは Dataflow Job での Datastream Schema 取得に利用します。

```bash
gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} \
    --member serviceAccount:${SERVICE_ACCOUNT} \
    --role roles/datastream.viewer
```

Pub/Sub Editor の権限を付与します。これは Dataflow Job の実行時の Pub/Sub Subscription Pull で利用します。

```bash
gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} \
    --member serviceAccount:${SERVICE_ACCOUNT} \
    --role roles/pubsub.editor
```

Pub/Sub Subscriber の権限を付与します。これは Dataflow Job の実行時の Pub/Sub Subscribe で利用します。

```bash
gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} \
    --member serviceAccount:${SERVICE_ACCOUNT} \
    --role roles/pubsub.subscriber
```

Pub/Sub Viewer の権限を付与します。これは Dataflow Job の実行時の Pub/Sub Topic と Subscription の取得で利用します。

```bash
gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} \
    --member serviceAccount:${SERVICE_ACCOUNT} \
    --role roles/pubsub.viewer
```

Storage Object Viewer の権限を付与します。これは Dataflow Job の実行時の Storage Object List で利用します。

```bash
gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} \
    --member serviceAccount:${SERVICE_ACCOUNT} \
    --role roles/storage.objectViewer
```

BigQuery DataEditor の権限を付与します。これは Dataflow Job の実行時の BigQuery テーブルへの書き込みに利用します。

```bash
gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} \
    --member serviceAccount:${SERVICE_ACCOUNT} \
    --role roles/bigquery.dataEditor
```

BigQuery JobUser の権限を付与します。これは Dataflow Job の実行時の BigQuery Job 実行に利用します。

```bash
gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} \
    --member serviceAccount:${SERVICE_ACCOUNT} \
    --role roles/bigquery.jobUser
```

## [演習] 5-2. Datastream リソースの作成 (ネットワーク設定)

本ハンズオンでは、よりセキュアになるように、Compute Engine に Public IP を割り当てず、Private IP のみを割り当てます。
そのため、Compute Engine インスタンスから外部への通信（必要ミドルウェアのインストール）には、Cloud NAT を経由するようにします。

![CloudSQL Auth Proxy Server3](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/cloudsql-auth-proxy-3.png?raw=true)

Cloud Router を作成します。この Router は Cloud NAT を作る際に利用します。

```bash
gcloud compute routers create cloudsql --network=cloudsql --region=asia-northeast1
```

Cloud Router を作成する際に、本ハンズオンの前半で作成した `cloudsql` ネットワークを指定します。
今回作った Cloud Router を指定して Cloud NAT を作成します。

```bash
gcloud compute routers nats create cloudsql \
    --router=cloudsql \
    --auto-allocate-nat-external-ips \
    --region asia-northeast1 \
    --nat-custom-subnet-ip-ranges=cloudsql
```

これで、Compute Engine インスタンスが外部に通信する際に、Cloud NAT を経由するようになりました。

![CloudSQL Auth Proxy Server4](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/cloudsql-auth-proxy-4.png?raw=true)

それでは、Cloud SQL Auth Proxy を実行する Compute Engine インスタンスを作成します。
起動と同時に、スタートアップスクリプトとして `cloud_sql_proxy` を実行させます。 

```
gcloud compute instances create cloudsql-proxy \
    --image-family=debian-10 \
    --image-project=debian-cloud \
    --zone=asia-northeast1-c \
    --machine-type=n2-standard-2 \
    --scopes=sql-admin,logging-write \
    --tags=allow-datastream \
    --network=cloudsql \
    --subnet=cloudsql \
    --no-address \
    --shielded-secure-boot \
    --metadata=startup-script="#! /bin/bash
      sudo apt -y install wget
      wget https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 -O /usr/local/bin/cloud_sql_proxy
      chmod +x /usr/local/bin/cloud_sql_proxy
      cloud_sql_proxy -instances=${GOOGLE_CLOUD_PROJECT}:asia-northeast1:mysql-db=tcp:0.0.0.0:3306"
```

ネットワークタグ `allow-datastream` を指定し、Datastream からの通信を受け取れるファイアウォールを適用しています。
また、Cloud SQL 用に作成したネットワーク `cloudsql` を指定し、`--no-address` で Public IP が付与されない（＝Private IP のみが付与される）ようにします。
`--metadata=startup-script` で `cloud_sql_proxy` が起動するように設定します。このスタートアップスクリプトが起動から完了するまで 1 分ほど待ちます。

`gcloud compute instances create` が成功すると、`INTERNAL_IP` が出力されます。**`INTERNAL_IP` は Datastream の 接続プロファイルを作成するときに利用するので控えておいてください。**

VM の起動が完了すると、次の構成の状態になります。

![Cloud SQL Auth Proxy](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/cloudsql-auth-proxy.png?raw=true)

## [演習] 5-3. Datastream リソースの作成 (接続プロファイル設定)

### **プライベート接続構成の作成**

ここからは Datastream のリソースを作成します。

![システム構成6](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/goal6.png?raw=true)

プライベート接続構成を作成します。

![Datastreamメニュー](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/5-1.png?raw=true)

1. ナビゲーションメニューから「データストリーム」を選択

![接続プロファイルメニュー](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/5-2.png?raw=true)

2. 「接続プロファイル」を選択

マーケットプレイスの「Datastream API」を有効化するための画面が表示されます。

![マーケットプレイス](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/5-3.png?raw=true)

「有効にする」を選択します。

Cloud Console のホーム画面に戻ってしまったら、またナビゲーションメニュー「データストリーム」から「プライベート接続構成」を選択してください。

![プライベート接続構成遷移](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/5-4.png?raw=true)
![構成を作成](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/5-5.png?raw=true)

「構成を作成」を選択します。

![プライベート接続構成](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/5-6.png?raw=true)

以下の内容で設定し、「作成」を選択します。
1. 接続プロファイルの名前：`private-mysql-cp`
2. 接続プロファイル ID：`private-mysql-cp`
3. リージョン：`asia-northeast1 (東京)`
4. VPC：`cloudsql`
5. IPアドレス範囲：`10.120.0.0/20`

「5. IPアドレス範囲」で指定する `10.120.0.0/20` は演習「Cloud SQL Auth Proxy サーバーの作成」で作成したファイアウォールの Source IP Range と一致している必要があります。
プライベート接続構成の作成には数分かかります。

ここで作成したプライベート接続構成は、次の接続プロファイルで利用します。

### **MySQL 接続プロファイルの作成**

続けて、Cloud SQL for MySQL インスタンスへの接続プロファイルを作成します。

「接続プロファイル」のメニューから「作成」を選択します。

![接続プロファイルメニュー](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/5-2.png?raw=true)
![接続プロファイル作成](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/5-7.png?raw=true)

接続プロファイルを作成する画面に遷移すると、どのサポートされているプロファイル タイプを選ぶかを選択します。

![MYSQL接続プロファイル](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/5-8.png?raw=true)

「MySQL」を選択します。

![MYSQL接続情報入力](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/5-9.png?raw=true)

以下の内容で設定します。
1. 接続プロファイルの名前：`mysql-cp`
2. 接続プロファイル ID：`mysql-cp`
3. リージョン：`asia-northeast1 (東京)`
4. ホスト名または IP：`<Proxy VM の INTERNAL_IP>`
5. ポート：`3306`
6. ユーザー名：`root`
7. パスワード：`password123`

「4. ホスト名または IP」に入力する `INTERNAL_IP` は次のコマンドでも確認できます。

```bash
gcloud compute instances describe cloudsql-proxy --zone asia-northeast1-c --format="value(networkInterfaces.networkIP)"
```

「接続設定の定義」画面の下部の「続行」を選択します。

![ソースへの接続を保護する](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/5-10.png?raw=true)

何も選択せず、「続行」を選択します。

![MySQL接続方法の定義-接続方法](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/5-11.png?raw=true)

「接続方法の定義」で「接続方法：プライベート接続（VPC ピアリング）」を選択します。

![MySQL接続方法の定義-プライベート接続構成](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/5-12.png?raw=true)

「プライベート接続構成」に演習「プライベート接続構成の作成」で作成した「private-mysql-cp」を選択します。

`private-mysql-cp` を選択したら、「続行」を選択します。

![MySQL接続方法の定義-続行](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/5-13.png?raw=true)

接続プロファイルの作成の前に、Datastream → Data Source への接続テストを実施できます。

「テストを実行」を選択します。本ハンズオンでは、Datastream → Cloud SQL Auth Proxy サーバー → Cloud SQL への接続テストになります。

![MySQL接続テストの実行](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/5-14.png?raw=true)
![MySQL接続テストの実行中](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/5-15.png?raw=true)

接続テストが成功すると、「テスト成功」と出力されます。もし失敗した場合はエラーメッセージが出力されます。

![MySQL接続テスト成功](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/5-16.png?raw=true)

接続テストが成功したら、「作成」を選択し、接続プロファイルを作成します。

![MySQL接続プロファイル作成](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/5-17.png?raw=true)
![mysql-cp接続プロファイル](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/5-18.png?raw=true)

続けて Cloud Storage 用の接続プロファイルを作成するため、「接続プロファイルの詳細」画面上部の「←」を選択して「接続プロファイル」画面に戻ります。

### **Cloud Storage 接続プロファイルの作成**

続けて Cloud Storage 用の接続プロファイルを作成するため、「プロファイルの作成」を選択します。

![プロファイルの作成](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/5-19.png?raw=true)

![GCS接続プロファイル](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/5-20.png?raw=true)

「Cloud Storage」を選択します。

![GCS接続プロファイル入力](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/5-21.png?raw=true)

以下の内容で設定します。
1. 接続プロファイルの名前：`gcs-cp`
2. 接続プロファイル ID：`gcs-cp`
3. リージョン：`asia-northeast1 (東京)`
4. バケット名：`<GOOGLE_CLOUD_PROJECTと同名のバケット>` ※ 「参照」から選択
5. 接続プロファイルのパス接頭辞：`/data`

「4. バケット名」は「参照」を選択し、`${GOOGLE_CLOUD_PROJECT}` と同名のバケットを選び、「選択」を選択します。

![GCSバケット選択](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/5-22.png?raw=true)

入力が完了したら、「作成」を選択します。

![GCS接続プロファイル作成](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/5-23.png?raw=true)

「mysql-cp」「gcs-cp」接続プロファイルが作成できたら、接続プロファイルに接続する「ストリーム」を作成します。

## [演習] 5-4. Datastream リソースの作成 (ストリーム設定)

### **ストリームの作成**

接続プロファイルに接続する「ストリーム」を作成するため、ナビゲーションメニューから「ストリーム」を選択します。

![ストリームメニュー](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/5-24.png?raw=true)

「ストリームの作成」を選択します。

![ストリームの作成](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/5-25.png?raw=true)

ストリームには、これまで作成した接続プロファイルを指定します。

![ストリームの詳細の定義](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/5-26.png?raw=true)

以下の内容で設定します。
1. ストリーム の名前：`cloudsql-stream`
2. ストリーム ID：`cloudsql-stream`
3. リージョン：`asia-northeast1 (東京)`
4. ソースタイプ：`MySQL`
5. 宛先の種類：`Cloud Storage`

![ストリームの詳細の定義-続行](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/5-27.png?raw=true)

「続行」を選択します。

「MySQL 接続プロファイルの定義」では、演習「MySQL 接続プロファイルの作成」で作成したプロファイルを指定します。
「ソース接続プロファイル」に「mysql-cp」を選択して、「続行」を選択します。

![ソース接続プロファイル](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/5-28.png?raw=true)

「ソースの構成」では、MySQL のどの Database を転送対象にするかを選択します。

「含めるオブジェクト」では、「特定のスキーマとテーブル」を選択し、スキーマとして本ハンズオンで作成した「game」DB と配下のテーブルを選択します。

![ソースの構成](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/5-29.png?raw=true)

「続行」を選択します。

![Cloud Storage 接続プロファイルの定義](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/5-30.png?raw=true)

「Cloud Storage 接続プロファイルの定義」の「宛先接続プロファイル」で、「gcs-cp」を選択し、「続行」を選択します。

![宛先の構成](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/5-31.png?raw=true)

「ストリームの宛先の構成」では何も変更せず、「続行」を選択します。

![確認と作成](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/5-32.png?raw=true)

「ストリームの詳細の確認と作成」の画面下部の「検証を実行」を選択することでエンドツーエンドの検証を行えます。
「検証を実行」を選択します。

![検証を実行](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/5-33.png?raw=true)

検証が成功したら、「作成して開始」を選択します。

![作成して開始](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/5-34.png?raw=true)

ダイアログが表示されるので、「作成して開始」を選択します。

![作成して開始](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/5-35.png?raw=true)

ストリームの作成と開始には数分ほどかかります。

![ストリームの詳細](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/5-36.png?raw=true)

ストリームの開始が始まると、Datastream → Proxy VM → Cloud SQL の CDC が始まります。

## [演習] 6. BigQuery 連携

ここからは、Datastream で ストリームしたデータを BigQuery に連携させます。

![システム構成7](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/goal7.png?raw=true)

### **BigQuery データセットの作成**

BigQuery データセット `game_event` を作成します。

```bash
bq mk --data_location=asia-northeast1 game_event
```

Datastream でストリームしたデータの最終宛先であるデータセットを作成しました。

### **Dataflow Job のデプロイ**

BigQuery へのデータの連携は Dataflow Job で行います。

![システム構成8](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/goal8.png?raw=true)

Dataflow の API を有効化します。

```bash
gcloud services enable dataflow.googleapis.com
```

Dataflow VM 間での通信を許可するファイアウォール ルールを作成します。このファイアウォール ルールは Dataflow Shuffle の通信に使います。

Dataflow VM 用の、内向き通信の許可ルールを作成します。

```
gcloud compute firewall-rules create allow-dataflow-vm-ingress \
    --action=allow \
    --direction=ingress \
    --network=cloudsql  \
    --target-tags=dataflow \
    --source-tags=dataflow \
    --priority=1000 \
    --rules tcp:12345-12346
```

Dataflow VM 用の、外向き通信の許可ルールを作成します。

```
gcloud compute firewall-rules create allow-dataflow-vm-egress \
    --network=cloudsql \
    --action=allow \
    --direction=egress \
    --target-tags=dataflow \
    --destination-ranges=10.146.0.0/20\
    --priority=1000  \
    --rules tcp:12345-12346
```

Dataflow Job のデプロイは gcloud コマンドで実行します。
Job の Template ファイルは事前に用意されているものを利用します。

```
gcloud beta dataflow flex-template run datastream-replication \
        --project="${GOOGLE_CLOUD_PROJECT}" \
        --region="asia-northeast1" \
        --template-file-gcs-location="gs://dataflow-templates-asia-northeast1/latest/flex/Cloud_Datastream_to_BigQuery" \
        --enable-streaming-engine \
        --network=cloudsql \
        --subnetwork=regions/asia-northeast1/subnetworks/cloudsql \
        --disable-public-ips \
        --additional-experiments=enable_secure_boot \
        --parameters \
inputFilePattern="gs://${GOOGLE_CLOUD_PROJECT}/data/",\
outputProjectId="${GOOGLE_CLOUD_PROJECT}",\
outputStagingDatasetTemplate="game_event",\
outputDatasetTemplate="game_event",\
outputStagingTableNameTemplate="{_metadata_table}_log",\
outputTableNameTemplate="{_metadata_table}",\
deadLetterQueueDirectory="gs://${GOOGLE_CLOUD_PROJECT}/dlq/",\
maxNumWorkers=2,\
autoscalingAlgorithm="THROUGHPUT_BASED",\
mergeFrequencyMinutes=2,\
inputFileFormat="avro",\
gcsPubSubSubscription="projects/${GOOGLE_CLOUD_PROJECT}/subscriptions/datastream-subscription"
```

Job の Template として、`Cloud_Datastream_to_BigQuery` Template を利用します。また、BigQuery の宛先データセットを `game_event` に指定します。

Job は開始から実行まで数分の時間がかかります。そのため、BigQuery への連携も数分ほどかかります。

Dataflow Job は gcloud または Cloud Console から確認できます。
Cloud Console から確認する場合は、ナビゲーションメニュー「Dataflow」→「ジョブ」から確認します。

![Dataflowメニュー](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/6-1.png?raw=true)

「Dataflow ジョブ」画面から「datastream-replication」のリンクを選択すると、ジョブの詳細や実行状況を確認できます。

![Dataflow Job](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/6-2.png?raw=true)

### **BigQuery データの確認**

Dataflow Job が成功すると、BigQuery のデータセット `game_event` にデータが連携されます。

ナビゲーションメニュー「BigQuery」を選択し、Cloud Console から確認します。

![BigQueryメニュー](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/6-3.png?raw=true)

Dataflow からデータが連携されるまでは、`game_event` データセット配下には何も表示されません。

![game_event dataset](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/6-4.png?raw=true)

データが連携されると、`game_event` テーブルと `game_event_log` テーブルが作成されます。

![game_event_log プレビュー](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/6-5.png?raw=true)

テーブル `game_event_log` を選択し、「プレビュー」タブを選択します。
「プレビュー」欄を見ると、Cloud SQL に保存されているデータが Datastream → Cloud Storage → Cloud Pub/Sub → Dataflow → BigQuery という経路を経て、データが連携されていることが確認できました。
`game_event_log` テーブルは、Datastream から受信するデータの変更をステージングするために使われます。

![game_event プレビュー](https://github.com/google-cloud-japan/egg-training-materials/blob/main/egg5-3/images/6-6.png?raw=true)

テーブル `game_event` を選択し、「プレビュー」タブを選択します。
`game_event_log` の時と同じようにデータが入っていることを確認できます。
`game_event` テーブルには、`game_event_log` テーブルにステージングされた変更がマージされ、ソース データベースのテーブルの 1 対 1 のレプリカが作成されます。

以上で、今回の Datastream ハンズオンは完了です。

## **Thank You!**

Cloud SQL → Cloud SQL Auth Proxy → Datastream → Cloud Storage → Cloud Pub/Sub → Dataflow → BigQuery という大きな Data Pipeline の流れを実感できましたでしょうか。

お疲れ様でした。
