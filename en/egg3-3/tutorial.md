# E.G.G hands-on #1


## Selecting Google Cloud project


Make a Google Cloud project that you do the hands-on, select Google Cloud project, and Click **Start**.


**Since this hands-on uses Firestore Native mode, please create a new project at it may cause inconvenience if it is an existing project (especially if you are already using it).**




<walkthrough-project-setup>
</walkthrough-project-setup>




<!-- Step 1 -->
## Introduction


### **Overview and objective**


In this hands-on, we build a test application and learn how to connect to Cloud Firestore and Cloud Memorystore to do the query for the Cloud Run beginner. The objective of this hands-on  is for you to grasp the image of application development using Cloud Run.


### **Prerequisite**


This hands-on is intended for those who are new to Cloud Run. No prior knowledge is required to go through this hands-on.
If you want to know more about the GCP product that we use in this hands-on, we recommend you to use Coursera materials and official documents for further study.


### **Target product**


Following is the list of the products we learn today.


- Cloud Run
- Cloud Firestore
- Cloud Memorystore
- Serverless VPC access




<!-- Step 2 -->
## Contents of this hands-on


You will learn the following subject in hands-on style.


### **Learning step**
- Preparing environment：10 minutes
  - Creating project
  - Setting up gcloud command line tool
  - Enabling GCP features（API）


- Application development using [Cloud Run](https://cloud.google.com/run) ：60 minutes
  - Containerization of sample application
  - Registering container to [Google Container Registry](https://cloud.google.com/container-registry/) 
  - Deploying Cloud Run
  - Using Cloud Firestore
  - Setting serverless VPC access
  - Using Cloud Memorystore for Redis
  - Advanced exercise


- Cleanup：10 minutes
  - Deleting whole project
  - （Option）Deleting individual resources
    - Deleting Cloud Run
    - Deleting Cloud Firestore
    - Deleting Cloud Memorystore
    - Deleting Serverless VPC Access connector
    - Deleting VPC Subnet and VPC
    - Deleting container image that is registered to Container Registry
    - Deleting  dev-key.json with owner access
    - Deleting service account dev-egg-sa




<!-- Step 3 -->
## Preparing environment


<walkthrough-tutorial-duration duration=10></walkthrough-tutorial-duration>


First, we prepare an environment for the hands-on.


You need to set up the following;


- Setting up gcloud command line tool
- Enabling GCP features（API）
- Setting up service account




<!-- Step 4 -->
## gcloud command line tool


Google Cloud can be operated via CLI, GUI, and Rest API. In this hands-on we mainly use CLI, but you can also check by GUI from the URLs on this hands-on.




### What is gcloud command line tool?


gcloud command line interface is the main CLI tool in GCP. With this tool, you can execute many general platform tasks from command line, script, or other automation. 


For example, you can create and maintain following things using gcloud CLI.


- Google Compute Engine virtual machine
- Google Kubernetes Engine cluster
- Google Cloud SQL instance


**Tips**: You can find more details on gcloud command line tool [here](https://cloud.google.com/sdk/gcloud?hl=ja).


<walkthrough-footnote>Next, you set up for using gcloud CLI for hands-on.</walkthrough-footnote>




<!-- Step 5 -->
## Setting up gcloud command line tool


The gcloud command requires the setting of the project to be operated.


### Setting GCP project ID in environment variable


Set GCP project ID in the environment variable `GOOGLE_CLOUD_PROJECT` 


```bash
export GOOGLE_CLOUD_PROJECT="{{project-id}}"
```


### Setting up a GCP default project that you use from CLI（gcloud command）


Set up the project to be operated.


```bash
gcloud config set project $GOOGLE_CLOUD_PROJECT
```


### Setting up default region


Set the default region that you specify when you create a regional source. 


```bash
gcloud config set compute/region us-central1
```




<walkthrough-footnote>You are ready to use CLI (gcloud). Next, enable the functions used in the hands-on.</walkthrough-footnote>




<!-- Step 6 -->
## GCP environment setting Part1


You need to enable each functions you want to use in GCP.
Let’s enable the functions that you use in the hands-on.




### Enable GCP’s API that you use in the hands-on


Enable following functions.


<walkthrough-enable-apis></walkthrough-enable-apis>


- Cloud Build API
- Google Container Registry API
- Google Cloud Firestore API
- Google Cloud Memorystore for Redis API
- Serverless VPC Access API


```bash
gcloud services enable \
  cloudbuild.googleapis.com \
  containerregistry.googleapis.com \
  run.googleapis.com \
  redis.googleapis.com \
  vpcaccess.googleapis.com \
  servicenetworking.googleapis.com
```


**GUI**: [API library](https://console.cloud.google.com/apis/library?project={{project-id}})


<!-- Step 7 -->
## GCP environment setting Part2


### Creating service account


Create a service account used in local development. 


```bash
gcloud iam service-accounts create dev-egg-sa
```


It grants access to the created service account. **It gives owner access in this hands-on, but please grant appropriate access level in the actual development.**


```bash
gcloud projects add-iam-policy-binding {{project-id}} --member "serviceAccount:dev-egg-sa@{{project-id}}.iam.gserviceaccount.com" --role "roles/owner"
```


Create a key file.


```bash
gcloud iam service-accounts keys create dev-key.json --iam-account dev-egg-sa@{{project-id}}.iam.gserviceaccount.com
```


**GUI**: [Service account](https://console.cloud.google.com/iam-admin/serviceaccounts?project={{project-id}})


Set the created key in environment variable.


```bash
export GOOGLE_APPLICATION_CREDENTIALS=$(pwd)/dev-key.json
```


<!-- Step 8 -->
## GCP environment setting Part3


### Enabling Firestore


We use the native mode of Firestore in this hands-on.


Move to the [Datastore](https://console.cloud.google.com/datastore/entities/query/kind?project={{project-id}}) of GCP console, and click [SWITCH TO NATIVE MODE]. Select `us-east1` in the location selection.


1. Switching screen


![switch1](https://storage.googleapis.com/egg-resources/egg1/public/firestore-switch-to-native1.png)
![switch2](https://storage.googleapis.com/egg-resources/egg1/public/firestore-switch-to-native2.png)


2. This screen could be displayed instead of the above. Select the native mode as well.


![select-firestore-mode](https://storage.googleapis.com/egg-resources/egg1/public/select-mode.png)


3. When the native mode is enabled, data management screen is enabled in [Firestore console](https://console.cloud.google.com/firestore/data/?project={{project-id}})


**In Datastore mode, you can also switch to native mode if you have not registered any data yet.**


<walkthrough-footnote>Now you can use the required functions. Next, we will develop a Cloud Run application.</walkthrough-footnote>




<!-- Step 9 -->
## Application development using Cloud Run


<walkthrough-tutorial-duration duration=60></walkthrough-tutorial-duration>


Let’s experience application development using Cloud Run.


Follow the steps below.
  - Containerizing the sample application
  - Registering the container to [Google Container Registry](https://cloud.google.com/container-registry/) 
  - Deploying Cloud Run
  - Utilizing Cloud Firestore 
  - Setting serverless VPC access
  - Utilizing Cloud Memorystore for Redis
  - Advanced exercise




<!-- Step 10 -->
## Checking application code


**The code of this step is same as answer/step10/main.go**


Let’s make an API server by Go as a sample Web application for the hands-on.


First, check main.go in the current directory.
This is a Go code that returns `Hello, EGG!` to a simple HTTP request.




```go:main.go
package main


import (
        "fmt"
        "log"
        "net/http"
        "os"
)


func main() {
        http.HandleFunc("/", indexHandler)


        port := os.Getenv("PORT")
        if port == "" {
                port = "8080"
                log.Printf("Defaulting to port %s", port)
        }


        log.Printf("Listening on port %s", port)
        if err := http.ListenAndServe(":"+port, nil); err != nil {
                log.Fatal(err)
        }
}


func indexHandler(w http.ResponseWriter, r *http.Request) {
        fmt.Fprint(w, "Hello, Egg!")
}
```


Once you checked it, let’s run it locally.


```bash
go run main.go
```


It is the same as a normal Go application so far.


**Note：Please note that this code is just a sample implementation.**


<walkthrough-footnote>You have just created an application and launched it. Next, let’s actually access the application.</walkthrough-footnote>




<!-- Step 11 -->
## Launching the application on Cloud Shell


### Accessing the launched application using CloudShell functions


Click the icon at the upper right corner of the display <walkthrough-web-preview-icon></walkthrough-web-preview-icon> and select “Port for preview: 8080”.
New tab will be opened in the browser by this, and you can access the container launched on Cloud Shell.


When you correctly access the application, **Hello, EGG!** will be displayed.


After you checked it, type Ctrl+c on Cloud Shell to stop the running application.


Now you accessed the application running in <walkthrough-footnote>local environment（inside Cloud Shell). Next, let’s containerize the application.</walkthrough-footnote>




<!-- Step 12 -->
## Launching containerized application on Cloud Shell 


### Making container


Containerize the sample Web application written in Go.
The container we created here is saved at the local of Cloud Shell instance.


```bash
docker build -t gcr.io/$GOOGLE_CLOUD_PROJECT/egg1-app:v1 .
```


**Tips**: Entering `docker build` command will load the Dockerfile and create the container with the process as described there. 


### Launching container on Cloud Shell


Launch container, which is created with the above procedure, on Cloud Shell 


```bash
docker run -p 8080:8080 \
--name egg1-app \
-e GOOGLE_APPLICATION_CREDENTIALS=/tmp/keys/dev-key.json \
-v $PWD/dev-key.json:/tmp/keys/dev-key.json:ro \
gcr.io/$GOOGLE_CLOUD_PROJECT/egg1-app:v1
```


**Tips**: The 8080 port in the Cloud Shell environment is linked to the 8080 port in the container and launched in the foreground.


<walkthrough-footnote>Now you containerized the application and launched it. Next, let’s actually access the application.</walkthrough-footnote>




<!-- Step 13 -->
## Checking the operation of created container


### Utilizing the functions of Cloud Shell to access the launched application


Click the icon on the upper right corner <walkthrough-web-preview-icon></walkthrough-web-preview-icon> and select "Port for preview: 8080"
New tab will be opened in the browser, and you can access the container launched on Cloud Shell.


When you access the application correctly, it displays  `Hello EGG!` as before.


Once you checked it, type Ctrl+c on Cloud Shell to stop the running container.


<walkthrough-footnote>Now you accessed the container running on local environment (within Cloud Shell). Next, you prepare to deploy to Cloud Run.</walkthrough-footnote>




<!-- Step 14 -->
## Registering to container registry


The container you just created is saved at local and cannot be referenced from anywhere else. 
Register it on private container storage on GCP (Container registry) so that it can be used elsewhere.


### Registering (Push) the created container on the container registry (Google Container Registry)


```bash
docker push gcr.io/$GOOGLE_CLOUD_PROJECT/egg1-app:v1
```


**GUI**: [Container registry](https://console.cloud.google.com/gcr/images/{{project-id}}?project={{project-id}})


<walkthrough-footnote>Next, let’s deploy the container on Cloud Run</walkthrough-footnote>




<!-- Step 15 -->
## Deploying container on Cloud Run


### Creating a Cloud Run service with gcloud command to deploy container


The name of Cloud Run is egg1-app.


```bash
gcloud run deploy --image=gcr.io/$GOOGLE_CLOUD_PROJECT/egg1-app:v1 \
  --service-account="dev-egg-sa@{{project-id}}.iam.gserviceaccount.com" \
  --platform=managed \
  --region=us-central1 \
  --allow-unauthenticated \
  egg1-app
```


**Note**: It takes 1-2 minutes to complete the deployment.


**GUI**: [Cloud Run](https://console.cloud.google.com/run?project={{project-id}})


### Get the URL of the Cloud Run Service
```bash
URL=$(gcloud run services describe --format=json --region=us-central1 --platform=managed egg1-app | jq .status.url -r)
echo ${URL}
```


Open the URL you get from the browser and check the operation of the application.


**GUI**: [Cloud Run service information](https://console.cloud.google.com/run/detail/us-central1/egg1-app/general?project={{project-id}})




<!-- Step 16 -->
## Checking the log of Cloud Run


### Checking the log of the container
**GUI**: [Cloud Run log](https://console.cloud.google.com/run/detail/us-central1/egg1-app/logs?project={{project-id}})


Check the access log.


<walkthrough-footnote>Sample Web application was deployed on Cloud Run. Next, you set up Cloud Build.</walkthrough-footnote>






<!-- Step 17 -->
## Automation of build and deploy by Cloud Build


Cloud Build を利用し今まで手動で行っていたアプリケーションのビルド、コンテナ化、リポジトリへの登録、Cloud Run へのデプロイを自動化します。
Use Cloud Build to automate previously manual-operated application builds, containerization, registrations to repository, and deployments to Cloud Run.


### Adding permission to the service account of Cloud Build


Get the service account used when running Cloud Build, and store it in environmental variable. 


```bash
export CB_SA=$(gcloud projects get-iam-policy $GOOGLE_CLOUD_PROJECT | grep cloudbuild.gserviceaccount.com | uniq | cut -d ':' -f 2)
```


Grant permission for the Cloud Run admin to auto-deploy on the service account you got above from Cloud Build.


```bash
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT  --member serviceAccount:$CB_SA --role roles/run.admin
```


```bash
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT  --member serviceAccount:$CB_SA --role roles/iam.serviceAccountUser
```


<walkthrough-footnote>Now you grant permission to the service account you use on Cloud Build to make auto-deployment to Cloud Run available.</walkthrough-footnote>




<!-- Step 18 -->
## Automation of build and deployment by Cloud Build


### Checking cloudbuild.yaml


Check the contents of `cloudbuild.yaml` under the `egg3-3`  folder where the details of the jobs of Cloud Run are defined.


```
steps:
- name: 'gcr.io/cloud-builders/docker'
  args: ['build', '-t', 'gcr.io/$PROJECT_ID/egg1-app:$BUILD_ID', '.']


- name: 'gcr.io/cloud-builders/docker'
  args: ['push', 'gcr.io/$PROJECT_ID/egg1-app:$BUILD_ID']


- name: 'gcr.io/cloud-builders/gcloud'
  args: [
    'run',
    'deploy',
    '--image=gcr.io/$PROJECT_ID/egg1-app:$BUILD_ID',
    '--service-account=dev-egg-sa@$PROJECT_ID.iam.gserviceaccount.com',
    '--platform=managed',
    '--region=us-central1',
    '--allow-unauthenticated',
    '--set-env-vars',
    'GOOGLE_CLOUD_PROJECT=$PROJECT_ID',
    'egg1-app',
  ]
```


When building the container with the docker build command, the tag of the container was `gcr.io/{{project-id}}/egg1-app:v1`, but in Cloud Build it is `gcr.io/{{project-id}}/egg1-app:$BUILD_ID`. $BUILD_ID should be the job ID of Cloud Build.


<walkthrough-footnote>Now let’s run the Cloud Build job.</walkthrough-footnote>




<!-- Step 19 -->
## Automation of build and deployment by Cloud Build


### Running the Cloud Build job


```bash
gcloud builds submit --config cloudbuild.yaml .
```


** Tips **: The `.` at the end of the command indicates that  `cloudbuild.yaml` exists in the current directory.




### Checking the job


[History of Cloud Build] Access (https://console.cloud.google.com/cloud-build/builds?project={{project-id}}) to check that the build is executed.




### Checking Cloud Run


Make sure the image URL of the container of Cloud Run is the image created by Cloud Build. 


**GUI**: [Cloud Run revision](https://console.cloud.google.com/run/detail/us-central1/egg1-app/revisions?project={{project-id}})




<walkthrough-footnote>The set up of auto build and deploy by Cloud Build is completed. Next, let’s implement Firestore.</walkthrough-footnote>




<!-- Step 20 -->
## Using Firestore


Edit the sample web application to use Firestore. In this step, implement basic CRUD processing.


### Adding dependency


Add a client library to access Firestore.
In the case of Go language, you can set up the dependency of the Go package by `go.mod`.


`go.mod` file with every dependency you use in this hands-on written is already stored in the `egg3-3` folder. 


```
module github.com/google-cloud-japan/egg-training-materials/egg3-3


go 1.13


require (
        cloud.google.com/go/firestore v1.3.0
        github.com/gomodule/redigo v2.0.0+incompatible
        golang.org/x/net v0.0.0-20200904194848-62affa334b73 // indirect
        golang.org/x/oauth2 v0.0.0-20200902213428-5d25da1a8d43 // indirect
        golang.org/x/sys v0.0.0-20200909081042-eff7692f9009 // indirect
        golang.org/x/tools v0.0.0-20200913032122-97363e29fc9b // indirect
        google.golang.org/api v0.31.0
        google.golang.org/genproto v0.0.0-20200911024640-645f7a48b24f // indirect
        google.golang.org/grpc v1.32.0 // indirect
)
```


<walkthrough-footnote>Let’s implement the code to operate Firestore.</walkthrough-footnote>




<!-- Step 21 -->
## Using Firestore


### Functions for adding and getting data


**You can see the code created in this step at answer/step21/main.go **


Add the code below in the `main.go` file.
First, add the code below in import.


```go
"encoding/json"
"io"
"strconv"
"cloud.google.com/go/firestore"
"google.golang.org/api/iterator"
```


Next, add a handler to the main function.


```go
        http.HandleFunc("/", indexHandler) // This is an existing line
        http.HandleFunc("/firestore", firestoreHandler)
```


Then, add a code that posts request data to Firestore. Add the code below at the bottom.


```go
func firestoreHandler(w http.ResponseWriter, r *http.Request) {


        // Creating Firestore client
        pid := os.Getenv("GOOGLE_CLOUD_PROJECT")
        ctx := r.Context()
        client, err := firestore.NewClient(ctx, pid)
        if err != nil {
                log.Fatal(err)
        }
        defer client.Close()


        switch r.Method {
        // Method  to post
        case http.MethodPost:
                u, err := getUserBody(r)
                if err != nil {
                        log.Fatal(err)
                        w.WriteHeader(http.StatusInternalServerError)
                        return
                }
                ref, _, err := client.Collection("users").Add(ctx, u)
                if err != nil {
                        log.Fatalf("Failed adding data: %v", err)
                        w.WriteHeader(http.StatusInternalServerError)
                        return
                }
                log.Print("success: id is %v", ref.ID)
                fmt.Fprintf(w, "success: id is %v \n", ref.ID)


        // Method to get
        case http.MethodGet:
                iter := client.Collection("users").Documents(ctx)
                var u []Users


                for {
                        doc, err := iter.Next()
                        if err == iterator.Done {
                                break
                        }
                        if err != nil {
                                log.Fatal(err)
                        }
                        var user Users
                        err = doc.DataTo(&user)
                        if err != nil {
                                log.Fatal(err)
                        }
                        user.Id = doc.Ref.ID
                        log.Print(user)
                        u = append(u, user)
                }
                if len(u) == 0 {
                        w.WriteHeader(http.StatusNoContent)
                } else {
                        json, err := json.Marshal(u)
                        if err != nil {
                                w.WriteHeader(http.StatusInternalServerError)
                                return
                        }
                        w.Write(json)
                }


        // Other HTTP methods
        default:
                w.WriteHeader(http.StatusMethodNotAllowed)
                return
        }
}


type Users struct {
        Id    string `firestore:id, json:id`
        Email string `firestore:email, json:email`
        Name  string `firestore:name, json:name`
}


func getUserBody(r *http.Request) (u Users, err error) {
        length, err := strconv.Atoi(r.Header.Get("Content-Length"))
        if err != nil {
                return u, err
        }


        body := make([]byte, length)
        length, err = r.Body.Read(body)
        if err != nil && err != io.EOF {
                return u, err
        }


        //parse json
        err = json.Unmarshal(body[:length], &u)
        if err != nil {
                return u, err
        }
        log.Print(u)
        return u, nil
}


```


This code posts data to the Firestore of the actual project or gets data from Firestore.


<walkthrough-footnote>Next, let’s deploy the code and check the operation.</walkthrough-footnote>




<!-- Step 22 -->
## Deployment and Checking (Add functions to register and get to/from Firestore)


### Deployment to Cloud Run


Run Cloud Build and deploy the application to Cloud Run.


```bash
gcloud builds submit --config cloudbuild.yaml .
```


### Displaying URLs


Display URLs with the command below.


```bash
echo $URL
```


### Performing operation using Firestore


Execute cURL command such as below to the URL of the Service of Cloud Run from Cloud Shell and confirm that the data registration and acquisition process is performed.


**Registration**


```
curl -X POST -d '{"email":"tamago@example.com", "name":"Tamago Taro"}' ${URL}/firestore
```


**Acquisition（All）**


```
curl ${URL}/firestore
```


<walkthrough-footnote>Next, let’s implement the update/delete of registered data</walkthrough-footnote>




<!-- Step 23 -->
## Using Firestore 
### Data update/delete process


**You can find the code in this step at answer/step23/main.go**


In the data registration process implemented in the previous step, a unique ID was assigned to each data.
Add a process to update and delete data using that ID.


Update API targets unique user data by setting ID value on Doc and updates with the contents of the request received by Set function.
Delete API is in the format to specify an ID by a path parameter.


Add the following code in the import in the `main.go` 


```go
"strings"
```


Add the following code in the HandleFunc in the main function.


```go
        http.HandleFunc("/firestore/", firestoreHandler)
```


Next, add the following case phrase after the case phrase of  `MethodGet`


```go
        // Update method
        case http.MethodPut:
                u, err := getUserBody(r)
                if err != nil {
                        log.Fatal(err)
                        w.WriteHeader(http.StatusInternalServerError)
                        return
                }


                _, err = client.Collection("users").Doc(u.Id).Set(ctx, u)
                if err != nil {
                        w.WriteHeader(http.StatusInternalServerError)
                        return
                }


                fmt.Fprintln(w, "success updating")


        // Delete method
        case http.MethodDelete:
                id := strings.TrimPrefix(r.URL.Path, "/firestore/")
                _, err := client.Collection("users").Doc(id).Delete(ctx)
                if err != nil {
                        w.WriteHeader(http.StatusInternalServerError)
                        return
                }
                fmt.Fprintln(w, "success deleting")
```


<walkthrough-footnote>Now the data update/delete function is implemented. Let’s deploy it to Cloud Run</walkthrough-footnote>




<!-- Step 24 -->
## Deployment and Checking (Adding update/delete function to Firestore)


### Deploying to Cloud Run


Run the Cloud Build and deploy the application to Cloud Run.


```bash
gcloud builds submit --config cloudbuild.yaml .
```


### Displaying URL


Display the URL with the following command.


```bash
echo $URL
```


### Performing operations using Firestore 


Execute some cURL commands such as below to the URL of the Service of the Cloud Run from Cloud Shell and confirm the data update/delete processes are performed.


**Update**


Set the value of  `id` that you confirmed in the console etc. to `<ID>`.


![firestore-id](https://storage.googleapis.com/egg-resources/egg1/public/firestore-id.jpg)


```
curl -X PUT -d '{"id": "<ID>", "email":"egg@example.com", "name":"Egg Taro"}' ${URL}/firestore
```


**Delete**


Specify the value of  `id` to be deleted to `<ID>`


```
curl -X DELETE ${URL}/firestore/<ID>
```


<walkthrough-footnote>That’s it for the implementation on Firestore. Next, let’s make Memorystore operable.</walkthrough-footnote>




<!-- Step 25 -->
## Making a connector for Serverless VPC Access


From here on, we will  integrate Memorystore with Cloud Run.
First, create a VPC network.


```bash
gcloud compute networks create eggvpc --subnet-mode=custom
```


```bash
gcloud compute networks subnets create us-subnet --network=eggvpc --region=us-central1 --range=10.128.0.0/20
```


```bash
gcloud compute networks vpc-access connectors create egg-vpc-connector \
--network eggvpc \
--region us-central1 \
--range 10.129.0.0/28
```




<!-- Step 26 -->
## Using Memorystore for Redis 


Let’s cache data using Memorystore for Redis.
Modify the Firestore data so that it can be returned from the cache.


### Creating Redis instance


```bash
gcloud redis instances create --network=eggvpc --region=us-central1 eggcache
```




<!-- Step 27 -->
## Modifying Firestore handler 


**You can find the code for this step at answer/step27/main.go**


Currently, we are just getting everything, so caching is pointless. First, let’s modify it to get the key.


Let’s modify the MethodGet of the firestoreHandler of `main.go`. Modify it to the following code.


```go
        // Get method
        case http.MethodGet:
                id := strings.TrimPrefix(r.URL.Path, "/firestore/")
                log.Printf("id=%v", id)
                if id == "/firestore" || id == "" {
                        iter := client.Collection("users").Documents(ctx)
                        var u []Users


                        for {
                                doc, err := iter.Next()
                                if err == iterator.Done {
                                        break
                                }
                                if err != nil {
                                        log.Fatal(err)
                                }
                                var user Users
                                err = doc.DataTo(&user)
                                if err != nil {
                                        log.Fatal(err)
                                }
                                user.Id = doc.Ref.ID
                                log.Print(user)
                                u = append(u, user)
                        }
                        if len(u) == 0 {
                                w.WriteHeader(http.StatusNoContent)
                        } else {
                                json, err := json.Marshal(u)
                                if err != nil {
                                        w.WriteHeader(http.StatusInternalServerError)
                                        return
                                }
                                w.Write(json)
                        }
                } else {
                        // (Step 29) Replace from here
                        doc, err := client.Collection("users").Doc(id).Get(ctx)
                        if err != nil {
                                w.WriteHeader(http.StatusInternalServerError)
                                return
                        }
                        var u Users
                        err = doc.DataTo(&u)
                        if err != nil {
                                log.Fatal(err)
                        }
                        u.Id = doc.Ref.ID
                        json, err := json.Marshal(u)
                        if err != nil {
                                w.WriteHeader(http.StatusInternalServerError)
                                return
                        }
                        w.Write(json)
                        // (Step 29) Replace up to here
                }
```


Now we can get unique user data.




<!-- Step 28 -->
## Modifying  Firestore handler


Next, add the code to operate Redis.


**You can find the code for this step at answer/step28/main.go**


Add the following code in the import.


```go
"github.com/gomodule/redigo/redis"
```


Add the following code as the first process of main function. 


```go
        // Redis
        initRedis()
```


Add the following code at the end of `main.go`.


```go
var pool *redis.Pool


func initRedis() {
        var (
                host = os.Getenv("REDIS_HOST")
                port = os.Getenv("REDIS_PORT")
                addr = fmt.Sprintf("%s:%s", host, port)
        )
        pool = redis.NewPool(func() (redis.Conn, error) {
                return redis.Dial("tcp", addr)
        }, 10)
}
```


Add the following code between the block created by Firestore client and switch clause.


```go
                        conn := pool.Get()
                        defer conn.Close()
```


Add the code to get/set cache to the previous code that gets single user data.
Replace the range of code from the comment `(Step 28) Replace from here` to `(Step 28) Replace up to here` in the Get method to the following code.


```go
                        // (Step 28) Replace from here
                        // Creating Redis client
                        cache, err := redis.String(conn.Do("GET", id))
                        if err != nil {
                                log.Println(err)
                        }
                        log.Printf("cache : %v", cache)


                        if cache != "" {
                                json, err := json.Marshal(cache)
                                if err != nil {
                                        w.WriteHeader(http.StatusInternalServerError)
                                        return
                                }
                                w.Write(json)
                                log.Printf("find cache")
                        } else {
                                doc, err := client.Collection("users").Doc(id).Get(ctx)
                                if err != nil {
                                        w.WriteHeader(http.StatusInternalServerError)
                                        return
                                }
                                var u Users
                                err = doc.DataTo(&u)
                                if err != nil {
                                        log.Fatal(err)
                                }
                                u.Id = doc.Ref.ID
                                json, err := json.Marshal(u)
                                if err != nil {
                                        w.WriteHeader(http.StatusInternalServerError)
                                        return
                                }
                                conn.Do("SET", id, string(json))
                                w.Write(json)
                        }
                        // (Step 28) Replace up to here
```


<!-- Step 29 -->
## Updating Cloud Run deployment options


You can perform the connection set up of Serverless VPC Access by specifying `--vpc-connector` when deploying Cloud Run.
Also, with environment variables, you can make the Cloud Run container have the connection information to Memorystore for Redis.


### Confirming the IP address of Redis instance 


Get the IP address of Redis instance by executing the following command.


```bash
gcloud redis instances list --format=json  --region=us-central1 | jq '.[0].host'
```


### Updating cloudbuild.yaml 


Update cloudbuild.yaml as below.


Specify the IP address of REDIS_HOST that you created  for the `XXX.XXX.XXX.XXX` of **REDIS_HOST** 


```
steps:
- name: 'gcr.io/cloud-builders/docker'
  args: ['build', '-t', 'gcr.io/$PROJECT_ID/egg1-app:$BUILD_ID', '.']


- name: 'gcr.io/cloud-builders/docker'
  args: ['push', 'gcr.io/$PROJECT_ID/egg1-app:$BUILD_ID']


- name: 'gcr.io/cloud-builders/gcloud'
  args: [
    'run',
    'deploy',
    '--image=gcr.io/$PROJECT_ID/egg1-app:$BUILD_ID',
    '--vpc-connector=egg-vpc-connector',
    '--service-account=dev-egg-sa@$PROJECT_ID.iam.gserviceaccount.com',
    '--platform=managed',
    '--region=us-central1',
    '--allow-unauthenticated',
    '--set-env-vars',
    'GOOGLE_CLOUD_PROJECT=$PROJECT_ID',
    '--set-env-vars',
    'REDIS_HOST=XXX.XXX.XXX.XXX',
    '--set-env-vars',
    'REDIS_PORT=6379',
    'egg1-app',
  ]
```




<!-- Step 30 -->
## Deployment and checking (Adding cache function)


### Deploying to Cloud Run


Let’s run the Cloud Build and deploy the application to the Cloud Run.


```bash
gcloud builds submit --config cloudbuild.yaml .
```


### Displaying URL


Display the URL with the following command.


```bash
echo $URL
```


Access twice with the ID of the data registered to Firestore endpoint and confirm that the response time is shorter (i.e. cache is working).


```bash
curl ${URL}/firestore/<ID>
```


### Checking the log of container
**GUI**: [Cloud Run log](https://console.cloud.google.com/run/detail/us-central1/egg1-app/logs?project={{project-id}})


Confirm by the access log  that the time to process the second access is shorter.


<walkthrough-footnote>That’s it for the hands-on. Thank you!</walkthrough-footnote>




<!-- Step 31 -->
## Advanced exercise: Gradual deployment of the new revision of Cloud Run 


Cloud Run has the function to switch traffic between revisions, and you can perform the tasks such as A/B testing or Canary deployment. Modify the phrase `Hello, EGG!` in main.go to any word you choose and try the gradual migration of traffic by following the steps below.


### Modifying couldbuild.yaml 


Add **--no-traffic** in the deployment options of Cloud Run as below.


Specify the IP address of REDIS_HOST that you created  for the `XXX.XXX.XXX.XXX` of **REDIS_HOST** 


```
steps:
- name: 'gcr.io/cloud-builders/docker'
  args: ['build', '-t', 'gcr.io/$PROJECT_ID/egg1-app:$BUILD_ID', '.']


- name: 'gcr.io/cloud-builders/docker'
  args: ['push', 'gcr.io/$PROJECT_ID/egg1-app:$BUILD_ID']


- name: 'gcr.io/cloud-builders/gcloud'
  args: [
    'run',
    'deploy',
    '--no-traffic',
    '--image=gcr.io/$PROJECT_ID/egg1-app:$BUILD_ID',
    '--vpc-connector=egg-vpc-connector',
    '--service-account=dev-egg-sa@$PROJECT_ID.iam.gserviceaccount.com',
    '--platform=managed',
    '--region=us-central1',
    '--allow-unauthenticated',
    '--set-env-vars',
    'GOOGLE_CLOUD_PROJECT=$PROJECT_ID',
    '--set-env-vars',
    'REDIS_HOST=XXX.XXX.XXX.XXX',
    '--set-env-vars',
    'REDIS_PORT=6379',
    'egg1-app',
  ]
```


### Executing Cloud Build job


```bash
gcloud builds submit --config cloudbuild.yaml .
```


### Confirming revision information


Execute the following command.


```bash
gcloud run revisions list --platform=managed --region=us-central1 --service=egg1-app
```


Since **--no-traffic** is specified, the previous revision is still processing the traffic


**GUI**: [Changes to Cloud Run (Revision)](https://console.cloud.google.com/run/detail/us-central1/egg1-app/revisions?hl=ja&project={{project-id}})




### Executing Cloud Run traffic switching


Switch all traffic to the latest revision with the following command.


```bash
gcloud run services update-traffic --to-latest --platform=managed --region=us-central1 egg1-app
```


**GUI**: [Changes to Cloud Run (Revision)](https://console.cloud.google.com/run/detail/us-central1/egg1-app/revisions?hl=ja&project={{project-id}})




### Checking the application


Display the URL with the following command.


```bash
echo $URL
```




## Advanced exercise: Deployment triggered by the commit to Cloud Source Repositories


Create a repository at [Cloud Source Repositories](https://cloud.google.com/source-repositories/), set up a [Cloud Build trigger](https://cloud.google.com/cloud-build/docs/running-builds/automate-builds), and automate the build of application and  deployment to Cloud Run triggered by Push of Git.


### Creating Git repository at Cloud Source Repository (CSR)


Create a private Git repository to store the source code we are using in this hands-on at 
Cloud Source Repository (CSR).


```bash
gcloud source repos create egg1-handson
```


**GUI**: [Source Repository](https://source.cloud.google.com/{{project-id}}/egg1-handson): The access before creating it will be denied.


### Creating Cloud Build trigger


Create a trigger that will be triggered when performing push to the private Git repository that you created at Cloud Build in the previous step.


```bash
gcloud beta builds triggers create cloud-source-repositories --description="egg1handson" --repo=egg1-handson --branch-pattern=".*" --build-config="gaming/egg3-3/cloudbuild.yaml"
```


**GUI**: [Build trigger](https://console.cloud.google.com/cloud-build/triggers?project={{project-id}})


### Setting Git client


Set up the Git client to authenticate with CSR.


```bash
git config --global credential.https://source.developers.google.com.helper gcloud.sh
```


**Tips**: This is a configuration to link the git command and the IAM account used in gcloud 


### User setting


Replace USERNAME with your user name and execute it to set up the user.


```bash
git config --global user.name "USERNAME"
```


### Email address setting


Replace USERNAME@EXAMPLE.com with your email address and execute it to set up the user’s email address. 


```bash
git config --global user.email "USERNAME@EXAMPLE.com"
```


### Git repository setting


Register the CSR as the Git remote repository. 
You can now use git commands to  manage the files on Cloud Shell


```bash
git remote add google https://source.developers.google.com/p/$GOOGLE_CLOUD_PROJECT/r/egg1-handson
```


### Transferring materials to CSR (Push)


The CSR you created in the previous step is empty.
Transfer (Push) the materials to CSR using git push command.


```bash
git push google master
```


You can confirm that the materials are pushed from **GUI**: [Source Repository](https://source.cloud.google.com/{{project-id}}/egg1-handson) 




### Confirming that Cloud Build automatically runs


Access [History of Cloud Build](https://console.cloud.google.com/cloud-build/builds?project={{project-id}}) and confirm that the build was being executed at the time git push command was executed.
This build has probably failed. If you have more time, check the Cloud Build log to see where the error is and fix it!




## Congraturations!


<walkthrough-conclusion-trophy></walkthrough-conclusion-trophy>


You have completed the hands-on for the application development using Cloud Run!!


If you don’t need the materials used in the demo, clean them up with the following steps.


## Cleanup（Deleting the project）


If you delete the created resources individually, skip the steps below and go to the next page.


### Deleting the project


```bash
gcloud projects delete {{project-id}}
```


## Cleanup（Deleting individual resources）


### Deleting Cloud Run 


```bash
gcloud run services delete egg1-app --platform managed --region=us-central1
```


### Deleting Firestore data


Delete the root collection from Firestore console. Every user data you created in this hands-on will be deleted.


### Deleting Cloud Memorystore


```bash
gcloud redis instances delete eggcache --region=us-central1
```


### Deleting Serverless VPC Access connector


```bash
gcloud compute networks vpc-access connectors delete egg-vpc-connector --region us-central1
```




### Deleting VPC


```bash
gcloud compute networks subnets delete us-subnet --region=us-central1
```


```bash
gcloud compute networks delete eggvpc
```


### Deleting container images registered to Container Registry


Select images from Container Registry console and delete them.


### Deleting repository created in Cloud Source Repositories 


Access [CSR setting screen ](https://source.cloud.google.com/admin/settings?projectId={{project-id}}&repository=egg1-handson) and execute `Delete this repository`.


### Deleting dev-key.json with owner permission


```bash
rm ~/cloudshell_open/egg-training-materials/egg3-3/dev-key.json
```


### Revoking the role granted to the service account


```bash
gcloud projects remove-iam-policy-binding {{project-id}} --member "serviceAccount:dev-egg-sa@{{project-id}}.iam.gserviceaccount.com" --role "roles/owner"
```


### Deleting the service account


```bash
gcloud iam service-accounts delete dev-egg-sa@{{project-id}}.iam.gserviceaccount.com
```