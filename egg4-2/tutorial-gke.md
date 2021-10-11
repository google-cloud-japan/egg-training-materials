# EGG ハンズオン(Google Kubernetes Engine) #4-2

## Google Cloud プロジェクトの選択

ハンズオンを行う Google Cloud プロジェクトを選択して **Start/開始** をクリックしてください。

**なるべく新しいプロジェクトを作成してください。**

<walkthrough-project-setup>
</walkthrough-project-setup>

## [解説] ハンズオンの内容

### **内容と目的**

本ハンズオンでは、Google Kubernetes Engine を触ったことない方向けに、Kubernetes クラスタの作成から始め、コンテナのビルド・デプロイ・アクセスなどを行います。

Cloud Spanner にアクセスする Web アプリケーションを題材に、Workload Identity を利用し Service Account の鍵なしで Cloud Spanner にアクセスすることも試します。

本ハンズオンを通じて、 Google Kubernetes Engine を使ったアプリケーション開発における、最初の 1 歩目のイメージを掴んでもらうことが目的です。

次の図は、ハンズオンのシステム構成(最終構成)になります。

![](https://storage.googleapis.com/egg-resources/egg4-2/public/gke/0-1.png)


## Cloud Shell 環境の設定

現在 Cloud Shell と Editor の画面が開かれている状態だと思いますが、[Google Cloud のコンソール](https://console.cloud.google.com/) を開いていない場合は、コンソールの画面を開いてください。

Cloud Shell 上で今回のハンズオンで使うパスと、プロジェクト ID が正しく表示されていることを確認してください。以下のように、青文字のパスに続いて、かっこにくくられてプロジェクト ID が黄色文字で表示されています。このプロジェクト ID は各個人の環境でお使いのものに読み替えてください。

![](https://storage.googleapis.com/egg-resources/egg4/public/3-2.png)

もしプロジェクトID が表示されていない場合、以下の図の様に、青字のパスのみが表示されている状態だと思います。以下のコマンドを Cloud Shell で実行し、プロジェクトIDを設定してください。

![](https://storage.googleapis.com/egg-resources/egg4/public/3-3.png)

```bash
gcloud config set project {{project-id}}
``` 

続いて、環境変数 `GOOGLE_CLOUD_PROJECT` に、各自で利用しているプロジェクトの ID を格納しておきます。以下のコマンドを、Cloud Shell のターミナルで実行してください。

```bash
export GOOGLE_CLOUD_PROJECT=$(gcloud config list project --format "value(core.project)")
```

以下のコマンドで、正しく格納されているか確認してください。
echo の結果が空の場合、1 つ前の手順で gcloud コマンドでプロジェクト ID を取得できていません。gcloud config set project コマンドで現在お使いのプロジェクトを正しく設定してください。

```bash
echo $GOOGLE_CLOUD_PROJECT
```

また以下のコマンドで、現在いるディレクトリを確認してください。

```bash
pwd
```

以下のようなパスが表示されると思います。

```
/home/<あなたのユーザー名>/cloudshell_open/egg-training-materials/egg4-2
```

過去に他の E.G.G のハンズオンを同一環境で実施している場合、***egg-training-materials-0*** や ***egg-training-materials-1*** のように末尾に数字がついたディレクトリを、今回の egg4- 用のディレクトリとしている場合があります。誤って過去のハンズオンで使ったディレクトリを使ってしまわぬよう、**今いる今回利用してるディレクトリを覚えておいてください。**


## [演習] 1. Google API の有効化と Kubernetes クラスタの作成

### **API の有効化**

次のコマンドで、ハンズオンで利用する Google API を有効化します。

```bash
gcloud services enable cloudbuild.googleapis.com \
  sourcerepo.googleapis.com \
  containerregistry.googleapis.com \
  cloudresourcemanager.googleapis.com \
  container.googleapis.com \
  stackdriver.googleapis.com \
  cloudtrace.googleapis.com \
  cloudprofiler.googleapis.com \
  logging.googleapis.com
```

### **Kubernetes クラスタの作成**

API を有効化したら、Kubernetes クラスタを作成します。
次のコマンドを実行してください。

```bash
gcloud container --project "$GOOGLE_CLOUD_PROJECT" clusters create "cluster-1" \
  --zone "asia-northeast1-a" \
  --enable-autoupgrade \
  --image-type "COS" \
  --enable-ip-alias \
  --workload-pool=$GOOGLE_CLOUD_PROJECT.svc.id.goog
```

Kubernetes クラスタの作成には数分かかります。

Kubernetes クラスタが作成されると、[Cloud Console] - [Kubernetes Engine] - [クラスタ] から確認できます。

![](https://storage.googleapis.com/egg-resources/egg4-2/public/gke/1-1.png)

Kubernetes クラスタを作成したことで、現在のシステム構成は次のようになりました。

![](https://storage.googleapis.com/egg-resources/egg4-2/public/gke/1-2.png)

### **コマンド設定**

次のコマンドを実行して、コマンドの実行環境を設定します。

```bash
gcloud config set compute/zone asia-northeast1-a
gcloud config set container/cluster cluster-1
gcloud container clusters get-credentials cluster-1
```

上記コマンドのうち次のコマンドで、Kubernetes クラスタの操作に必要な認証情報をローカル(Cloud Shell)に持ってきています。
```
gcloud container clusters get-credentials cluster-1
```

次のコマンドを実行して、Kubernetes Cluster との疎通確認、バージョン確認を行います。

```bash
kubectl version
```

次のような結果が出れば、Kubernetes Cluster と疎通できています(Client と Server それぞれでバージョンが出力されている)。

```
Client Version: version.Info{Major:"1", Minor:"22", GitVersion:"v1.22.2", GitCommit:"8b5a19147530eaac9476b0ab82980b4088bbc1b2", GitTreeState:"clean", BuildDate:"2021-09-15T21:38:50Z", GoVersion:"go1.16.8", Compiler:"gc", Platform:"linux/amd64"}
Server Version: version.Info{Major:"1", Minor:"20+", GitVersion:"v1.20.10-gke.301", GitCommit:"17ad7bd6afa01033d7bd3f02ce5de56f940a915d", GitTreeState:"clean", BuildDate:"2021-08-24T05:18:54Z", GoVersion:"go1.15.15b5", Compiler:"gc", Platform:"linux/amd64"}
```

コマンド設定をしたことで、現在のシステム構成は次のようになりました。

![](https://storage.googleapis.com/egg-resources/egg4-2/public/gke/1-3.png)

## [演習] 2. Docker コンテナイメージの作成

### **Docker コンテナイメージのビルド**

Docker コンテナイメージを作るときは、Dockerfile を用意します。
Dockerfile は spanner ディレクトリに格納されています。
ファイルの内容は次のコマンドで、Cloud Shell Editor で確認できます。

```bash
cloudshell edit spanner/Dockerfile
```

ターミナルに戻って、次のコマンドで Docker コンテナイメージのビルドを開始します。

```bash
docker build -t asia.gcr.io/${GOOGLE_CLOUD_PROJECT}/spanner-app:v1 ./spanner
```

![](https://storage.googleapis.com/egg-resources/egg4-2/public/gke/2-1.png)

Docker コンテナイメージのビルドには数分かかります。

次のコマンドでローカル(Cloud Shell)上のコンテナイメージを確認できます。

```bash
docker image ls
```

次のように、コンテナイメージが出力されているはずです。

```
REPOSITORY                                       TAG  IMAGE ID       CREATED         SIZE
asia.gcr.io/<GOOGLE_CLOUD_PROJECT>/spanner-app   v1   8952a9a242f5   5 minutes ago   23.2MB
```

### **Docker コンテナイメージを Push**

コンテナイメージのビルドができたら、ビルドしたイメージを Google Container Registry にアップロードします。

次のコマンドで、`docker push` 時に `gcloud` の認証情報を使うように設定します。

```bash
gcloud auth configure-docker
```

次のコマンドで、Google Container Registry に Push します。
(初回は時間がかかります)

```bash
docker push asia.gcr.io/${GOOGLE_CLOUD_PROJECT}/spanner-app:v1
```

次のコマンドで Google Container Registry に Push されたことを確認します。

```bash
gcloud container images list-tags asia.gcr.io/${GOOGLE_CLOUD_PROJECT}/spanner-app
```

Cloud Console > [CI/CD] > [Container Registry] からも確認できます。

![](https://storage.googleapis.com/egg-resources/egg4-2/public/gke/2-2.png)

Google Container Registry にコンテナイメージを追加したことで、現在のシステム構成は次のようになりました。

![](https://storage.googleapis.com/egg-resources/egg4-2/public/gke/2-3.png)

## [演習] 3. Workload Identity 設定

### **Workload Identity が有効化されていることを確認**

GKE クラスタで Workload Identity が有効になっていることを確認します。
次のコマンドを実行してください。

```bash
gcloud container clusters describe cluster-1 \
  --format="value(workloadIdentityConfig.workloadPool)" --zone asia-northeast1-a
```

`<GOOGLE_CLOUD_PROJECT>.svc.id.goog` と出力されていれば、正しく設定されています。

またクラスタとは別に、NodePool で Workload Identity が有効になっていることを確認します。
次のコマンドを実行してください。

```bash
gcloud container node-pools describe default-pool --cluster=cluster-1 \
  --format="value(config.workloadMetadataConfig.mode)" --zone asia-northeast1-a
```

`GKE_METADATA` と出力されていれば、正しく設定されています。

### **Service Account 作成**

Workload Identity を利用する Service Account を作成します。
Kubernetes Service Account (KSA) と Google Service Account (GSA) を作成します。

次のコマンドで、Kubernetes クラスタ上に Kubernetes 用の Service Account (KSA) を作成します。

```bash
kubectl create serviceaccount spanner-app
```

次のコマンドで、Google Service Account (GSA) を作成します。

```bash
gcloud iam service-accounts create spanner-app
```

今回利用する Spanner App は Cloud Spanner にアクセスする Web アプリケーションです。
Cloud Spanner の Database に対してデータの操作(追加・更新・削除など)を行えるように、`roles/spanner.databaseUser` の権限を付与する必要があります。
次のコマンドで、Service Account に Cloud Spanner Database に対するデータ操作が行える権限を追加します。

```bash
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
  --role "roles/spanner.databaseUser" \
  --member serviceAccount:spanner-app@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com
```

この時点では、KSA と GSA はそれぞれ別のものとして作成だけしています。KSA と GSA の紐付け作業は次の作業で行います。

### **Service Account の紐付け**

Kubernetes Service Account が Google Service Account の権限を借用できるように、紐付けを行います。
次のコマンドで紐付けを行います。

```bash
gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:$GOOGLE_CLOUD_PROJECT.svc.id.goog[default/spanner-app]" \
  spanner-app@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com
```

次のコマンドで、Google Service Account の情報を Kubernetes Service Account のアノテーションに追加します。

```bash
kubectl annotate serviceaccount spanner-app \
  iam.gke.io/gcp-service-account=spanner-app@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com
```

## [演習] 4. Kubernetes Deployment の作成

ここからは Kubernetes クラスタ上で動かすリソースを作成していきます。

### **Deployment の Manifest ファイルを編集する** 

Manifest ファイルは k8s ディレクトリに格納されています。
ファイルの内容は次のコマンドで、Cloud Shell Editor で確認できます。

```bash
cloudshell edit k8s/spanner-app-deployment.yaml
```

**ファイル中の project id を自分の {{project-id}} に変更します。**

![](https://storage.googleapis.com/egg-resources/egg4-2/public/gke/3-1.png)


### **Deployment を作成する**

次のコマンドで、Kubernetes クラスタ上に Deployment を作成します。

```bash
kubectl apply -f k8s/spanner-app-deployment.yaml
```

作成された Deployment、Pod を次のコマンドで確認します。

```bash
kubectl get deployments
```

```bash
kubectl get pods -o wide
```

Deployment を作成したことで、現在のシステム構成は次のようになりました。

![](https://storage.googleapis.com/egg-resources/egg4-2/public/gke/4-1.png)

**Appendix) kubectl コマンドリファレンス その１**

 * Pod を一覧で確認したいとき
```bash
kubectl get pods
```

 * Pod の IP アドレスや実行 Node を知りたいとき
```bash
kubectl get pods -o wide
```

 * Pod の詳細を見たいとき
```bash
kubectl describe pods <pod name>
```

 * Pod の定義を YAML で取得したいとき
```bash
kubectl get pods <pod name> -o yaml
```


## [演習] 5. Kubernetes Service (Discovery) の作成

### **Service を作成する**

Manifest ファイルは k8s ディレクトリに格納されています。
ファイルの内容は次のコマンドで、Cloud Shell Editor で確認できます。

```bash
cloudshell edit k8s/spanner-app-service.yaml
```

次のコマンドで、Kubernetes クラスタ上に Service を作成します。

```bash
kubectl apply -f k8s/spanner-app-service.yaml
```

次のコマンドで、作成された Service を確認します。

```bash
kubectl get svc
```

ネットワークロードバランサー(TCP)を作成するため、外部 IP アドレス(EXTERNAL-IP)が割り当てられるまでにしばらく(数分)時間がかかります。
次のコマンドで、-w フラグを付けると変更を常に watch します(中断するときは Ctrl + C)

```bash
kubectl get svc -w
```


**Appendix) kubectl コマンドリファレンス その2**

 * Service を一覧で確認したいとき
```bash
kubectl get services
```

 * Service が通信をルーティングしている Pod(のIP) を知りたいとき
(endpoints リソースは Service リソースによって自動管理されます)
```bash
kubectl get endpoints
```

 * Service の詳細を見たいとき
```bash
kubectl describe svc <service name>
```

 * Service の定義を YAML で取得したいとき
```bash
kubectl get svc <service name> -o yaml
```

### **Service にアクセスする**

`Type: LoadBalancer` の Service を作成すると、ネットワークロードバランサーが払い出されます。
[Cloud Console] - [ネットワーキング] - [ネットワークサービス] - [Cloud Load Balancing] から確認できます。

![](https://storage.googleapis.com/egg-resources/egg4-2/public/gke/5-1.png)

ロードバランサーの外部 IP アドレスを指定して、実際にアクセスしてみましょう。
次のコマンドで、サービスの外部 IP アドレスを確認します。

```bash
kubectl get svc
```

次の出力のうち、`EXTERNAL-IP` が外部 IP アドレスになります。
環境ごとに異なるため、自分の環境では読み替えてください。

```
NAME         TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)          AGE
spanner-app  LoadBalancer   10.0.12.198   203.0.113.245  8080:30189/TCP   58s
kubernetes   ClusterIP      10.56.0.1     <none>         443/TCP          47m
```

curl 用に Cloud Shell の新しいタブを開きます。

![](https://storage.googleapis.com/egg-resources/egg4-2/public/gke/5-3.png)

新しく開いた Cloud Shell のタブで次の curl コマンドを実行し、Players 情報取得します。
EXTERNAL IP の部分は上記で確認した IP アドレスに変更してください。

```bash
curl <EXTERNAL IP>:8080/players
```

curl コマンドの結果、アクセスできれば、Service リソースと Deployment(そしてPod)は正しく機能しています。

また、Workload Identity の機能を使うことで、Service Account の鍵なしで Cloud Spanner にアクセスできることも確認できました。

![](https://storage.googleapis.com/egg-resources/egg4-2/public/gke/5-2.png)

### **Spanner App を操作する**

 * Player 新規追加(playerId は自動で採番されます)
```bash
curl -X POST -d '{"name": "testPlayer1", "level": 1, "money": 100}' <EXTERNAL IP>:8080/players
```

もし **`invalid character '\\' looking for beginning of value`** というエラーが出た場合は、curl コマンド実行時に、バックスラッシュ(\\)文字を削除して改行せずに実行してみてください。

 * Player 一覧取得
```bash
curl <EXTERNAL IP>:8080/players
```

 * Player 更新(playerId は適宜変更すること)
```bash
curl -X PUT -d '{"playerId":"afceaaab-54b3-4546-baba-319fc7b2b5b0","name": "testPlayer1", "level": 2, "money": 200}' <EXTERNAL IP>:8080/players
```

 * Player 削除(playerId は適宜変更すること)
```bash
curl -X DELETE http://<EXTERNAL IP>:8080/players/afceaaab-54b3-4546-baba-319fc7b2b5b0
```

**Appendix) kubectl を使ったトラブルシューティング**

Kubernetes 上のリソースで問題が発生した場合は `kubectl describe` コマンドで確認します。
Kubernetes は リソースの作成・更新・削除などを行うと `Event` リソースを発行します。 `kubectl describe` コマンドで1時間以内の `Event` を確認できます。

```bash
kubectl describe <resource name> <object name>
# 例
kubectl describe deployments hello-node
```

また、アプリケーションでエラーが発生していないかは、アプリケーションのログから確認します。
アプリケーションのログを確認するには `kubectl logs` コマンドを使います。

```bash
kubectl logs -f <pod name>
```

## [演習] 6. Cleanup

すべての演習が終わったら、リソースを削除します。

 1. ロードバランサーを削除します。Disk と LB は先に消さないと Kubernetes クラスタごと削除しても残り続けるため、先に削除します
```bash
kubectl delete svc spanner-app
```

 2. Container Registry に格納されている Docker イメージを削除します
```bash
gcloud container images delete asia.gcr.io/$GOOGLE_CLOUD_PROJECT/spanner-app:v1 --quiet
```

 3. Kubernetes クラスタを削除します
```bash
gcloud container clusters delete "cluster-1" --zone "asia-northeast1-a"
```

`Do you want to continue (Y/n)?` には `y` を入力します。

 4. Google Service Account に付与したロールを削除します
```bash
gcloud projects remove-iam-policy-binding $GOOGLE_CLOUD_PROJECT --member serviceAccount:spanner-app@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com --role "roles/spanner.databaseUser"
```

 5. Google Service Account を削除します
```bash
gcloud iam service-accounts delete spanner-app@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com
```

`Do you want to continue (Y/n)?` には `y` を入力します。

 6. Cloud Spanner Instance を削除します。
```bash
gcloud spanner instances delete dev-instance
```

`Do you want to continue (Y/n)?` には `y` を入力します。

## **Thank You!**

以上で、今回の Google Kubernetes Engine ハンズオンは完了です。