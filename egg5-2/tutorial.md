# EGG ハンズオン #5-2

## Google Cloud プロジェクトの選択

ハンズオンを行う Google Cloud プロジェクトを作成し、 Google Cloud プロジェクトを選択して `Start/開始` をクリックしてください。

**なるべく新しいプロジェクトを作成してください。**

<walkthrough-project-setup>
</walkthrough-project-setup>

## はじめに

### **目的と内容**

本ハンズオンは Cloud Spanner を触ったことのない方向けに、Cloud Spanner を使ったアプリケーション開発における、
最初の 1 歩目のイメージを掴んで頂くことを目的としています。  

Cloud Spanner のインスタンス作成、データベース作成など基本的なステップを経て、
Cloud Spanner を使った テストアプリケーションを構築していきます。 
また、Cloud Spanner を運用していく上で便利なツールも併せてご紹介します。

### **前提条件**

本ハンズオンは、はじめて Cloud Spanner を触られる方を想定しておりますが、Cloud Spanner の基本的なコンセプトや、
主キーによって格納データが分散される仕組みなどは、ハンズオン中では説明しません。  
事前知識がなくとも本ハンズオンの進行には影響ありませんが、Cloud Spanner の基本コンセプトやデータ構造については、 
Coursera などの教材を使い学んでいただくことをお勧めします。

## [解説] 1. ハンズオンで使用するスキーマの説明

今回のハンズオンでは以下の図ように、ユーザー（プレイヤー）とスコアを管理するテーブルを扱います。
後述する テストアプリケーションにより、これらの情報を REST API で扱えるようにします。

![スキーマ](https://storage.googleapis.com/handson-images/egg5-2_db_schema.png "今回利用するスキーマ")

このテーブルの DDL は以下のとおりです、実際にテーブルを CREATE する際に、この DDL は再度掲載します。

```sql
CREATE TABLE users (
  user_id STRING(36) NOT NULL,
  name STRING(MAX) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
) PRIMARY KEY(user_id);
```

```sql
CREATE TABLE scores (
  user_id STRING(36) NOT NULL,
  score_id STRING(36) NOT NULL,
  score INT64 NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
) PRIMARY KEY(user_id, score_id),
  INTERLEAVE IN PARENT users ON DELETE CASCADE;

CREATE INDEX ix_scores_score ON scores(score);
```

## [演習] 2. Cloud Spanner インスタンスの作成

現在 Cloud Shell と Editor の画面が開かれている状態だと思いますが、[Google Cloud のコンソール](https://console.cloud.google.com/) を開いていない場合は、コンソールの画面を開いてください。

### **API の有効化**
本ハンズオンで利用する Cloud Spanner と Artifact Registry の API を有効化します。  
Artifact Registry については本ハンズオンの最終盤で使いますが、纏めてこちらで有効化します。

```bash
gcloud services enable spanner.googleapis.com artifactregistry.googleapis.com
```
### **Cloud Spanner インスタンスの作成**

1. ナビゲーションメニューから`Spanner`を選択  
   Cloud Spanner をはじめて使う場合は API を有効化するステップが必要になるので、そのまま有効化してください。

![](https://storage.googleapis.com/handson-images/egg5-2_navigation_menu_spanner.png)

2. `インスタンスを作成`を選択

![](https://storage.googleapis.com/handson-images/egg5-2_create_spanner_instance.png)

### **情報の入力**

以下の内容で設定して`作成`を選択します。
1. インスタンス名： `demo`
2. インスタンス ID： `demo`
3. `リージョン`を選択
4. `asia-northeast1 (Tokyo)`を選択
5.  コンピューティング容量の割り当て：単位を`ノード`にしつつ、数量を `1` に指定
6. `作成`を選択

![](https://storage.googleapis.com/handson-images/egg5-2_create_spanner_instance_detail.png)

### **インスタンスの作成完了**
以下の画面に遷移し、作成完了です。
どのような情報が見られるか確認してみましょう。

![](https://storage.googleapis.com/handson-images/egg5-2_completed_creating_spanner_instance.png)

### **スケールアウトとスケールインについて**

Cloud Spanner インスタンスノード数を変更したい場合、編集画面を開いてノードの割り当て数を変更することで、簡単に実行出来ます。
ノード追加であってもノード削減であっても、一切のダウンタイムなく実施することができます。

なお補足ですが、たとえ 1 ノード構成であっても裏は多重化されており、単一障害点がありません。ノード数は可用性の観点ではなく、純粋に性能の観点でのみ増減させることができます。

![](https://storage.googleapis.com/handson-images/egg5-2_edit_spanner_instance.png)


## [演習] 3. Cloud Shell 上で環境構築
作成した Cloud Spanner に対して各種コマンドやアプリケーションを実行するための環境を Cloud Shell 上に構築します。   
以下のコマンドを Cloud Shell で実行し、プロジェクトIDを設定してください。
```text
gcloud config set project <あなたのプロジェクト ID>
```

今回のハンズオンで使用するテストアプリケーションのソースコードをクローンします。
テストアプリケーションの詳細については後述します。
```bash
git clone https://github.com/kazshinohara/spanner-sqlalchemy-demo
```

Python のパッケージ及び仮想環境を管理するため [Poetry](https://python-poetry.org/) をインストールします。
```bash
curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python3 -
```

Poetry のPATH を通しておきます。  
`~/.profile` に同じものが追記されているので次回以降 Cloud Shell にログインする際は、このステップはスキップして OK です。
```bash
export PATH="$HOME/.poetry/bin:$PATH"
```

先程クローンしたテストアプリケーションのレポジトリに移動します。
```bash
cd spanner-sqlalchemy-demo
```

テストアプリケーションを実行するための仮想環境を構成します。
以下のコマンドにより `pyproject.toml` に記載された依存パッケージをインストールした仮想環境が立ち上がります。
```bash
poetry install
```

Cloud Shell のターミナルに、以下のコマンド入力し、後ほど利用する Spanner CLI の Linux 用のバイナリをインストールします。

```bash
go install github.com/cloudspannerecosystem/spanner-cli@latest
```

最後に以下のコマンドで、現在いるディレクトリを確認してください。

```bash
pwd
```

以下のようなパスが表示されていれば OK です。  
基本的には以降の作業は本ディレクトリで行います。

```terminal
/home/<あなたのユーザー名>/cloudshell_open/egg-training-materials/egg5-2/spanner-sqlalchemy-demo
```

過去に他の E.G.G のハンズオンを同一環境で実施している場合、***egg-training-materials-0*** や 
***egg-training-materials-1*** のように末尾に数字がついたディレクトリを、今回の egg5-2 用のディレクトリとしている場合があります。
誤って過去のハンズオンで使ったディレクトリを使ってしまわぬよう、**今いる今回利用してるディレクトリを覚えておいてください。**


## [解説] 4. Cloud Spanner 接続クライアントの準備

Cloud Spanner へのデータの読み書きには、様々な方法があります。

### **クライアント ライブラリ を使用しアプリケーションを作成し読み書きする** 

アプリケーション内で、`C++`, `C#`, `Go`, `Java`, `Node.js`, `PHP`, `Python`, `Ruby` といった各種言語用のクライアント 
ライブラリを用いて、Cloud Spanner をデータベースとして利用します。クライアント ライブラリ内では以下の方法で、
Cloud Spanner のデータを読み書きすることができます。
- アプリケーションのコード内で API を用いて読み書きする
- アプリケーションのコード内で SQL を用いて読み書きする

またトランザクションも実行することが可能で、リードライト トランザクションはシリアライザブルの分離レベルで実行でき、強い整合性を持っています。またリードオンリー トランザクションを実行することも可能で、トランザクション間の競合を減らし、ロックやそれに伴うトランザクションの abort を減らすことができます。

### **JDBC ドライバー、各種 ORM を使用しアプリケーションを作成し読み書きする**
クライアントライブラリに加えて、JDBC ドライバー や 各種言語の ORM も提供されています。  
より抽象度の高いインターフェースを通じて SQL を意識せず容易にデータの読み書きを行うことが可能です。  

Google が OSS で提供
- Java - Hibernate  
- Python - Django ORM  
- Python - SQLAlchemy  
- Ruby - Active Record  
- C# - Entity Framework

コミュニティで提供
- PHP - Laravel

### **Cloud Console の GUI または `gcloud` コマンドを利用する** 

Cloud Console の GUI または `gcloud` コマンドを利用する方法もあります。こちらはデータベース管理者が、直接 SQL を実行したり、特定のデータを直接書き換える場合などに便利です。
 
### **その他 Cloud Spanner 対応ツールを利用する**

これは Cloud Spanner が直接提供するツールではありませんが、 `spanner-cli` と呼ばれる、対話的に SQL を発行できるツールがあります。
これは Cloud Spanner Ecosystem と呼ばれる、Cloud Spanner のユーザーコミュニティによって開発メンテナスが行われているツールです。
MySQL の `mysql` コマンドや、PostgreSQL の `psql` コマンドの様に使うことのできる、非常に便利なツールです。


## [演習] 5. データベースの作成

### **データベースの作成**

まだ Cloud Spanner のインスタンスしか作成していないので、データベース及びテーブルを作成していきます。  
1つの Cloud Spanner インスタンスには、複数のデータベースを作成することができます。

1. `demo` を選択すると画面が遷移します  
![](https://storage.googleapis.com/handson-images/egg5-2_select_spanner_instance.png)


2. `データベースを作成`を選択します  
![](https://storage.googleapis.com/handson-images/egg5-2_select_create_database.png)


3. データーベースの設定詳細を入力します  
![](https://storage.googleapis.com/handson-images/egg5-2_create_database.png)

データベース名には`ranking`と入力します。  
スキーマの定義には以下の DDL を貼り付けます。
```sql
CREATE TABLE users (
                       user_id STRING(36) NOT NULL,
                       name STRING(MAX) NOT NULL,
                       created_at TIMESTAMP NOT NULL,
                       updated_at TIMESTAMP NOT NULL,
) PRIMARY KEY(user_id);

CREATE TABLE scores (
                        user_id STRING(36) NOT NULL,
                        score_id STRING(36) NOT NULL,
                        score INT64 NOT NULL,
                        created_at TIMESTAMP NOT NULL,
                        updated_at TIMESTAMP NOT NULL,
) PRIMARY KEY(user_id, score_id),
  INTERLEAVE IN PARENT users ON DELETE CASCADE;

CREATE INDEX ix_scores_score ON scores(score);
```
### **データベースの作成完了**

![](https://storage.googleapis.com/handson-images/egg5-2_completed_creating_database.png)

うまくいくと、データベースが作成されると同時に 2 つのテーブルが生成されています。


## [解説] 6. テストアプリケーションについて
本ハンズオンで使用しているテストアプリケーションについて解説します。
Python3 で書かれており、Web フレームワークとして [FastAPI](https://fastapi.tiangolo.com/) 、
ORM として [Cloud Spanner SQLAlchemy ORM](https://github.com/googleapis/python-spanner-sqlalchemy) を使っています。

### **全体の構成**
![](https://storage.googleapis.com/handson-images/egg5-2_test_app_repo_structure.png)

- `app/alembic`
  - (本ハンズオンでは扱いません) DB マイグレーションツール [Alembic](https://alembic.sqlalchemy.org/en/latest/) に関するディレクトリです
- `app/crud.py`
  - データベースに対する CRUD (Create/Read/Update/Delete) 操作を定義されたファイルです
- `app/database.py`
  - データベースへの接続方法などについて定義されたファイルです
- `app/main.py`
  - テストアプリケーションのエントリポイントです
  - REST API の HTTP ハンドラが定義されており、`crud.py` で定義したメソッドを呼び出します
- `app/models.py`
  - データベースのスキーマが定義されたファイルです
- `app/schemas.py`
  - REST API のスキーマが定義されたファイルです
- `tests/conftest.py`
    - [Pytest](https://docs.pytest.org/en/7.1.x/) の設定ファイルです
- `tests/test_app.py`
  - ユニットテストが定義されたファイルです

### **モデルの定義 `app/models.py`**
ORM を利用することで、先程使った DDL は以下のようなクラスの定義で表現可能です。  
インターリーブやセカンダリインデックスの設定も可能です。`models.py` 定義されています。
![](https://storage.googleapis.com/handson-images/egg5-2_models.png)


### **CRUD 操作 `app/crud.py`**
`models.py` で定義したクラスのインスタンスを用いてデータを扱い、CRUD を行います。  
![](https://storage.googleapis.com/handson-images/egg5-2_crud.png)


## [演習] 7. テストアプリケーションを使ったデータの読み書き
ここではテストアプリケーションを Cloud Shell 上で起動して、REST API から Cloud Spanner へデータの読み書きを行います。

### **環境変数の設定**
テストアプリケーションの実行に必要な環境変数を設定します。

ハンズオンで使っている Google Cloud のプロジェクト ID を設定します。
```bash
export PROJECT_ID=$(gcloud config get-value project)
```

先程作成した Cloud Spanner のインスタンス ID を設定します。
```bash
export INSTANCE_ID="demo"
```

同じく作成済みの Cloud Spanner のデータベース ID を設定します。
```bash
export DATABASE_ID="ranking"
```

この後のステップで作成するテストアプリケーションが Cloud Spanner へ接続するために必要なサービスアカウントとそのキーファイルの名前を設定します。
```bash
export SA_NAME="spanner-demo"
export SA_KEY_NAME="spanner-demo-key"
```
### **サービスアカウントの作成**
テストアプリケーションから Cloud Spanner へ接続するために必要となるサービスアカウントの作成を行います。
```bash
gcloud iam service-accounts create ${SA_NAME}
```

Cloud Spanner にデータを読み書きするためのロールを紐付けます。
```bash
gcloud projects add-iam-policy-binding ${PROJECT_ID} --member "serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" --role "roles/spanner.databaseUser"
```

続いてサービスアカウントのキーファイルを Cloud Shell にダウンロードします。
```bash
gcloud iam service-accounts keys create ${SA_KEY_NAME} \
--iam-account=${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com
```

ダウンロードしたキーファイルのロケーションを環境変数として設定し、テストアプリケーションから使えるようにします。
```bash
export GOOGLE_APPLICATION_CREDENTIALS="/home/$(whoami)/cloudshell_open/egg-training-materials/egg5-2/spanner-sqlalchemy-demo/spanner-demo-key"
```
### **テストアプリケーションの実行**
コマンドを実行するディレクトリに注意してください。
テストアプリケーションのレポジトリのルートディレクトリにいることを念の為確認してください。
```bash
pwd
```

期待する戻り値は以下です。
違う場合は適宜 cd コマンドで正しいディレクトリに移動してください。
```terminal
/home/<あなたのユーザー名>/cloudshell_open/egg-training-materials/egg5-2/spanner-sqlalchemy-demo/
```

テストアプリケーションを実行します。
```bash
poetry run uvicorn app.main:app --port 8080 --reload
```

以下のような出力があればテストアプリケーションは正常に起動出来ています。
```terminal
INFO:     Uvicorn running on http://127.0.0.1:8080 (Press CTRL+C to quit)
INFO:     Started reloader process [583] using statreload
INFO:     Started server process [586]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```
### **テストアプリケーションの Swagger UI への接続**
テストアプリケーションで使用している FastAPI という Web フレームワークは [OpenAPI](https://github.com/OAI/OpenAPI-Specification)
をベースにしており、[Swagger UI](https://github.com/swagger-api/swagger-ui) がデフォルトで提供されています。
この Swagger UI を使ってテストアプリケーションに実装済みの REST API を呼び出し Cloud Spanner へのデータ読み書きを行うことが可能です。

Cloud Shell の Web preview 機能を使ってテストアプリケーションの Swagger UI へ接続します。
![](https://storage.googleapis.com/handson-images/egg5-2_select_web_preview.png)

テストアプリケーションは Cloud Shell 上で 8080 番でリッスンしている状態なので、
そのままポート 8080 でプレビューを選択します。  
![](https://storage.googleapis.com/handson-images/egg5-2_select_preview_8080.png)

以下のような画面が別タブで表示されれば成功です。
![](https://storage.googleapis.com/handson-images/egg5-2_fastapi_doc_top.png)

この Swagger UI を使わなくても例えば curl コマンドなどを使って、テストアプリケーションの REST API を呼び出すことも可能です。
例えばヘルスチェック用の API を呼び出す場合は、以下の通りです。試す場合は Cloud Shell の別タブで行ってください。
```bash
curl -s http://127.0.0.1:8080/health/ | jq
```
### **テストアプリケーションを通じたデータの読み書き**
ユーザーのリストを取得してみます。`GET /users/` を選択してください。  
![](https://storage.googleapis.com/handson-images/egg5-2_select_get_users.png)

`GET /users/` の API 定義が確認出来ます。`Try it out` を選択してください。  
![](https://storage.googleapis.com/handson-images/egg5-2_try_it_out.png)

そのまま `Execute` を選択してください。実際に API が呼び出されます。　　 
![](https://storage.googleapis.com/handson-images/egg5-2_execute.png)

レスポンスが下に表示されます。この時点ではまだ何も Cloud Spanner へデータ書き込みしていない状態なので、
空のリストが返ってきます。その他、HTTP のレスポンスコードやレスポンスヘッダーなども確認出来ます。
![](https://storage.googleapis.com/handson-images/egg5-2_get_users_response.png)

### **注意💡  ValueError について**
Cloud Shell 上で確認出来るテストアプリケーションの実行ログに、
`ValueError: staleness option can't be changed while a transaction is in progress. 
Commit or rollback the current transaction and try again.`という例外が発生してるかと思います。  
こちらは ORM の既知のバグのため、ノイジーかと思いますが気にしないでください。  
ORM の 最新版で FIX されていますが、諸般の都合により今回は最新版を利用していません。  

ではこの要領で以降のステップを進めていきます。  
まずはユーザーを作成してみましょう。 `POST /users/` を使います。  
![](https://storage.googleapis.com/handson-images/egg5-2_post_user.png)

`name` というパラメーターがあるので任意の文字列を入力してください。(例: ご自身のお名前など)
![](https://storage.googleapis.com/handson-images/egg5-2_post_user_execute.png)

レスポンスを確認します。`user_id` が生成されています。  
Cloud Spanner 上では users テーブルの主キーとして使われており、UUIDv4 を使っています。  
次のステップで使うので、この `user_id` をコピーしておきましょう。  
![](https://storage.googleapis.com/handson-images/egg5-2_post_user_response.png)

次にスコアを作成します。`POST /scores/` を使います。  
![](https://storage.googleapis.com/handson-images/egg5-2_post_score.png)

`score` というパラメーターにはお好きな数値を入力してください。  
`user_id` には先程コピーした `user_id` を貼り付けてください。  
![](https://storage.googleapis.com/handson-images/egg5-2_post_score_execute.png)

レスポンスを確認します。`score_id` が生成されています。  
次のステップで使うので、この `score_id` をコピーしておきましょう。　　
![](https://storage.googleapis.com/handson-images/egg5-2_post_score_response.png)

作成したスコアを更新してみましょう。`PUT /scores/{score_id}/` を使います。  
![](https://storage.googleapis.com/handson-images/egg5-2_put_score.png)

`score_id` には先程コピーした `score_id` を貼り付けてください。
`score` には作成時に入力したものとは別の数値を入力してください。
`user_id` はこのスコアの作成時と同じ値を入力してください。
![](https://storage.googleapis.com/handson-images/egg5-2_put_score_execute.png)

レスポンスを確認し、スコアが期待通り更新されていることを確認します。
![](https://storage.googleapis.com/handson-images/egg5-2_put_score_reponse.png)

### **メモ💡Cloud Spanner の主キーのひみつ**

UUIDv4 を使ってランダムな ID を生成していますが、これは主キーを分散させるためにこのような仕組みを使っています。  
一般的な RDBMS では、主キーはわかりやすさのために連番を使うことが多いですが、Cloud Spanner は主キー自体を  
シャードキーのように使っており、主キーに連番を使ってしまうと、新しく生成された行が常に一番うしろのシャードに割り当てられてしまうからです。

今回利用しているテストアプリケーションでは、`app/crud.py` 中の以下のように UUID を生成し、主キーとして利用しています。

```py
db_user = models.Users(user_id=str(uuid.uuid4()), name=user.name)

db_score = models.Scores(user_id=score.user_id, score_id=str(uuid.uuid4()), score=score.score)
```

### **データの削除**
最後にテストアプリケーションを使ったデータの削除を試してみます。
先程作成したユーザーを削除してみましょう。 `DELETE /users/{user_id}/` を使います。  
![](https://storage.googleapis.com/handson-images/egg5-2_delete_user.png)

先程作成したユーザーの `user_id` を入力してください。  
![](https://storage.googleapis.com/handson-images/egg5-2_delete_user_execution.png)

`204` が返ってきたら成功です。  
![](https://storage.googleapis.com/handson-images/egg5-2_delete_user_response.png)

ここでスコアのリストを確認してみましょう。 `GET /scores/` を使います。
![](https://storage.googleapis.com/handson-images/egg5-2_get_scores.png)

そのまま実行してみてください。  
![](https://storage.googleapis.com/handson-images/egg5-2_get_scores_execute.png)

ご覧の通り空のリストが返ってくるかと思います。
これはインターリーブにより users テーブルと scores テーブルが親子関係になっており、`ON DELETE CASCADE` をテーブル作成時に設定しているためです。
親のユーザーが削除されたため子のスコアも一緒に削除されたことになります。
![](https://storage.googleapis.com/handson-images/egg5-2_get_scores_response.png)


## [演習] 8. Cloud Console を使ったデータの読み書き
Cloud Spanner へのデータの読み書きは Cloud Console からも可能です。
試してみましょう。

### **入力用データの準備**
テストアプリケーションでは主キーやタイムスタンプなどの値は自動で入力してくれていましたが、
Cloud Console の場合はそういったものはないので、自分で用意する必要があります。

Cloud Shell で以下のコマンドを実行して主キー用の uuid を生成します。  
**(注意) テストアプリケーションを実行しているタブとは別に新たに Cloud Shell のタブを開いて作業をしてください。**

**ユーザー用とスコア用、それぞれ 1 つずつ生成し、控えておいてください。**
```bash
python3 -c 'import uuid;print(uuid.uuid4())'
```
users と scores のテーブルには `created_at` というタイムスタンプのカラムがあります。
こちらも用意しておきましょう。こちらは使いまわし OK なので 1 つで良いです。
```bash
python3 -c 'from datetime import datetime;print(datetime.now())'
```

### **ユーザーの追加**
ユーザーの追加から行います。`users` を選択します。  
![](https://storage.googleapis.com/handson-images/egg5-2_select_users_table.png)

左のメニューから`データ`を選択します。  
![](https://storage.googleapis.com/handson-images/egg5-2_select_data_menu.png)

挿入を選択します。  
![](https://storage.googleapis.com/handson-images/egg5-2_select_insert_button_users.png)

予め用意されたクエリのテンプレートに従い、`VALUES` を入力します。
事前に用意した `user_id` 用の uuid と `created_at` 用のタイムスタンプに加えて、
任意のユーザー名、`updated_at` には `1970-01-01T00:00:00` を入力してください。
(`updated_at` のタイムスタンプはダミーです)　　

最後に`実行`ボタンを押してください。
![](https://storage.googleapis.com/handson-images/egg5-2_insert_user.png)

左のメニューから`データ`を選択すると、insert(追加)したデータがあることが確認出来ます。
![](https://storage.googleapis.com/handson-images/egg5-2_check_newly_insert_user.png)


### **ユーザーの更新**
次に前のステップに追加したユーザーの情報を更新します。
更新対象のデータを選択の上、`編集`を選択してください。  
![](https://storage.googleapis.com/handson-images/egg5-2_select_edit_user.png)

以下は例となります。私は名字を `name` に追加してみました。
任意の変更を加えてみてください。  
`updated_at` の値は先程のコマンドを使って現在の時間のタイムスタンプを入力してください。(そのままでも構いません)  

最後に`実行`ボタンを押してください。
![](https://storage.googleapis.com/handson-images/egg5-2_update_user.png)

左のメニューから`データ`を選択すると、update(更新) したデータがあることが確認出来ます。
![](https://storage.googleapis.com/handson-images/egg5-2_check_update_user.png)


### **スコアの追加**
同様にスコアの追加も Cloud Console から試してみます。  
`scores` を選択します。  
![](https://storage.googleapis.com/handson-images/egg5-2_select_scores_table.png)

左のメニューから`データ`を選択します。  
![](https://storage.googleapis.com/handson-images/egg5-2_select_data_menu.png)

`挿入`を選択します。  
![](https://storage.googleapis.com/handson-images/egg5-2_select_insert_button_scores.png)

予め用意されたクエリのテンプレートに従い、`VALUES` を入力します。
`user_id` は前のステップで追加したユーザーのものを入力してください。
事前に用意した `scores_id` 用の uuid と `created_at` 用のタイムスタンプに加えて、
任意のスコア、`updated_at` には `1970-01-01T00:00:00` を入力してください。
(`updated_at` のタイムスタンプはダミーです)　　

最後に`実行`ボタンを押してください。  
![](https://storage.googleapis.com/handson-images/egg5-2_insert_score.png)

左のメニューから`データ`を選択すると、insert(追加)したデータがあることが確認出来ます。  
![](https://storage.googleapis.com/handson-images/egg5-2_check_newly_insert_score.png)

### **おまけ**
テストアプリケーションの Swagger UI から Cloud Console から追加したデータが確認出来るか試してみてください。


## [演習] 9. Spanner CLI を使ったデータの読み書き
### **ダミーデータの入力**
Spanner CLI の前に Cloud Spanner にダミーデータを書き込んでおきましょう。
**(注意) この作業は前のステップで uuid などを作った Cloud Shell のタブを使ってください。**

はじめに必要な環境変数を設定します。
```bash
export PROJECT_ID=$(gcloud config get-value project)
```
```bash
export INSTANCE_ID="demo"
```
```bash
export DATABASE_ID="ranking"
```
```bash
export GOOGLE_APPLICATION_CREDENTIALS="/home/$(whoami)/cloudshell_open/egg-training-materials/egg5-2/spanner-sqlalchemy-demo/spanner-demo-key"
```

次にテストアプリケーションのレポジトリのルートディレクトリに移動します。
```bash
cd /home/$(whoami)/cloudshell_open/egg-training-materials/egg5-2/spanner-sqlalchemy-demo
```

ダミーデータを書き込むスクリプトを実行します。 
このスクリプトは 100 ユーザー、10000 スコアを Cloud Spanner へ直接書き込みます。Cloud Spanner との接続には前述のクライントライブラリを使っています。
興味のある方は中身も確認してみてください。

実行権限を付与します。
```bash
chmod u+x ./tests/insert_data.py
```

スクリプトを実行します。
```bash
poetry run ./tests/insert_data.py
```
エラーとなる場合は以前のステップで設定した環境変数(INSTANCE_ID, DATABASE_ID, GOOGLE_APPLICATION_CREDENTIALS)が
設定されていることを確認してください。

数分でダミーデータの書き込みが終わります。無事完了すると以下のようなメッセージが表示されているはずです。
```terminal
Inserted user data.
Read users
Inserted score data.
```

### **SQL によるインタラクティブな操作**

では Spanner CLI を触っていきましょう。
以下の通りコマンドを実行すると、Cloud Spanner に接続できます。

```bash
spanner-cli -p $PROJECT_ID -i $INSTANCE_ID -d $DATABASE_ID
```

![](https://storage.googleapis.com/handson-images/egg5-2_spanner_cli_entry.png)

先程のスクリプトでスコアが本当に 10000 件書き込みされているか確認してみましょう。
```sql
SELECT COUNT(*) FROM scores;
```

さらに、以下のような SELECT 文を実行し、スコアを昇順に表示してみましょう。
9000 以上のスコアのトップ 10 がユーザー名とともに表示されます。
```sql
SELECT s.score_id, s.score, s.user_id, u.name
FROM scores@{FORCE_INDEX=ix_scores_score} s
INNER JOIN users u ON s.user_id = u.user_id
WHERE score >= 9000 
ORDER BY score DESC LIMIT 10; 
```

先程の SELECT 文の頭に `EXPLAIN` を追加して実行してみましょう。クエリプラン（実行計画）を表示することができます。  
クエリプランは Cloud Console 上でも表示できます。
テーブル作成時に DDL で指定した通り、`score` の値でインデックスを作成していますので、
そちらを使うよう `FORCE_INDEX` ディレクティブでインデックス名を指定します。
```sql
EXPLAIN
SELECT s.score_id, s.score, s.user_id, u.name
FROM scores@{FORCE_INDEX=ix_scores_score} s
INNER JOIN users u ON s.user_id = u.user_id
WHERE score >= 9000
ORDER BY score DESC LIMIT 10; 
```

Cloud Spanner では、クエリを効率化する可能性のあるインデックスが自動的に使用されますが、重要なクエリについては、
より安定したパフォーマンスのため、今回のように `FORCE_INDEX` ディレクティブを使うことを推奨しています。
![](https://storage.googleapis.com/handson-images/egg5-2_spanner_query_plan2.png)

最後に spanner-cli を終了します。
```bash
exit;
```

### **spanner-cli の詳しい使い方**
[spanner-cli の GitHubリポジトリ](https://github.com/cloudspannerecosystem/spanner-cli) には、spanner-cli の使い方が詳しく乗っています。これを見ながら、Cloud Spanner に様々なクエリを実行してみましょう。


## [演習] 10. コンテナイメージの作成
最後の工程です。  
本ハンズオンで使用したテストアプリケーションはこの後の Cloud Run ハンズオンでも使用します。
事前にコンテナイメージを作成しておきましょう。

### **コンテナレジストリの準備**
はじめにコンテナイメージを保存するレポジトリを [Artifact Registry](https://cloud.google.com/artifact-registry/docs) に作成します。

レポジトリ名を環境変数にセットします。
```bash
export REPOSITORY_NAME=demo
```


レポジトリを作成します。
```bash
gcloud artifacts repositories create $REPOSITORY_NAME --repository-format=docker \
--location=asia-northeast1
```

念の為、レポジトリが作成されたことを確認します。
```bash
gcloud artifacts repositories list
```

docker push コマンドで先程作成したレポジトリにプッシュ出来るよう認証設定を行います。
```bash
gcloud auth configure-docker asia-northeast1-docker.pkg.dev
```

### **コンテナイメージのビルド、プッシュ**
テストアプリケーションのルートディレクトリに移動します。

```bash
cd /home/$(whoami)/cloudshell_open/egg-training-materials/egg5-2/spanner-sqlalchemy-demo
```

コンテナイメージをビルドします。
```bash
docker build -t asia-northeast1-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY_NAME}/spanner-sqlalchemy-demo:1.0.0 .
```

ビルドが完了したらコンテナイメージを先程作成したレポジトリにプッシュします。
```bash
docker push asia-northeast1-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY_NAME}/spanner-sqlalchemy-demo:1.0.0
```

## **Thank You!**

以上で、今回の Cloud Spanner ハンズオンは完了です。
引き続き Cloud Run ハンズオンをお楽しみください！
