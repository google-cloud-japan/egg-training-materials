# EGG Hands-on #3-2

## Selecting Google Cloud project

Make a Google Cloud project that you do the hands-on, select Google Cloud project, and Click **Start**.

**Make a project as new as possible.**

<walkthrough-project-setup>
</walkthrough-project-setup>

## [Explanation] Overview of hands-on

### **Overview and Objective**

In this hands-on, which is intended for the people with no prior experience of Cloud Spanner, we start from creating an instance, building a simple application that connects to Cloud Spanner and queries using API, querying by SQL, among other things.

Throughout this hands-on, our objective is for you to get an image of the first step in application development using Cloud Spanner.

### **Prerequisite**

This hands-on is intended for those who are new to Cloud Spanner, but things like the basic concept of Cloud Spanner or the mechanism by which the stored data is distributed by the primary key are not explained in the hands-on.
No prior knowledge is required to go through this hands-on, but it is recommended that you use materials such as Coursera to study the basic concept and data structure of Cloud Spanner.

## [Explanation] 1. Description of Schema used in the hands-on

In this hands-on, we use three tables as below. This assumes that Cloud Spanner was used as a back-end database in the development of a game, and they represent the equivalent of tables that manage game player information and item information.

![Schema](https://storage.googleapis.com/egg-resources/egg3/public/1-1.png "The Schema we use this time")

The DDL of this table is as below. When we actually CREATE the table, DDL will be shown again.

```sql
CREATE TABLE players (
player_id STRING(36) NOT NULL,
name STRING(MAX) NOT NULL,
level INT64 NOT NULL,
money INT64 NOT NULL,
) PRIMARY KEY(player_id);
```

```sql
CREATE TABLE items (
item_id INT64 NOT NULL,
name STRING(MAX) NOT NULL,
price INT64 NOT NULL,
) PRIMARY KEY(item_id);
```

```sql
CREATE TABLE player_items (
player_id STRING(36) NOT NULL,
item_id INT64 NOT NULL,
quantity INT64 NOT NULL,
FOREIGN KEY(item_id) REFERENCES items(item_id)
) PRIMARY KEY(player_id, item_id),
INTERLEAVE IN PARENT players ON DELETE CASCADE;
```

## [Exercise] 2. Creating a Cloud Spanner instance

Cloud Shell and Editor screens should be opened now. If you have not opened [Console of Google Cloud](https://console.cloud.google.com/) yet, please do so.

### **Creating a Cloud Spanner instance**

![](https://storage.googleapis.com/egg-resources/egg3/public/2-1.png)

1. Select “Spanner” from navigation menu

![](https://storage.cloud.google.com/egg-resources/egg3-2/public/2-2.png)

2. Select “Create an Instance”

### **Input information**

![](https://storage.googleapis.com/egg-resources/egg3/public/2-3.png)

Set up as below configuration and select “Create”

1. Instance name：dev-instance
2. Instance ID：dev-instance
3. Select “Region”
4. Select ”asia-northeast1 (Tokyo) “
5. Node assignment：1
6. Select “Create”

### **Instance is created**

The screen below will be displayed, and the creation of the instance is completed.
Let’s check out what information we can see.

![](https://storage.googleapis.com/egg-resources/egg3-2/public/2-4.png)

### **On scale-out and scale-in**

When you want to change the number of Cloud Spanner instance nodes, it’s easily done by opening the Editor screen and changing the node assignment.
There is no downtime whether you add or delete nodes.

As a side note, even with a single-node configuration, the backend is multiplexed and there is no single point of failure.The number of nodes can only be increased or decreased purely in terms of performance, not in terms of availability.

![](https://storage.googleapis.com/egg-resources/egg3/public/2-5.png)

## [Exercise] 3. Creating the test environment for connection (Build on Cloud Shell)

Prepare the Cloud Shell to execute various commands against the created Cloud Spanner.

This time you see Cloud Shell that you booted at the beginning of hands-on. Make sure the correct path and project ID are displayed, which will be used in this hands-on. As you see below, the path is displayed in blue, followed by project ID, which is yellow and parenthesized. Actual project ID varies depending on the environment in which you operate.

![](https://storage.googleapis.com/egg-resources/egg3/public/3-2.png)

If project ID is not displayed, you might only see the blue path as shown in the figure below. In that case, run the command below in Cloud Shell and set up the project ID.

![](https://storage.googleapis.com/egg-resources/egg3/public/3-3.png)

```bash
gcloud config set project {{project-id}}
```

Next, store the ID of the project you are using in the environment variable `GOOGLE_CLOUD_PROJECT`. Run the following command in the terminal of Cloud Shell.

```bash
export GOOGLE_CLOUD_PROJECT=$(gcloud config list project --format "value(core.project)")
```

Also, make sure where you are right now in the directory by the command below.

```bash
pwd
```

Path will be displayed, such as below.

```bash
/home/<Your user name>/cloudshell_open/egg-training-materials/egg3-2
```

If other E.G.G. hands-on had been conducted in the same environment before, directories that end with numerals such as ***egg-training-materials-0*** や ***egg-training-materials-1*** may be set up as the directory for egg3- this time. **Please make sure where you are at in the directory** to avoid mistakenly using the directory you used in the past hands-on.

## [Explanation] 4. Preparing a client for Cloud Spanner connection

There are several ways to read/write data on Cloud Spanner.

### **Create application and read/write using client library**

A typical method is to use client library to create application and read/write. In the server side of the game application, client library of various languages such as `C++`, `C#`, `Go`, `Java`, `Node.js`, `PHP`, `Python`, `Ruby` are used to utilize Cloud Spanner as a database. In the client library, the data of Cloud Spanner can be read/write with the method below.

- Read/write using API within the application code  
- Read/write using SQL within the application code

Also, you can perform transactions. Read/write transactions can be executed at a serializable isolation level and are highly consistent. You can also perform read-only transactions, which reduces conflicts between transactions, and also reduces the locks and associated transactions abort.

### **Utilize the GUI of Cloud Console or gcloud command**

You can also use the GUI of Cloud Console or gcloud command. This method is convenient for a database admin to directly execute SQL or overwrite on certain data.

### **Utilize other Cloud Spanner compatible tools**

These are not the tools provided by Cloud Spanner, but there is a tool called `spanner-cli` that can issue SQL interactively. This is maintained by Cloud Spanner Ecosystem, a user community of Cloud Spanner. It is a very useful tool that you can use like MySQL’s mysql command or PostgreSQL’s psql command.

In this hands-on, we try to read/write mainly by the above method.

## [Exercise] 4. Preparing the Cloud Spanner connection client

### **Build of the application to write on Cloud Spanner**

First, we create a web application that uses the client library.

In the Cloud Shell, you are currently at `egg3-2`, the directory we use now.
There is a directory called spanner, so please move there.

```bash
cd spanner
```

Let’s check out what’s in the directory.

```bash
ls -la
```

You will see files and directories with the names such as `main.go` や `pkg/`.
You can also confirm this via the Editor of Cloud Shell.

Let’s open `egg3-2/spanner/main.go` through the Editor to see inside.

```bash
cloudshell edit main.go
```

![](https://storage.googleapis.com/egg-resources/egg3-2/public/4-1.png)

This application is the application to register new users in the game we are making.
When executed, the Web server will be booted.
When you send an HTTP request to the Web server, a user ID will be automatically assigned and new user data will be written on the players table of Cloud Spanner.

The code below is the part that is actually doing that.

```go
func (h *spanHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
        ...
                p := NewPlayers()
                // get player infor from POST request
                err := GetPlayerBody(r, p)
                if err != nil {
                        LogErrorResponse(err, w)
                        return
                }
                // use UUID for primary-key value
                randomId, _ := uuid.NewRandom()
                // insert a recode using mutation API
                m := []*spanner.Mutation{
                        spanner.InsertOrUpdate("players", tblColumns, []interface{}{randomId.String(), p.Name, p.Level, p.Money}),
                }
                // apply mutation to cloud spanner instance
                _, err = h.client.Apply(r.Context(), m)
                if err != nil {
                        LogErrorResponse(err, w)
                        return
                }
                LogSuccessResponse(w, "A new Player with the ID %s has been added!\n", randomId.String())}
        ...
```

Next, let’s build this source code written in Go.

You build it with the command below. When you build it for the first time, it takes a little more time due to the downloading of the dependent library.
It will take one minute to download and build.

```bash
go build -o player
```

Let’s see whether we have the built binary.
You will find the binary named `player` created. Now we have the application to connect to Cloud Spanner and read/write.

```bash
ls -la
```

**Appendix) Method to operate without building the binary**

With the command below, you can also operate the application without building binary.

```bash
go run *.go
```

### **Installing spanner-cli**

It is better to create a dedicated application to read/write game data, but sometimes you need to read/write on the database on Cloud Spanner with SQL. In such a situation, **spanner-cli** is useful; it allows you to interactively execute SQL as a transaction.

This is not an official application by Google Cloud. It is developed by a user community called Cloud Spanner Ecosystem and published on GitHub.

Enter the following command in the Cloud Shell terminal to install spanner-cli binary for Linux.

```bash
go get -u github.com/cloudspannerecosystem/spanner-cli
```

## [Exercise] 5. Create table

### **Create database**

So far we have only created Cloud Spanner instance, so let’s create a database and table.

You can create several databases in a Cloud Spanner instance.

![](https://storage.googleapis.com/egg-resources/egg3-2/public/5-1.png)

![](https://storage.googleapis.com/egg-resources/egg3-2/public/5-2.png)

1. The screen will transition when dev-instance is selected.
2. Select “Create a database”

### **Enter the database name**

![](https://storage.googleapis.com/egg-resources/egg3-2/public/5-3.png)
Enter the name as “player-db”

### **Define database schema**

![](https://storage.googleapis.com/egg-resources/egg3-2/public/5-4.png)
Transition to the screen for defining schema.

Paste the following DDL directly on the area of 1.

```sql
CREATE TABLE players (
player_id STRING(36) NOT NULL,
name STRING(MAX) NOT NULL,
level INT64 NOT NULL,
money INT64 NOT NULL,
) PRIMARY KEY(player_id);


CREATE TABLE items (
item_id INT64 NOT NULL,
name STRING(MAX) NOT NULL,
price INT64 NOT NULL,
) PRIMARY KEY(item_id);


CREATE TABLE player_items (
player_id STRING(36) NOT NULL,
item_id INT64 NOT NULL,
quantity INT64 NOT NULL,
FOREIGN KEY(item_id) REFERENCES items(item_id)
) PRIMARY KEY(player_id, item_id),
INTERLEAVE IN PARENT players ON DELETE CASCADE;
```

When “Create” in 2. is selected, the creation of a table begins.

### **Completion of database creation**

![](https://storage.googleapis.com/egg-resources/egg3-2/public/5-5.png)

If it is successfully done, three tables are created as well when the database is created.

## [Exercise] 6. Writing data：Application

### **Adding player data from Web application**

Execute the `player` command that you built earlier.

```bash
export GOOGLE_CLOUD_PROJECT=$(gcloud config list project --format "value(core.project)")
./player
```

If la og such as below is output, the web server is running.

```bash
2021/04/28 01:14:25 Defaulting to port 8080
2021/04/28 01:14:25 Listening on port 8080
```

If a log such as below is output, the environmental variable of `GOOGLE_CLOUD_PROJECT` is not set.

```bash
2021/04/28 18:05:47 'GOOGLE_CLOUD_PROJECT' is empty. Set 'GOOGLE_CLOUD_PROJECT' env by 'export GOOGLE_CLOUD_PROJECT=<gcp project id>'
```

Do it again after setting the environmental variable.

```bash
export GOOGLE_CLOUD_PROJECT=$(gcloud config list project --format "value(core.project)")
```

Or,

```bash
GOOGLE_CLOUD_PROJECT={{project-id}} ./player
```

This web server registers, updates, and deletes new player information when it accepts a HTTP request to specific paths.
Now let’s send a request to create a new player to the web server. Send a HTTP POST request with the following command in the tab separate from the console running `player`.

```bash
curl -X POST -d '{"name": "testPlayer1", "level": 1, "money": 100}' localhost:8080/players
```

When you send `curl` command, you will receive a result such as below.

```bash
A new Player with the ID 78120943-5b8e-4049-acf3-b6e070d017ea has been added!
```

If you get the error message **`invalid character '\\' looking for beginning of value`** , remove the backslash (\\) character and run it without a newline when you execute the curl command.

This ID(`78120943-5b8e-4049-acf3-b6e070d017ea`) is a user ID created automatically by the application. From the database perspective, it is the primary key of the player table. You will use it in later exercises, so please write down the ID you get.

### **Note💡Secret of the primary key of Cloud Spanner**

We are using UUIDv4 here to randomly generate ID. The reason we use this mechanism is because we want the primary key to be distributed. In a general RDBMS, the primary key often uses a serial number for clarity, but Cloud Spanner uses the primary key itself like a shard key. This is because if you use a serial number for the primary key, the newly generated row will always be assigned to the backmost shard.

We generate UUID with the code below in main.go and use it as the primary key.

```
randomId, _ := uuid.NewRandom()
```

By the way, in Cloud Spanner this shard is called a “split”. Split is automatically split as needed.

## [Exercise] 6. Writing data： GUI of Cloud Console

### **Check player data from GUI console**

![](https://storage.googleapis.com/egg-resources/egg3-2/public/6-0.png)
![](https://storage.googleapis.com/egg-resources/egg3-2/public/6-1-1.png)
![](https://storage.googleapis.com/egg-resources/egg3-2/public/6-1-2.png)

1. Select the target table “players”
2. Select data tab
3. You can check the added record from the “data” menu (left side) on Cloud Console.

You can check the ID that generated this time from here as well.

### **Add player_items data from GUI console**

![](https://storage.googleapis.com/egg-resources/egg3-2/public/6-2-1.png)
![](https://storage.googleapis.com/egg-resources/egg3-2/public/6-2-2.png)
![](https://storage.googleapis.com/egg-resources/egg3-2/public/6-2-3.png)
![](https://storage.googleapis.com/egg-resources/egg3-2/public/6-2-4.png)

Next, let’s write the data. In this example, we assume that you are adding an item on the generated player.

1. Database player-db: Select overview
2. Select the table “player_items”
3. Select “Data” from menu (left side)
4. Select “Insert” button

### **Check how the insert fails by foreign key constraint**

![](https://storage.googleapis.com/egg-resources/egg3-2/public/6-3.png)

Enter the values according to the columns of the table.

- player_id：the ID you wrote down from “Writing data - Client Library”
 (example：78120943-5b8e-4049-acf3-b6e070d017ea)
- item_id：1
- quantity：1

Select “Save” after you enter the ID.
An error message such as below will be displayed.

![](https://storage.googleapis.com/egg-resources/egg3-2/public/6-4.png)

### **Adding items data from GUI console**

![](https://storage.googleapis.com/egg-resources/egg3-2/public/6-5-1.png)
![](https://storage.googleapis.com/egg-resources/egg3-2/public/6-5-2.png)
![](https://storage.googleapis.com/egg-resources/egg3-2/public/6-5-3.png)
![](https://storage.googleapis.com/egg-resources/egg3-2/public/6-5-4.png)

Let’s write item data. This example assumes that you are adding a new item to the entire game.

1. Database player-db: Select overview
2. Select “items” table
3. Select “Data” from the menu (left side)
4. Select “Insert” button

### **Adding items data from GUI console**

![](https://storage.googleapis.com/egg-resources/egg3-2/public/6-6.png)

Enter the values according to the columns of the table.

- item_id：1
- name：Herb
- price：50

After you enter them, select “save”.

### **Adding player_items data from GUI console**

![](https://storage.googleapis.com/egg-resources/egg3-2/public/6-7.png)

Enter the values according to the columns of the table.

- player_id：The ID you wrote down from “Writing data - Client Library
 (example：78120943-5b8e-4049-acf3-b6e070d017ea)
- item_id：1
- quantity：1

After you enter them, select “Save”.
This time you will succeed.

### **Modifying player data from GUI console**

![](https://storage.googleapis.com/egg-resources/egg3-2/public/6-8-1.png)
![](https://storage.googleapis.com/egg-resources/egg3-2/public/6-8-2.png)
![](https://storage.googleapis.com/egg-resources/egg3-2/public/6-8-3.png)
![](https://storage.googleapis.com/egg-resources/egg3-2/public/6-8-4.png)

1. Database player-db: Select overview
2. Select “players” table
3. Select “Data” from the menu (left side)
4. Select the checkbox of added user
5. Select “Edit” button

### **Modifying player data from GUI console**

![](https://storage.googleapis.com/egg-resources/egg3-2/public/6-9.png)

Enter the values according to the columns of the table.

- name：tester01

After you enter them, select “save”.
You can easily modify data in this way.

## [Exercise] 6. Writing data： From Cloud Console to SQL

### **items and player_items by SQL**

![](https://storage.googleapis.com/egg-resources/egg3-2/public/6-10.png)

1. Select “Query” from the menu (left side)
2. Paste the SQL next page into the input field
3. Select “Run”

You can execute any SQL from Cloud Console in this way.

### **Insertion of items and player_items by SQL**

Paste the following SQL into “DDL statement” and select “Run”.

```sql
INSERT INTO items (item_id, name, price)
VALUES (2, 'Great Herb', 500);
```

When the writing is successful, “One row has been inserted” is displayed in the result field.

Modify the player_id(`78120943-5b8e-4049-acf3-b6e070d017ea` in this example) of the following SQL, paste it into “DDL statement” and then select “Run the query”.

```sql
INSERT INTO player_items (player_id, item_id, quantity)
VALUES ('78120943-5b8e-4049-acf3-b6e070d017ea', 2, 5);
```

When the writing is successful, “One row has been inserted” is displayed in the result field.

## [Exercise] 6. Writing data： SQL from spanenr-cli

### **Operating interactively by SQL**

Run the following command and you can connect to Cloud Spanner.

```bash
spanner-cli -p $GOOGLE_CLOUD_PROJECT -i dev-instance -d player-db
```

![](https://storage.googleapis.com/egg-resources/egg3/public/6-11.png)

For example, run the following SELECT statement to display the player’s item list.

```sql
SELECT players.name, items.name, player_items.quantity FROM players
JOIN player_items ON players.player_id = player_items.player_id
JOIN items ON player_items.item_id = items.item_id;
```

Add EXPLAIN at the head of the SELECT statement above and run it. Query plan will be displayed. Query plan can also be displayed on Cloud Console.

```sql
EXPLAIN
SELECT players.name, items.name, player_items.quantity FROM players
JOIN player_items ON players.player_id = player_items.player_id
JOIN items ON player_items.item_id = items.item_id;
```

### **How to use spanner-cli**

[GitHub repository of spanner-cli](https://github.com/cloudspannerecosystem/spanner-cli) contains a detailed guide on how to use spanner-cli. Let’s run some queries on Cloud Spanner with this guide.

### **Appendix) How to run Web application**

- Newly added player

```bash
curl -X POST -d '{"name": "testPlayer1", "level": 1, "money": 100}' localhost:8080/players
```

- Get the list of player

```bash
curl localhost:8080/players
```

- Update player

```bash
curl -X PUT -d '{"playerId":"afceaaab-54b3-4546-baba-319fc7b2b5b0","name": "testPlayer1", "level": 2, "money": 200}' localhost:8080/players
```

- Delete player

```bash
curl -X DELETE http://localhost:8080/players/afceaaab-54b3-4546-baba-319fc7b2b5b0
```

## Thank You

That’s it for the Cloud Spanner hands-on.
All you have to do now is to use Cloud Spanner as a database!
