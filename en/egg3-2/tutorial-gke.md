# EGG hands-on(Google Kubernetes Engine) #3-2


## Selecting Google Cloud project


Make a Google Cloud project that you do the hands-on, select Google Cloud project, and Click **Start**.


**Make a project as new as possible.**


<walkthrough-project-setup>
</walkthrough-project-setup>


## [Explanation] Overview of hands-on


### **Overview and Objective**


In this hands-on, which is intended for people with no prior experience of Google Kubernetes Engine, we start from creating Kubernetes cluster, and Build/Deploy/Access container are covered among others.


Also, using a web application that accesses Cloud Spanner as the subject, we try to access Cloud Spanner without Service Account key using Workload Identity.


Throughout this hands-on, our objective is for you to get an image of the first step in application development using Google Kubernetes Engine.


The following figure shows the system configuration (final configuration) of the hands-on.


![](https://storage.googleapis.com/egg-resources/egg3-2/public/gke/0-1.png)


## [Exercise] 1. Enabling Google API and creating Kubernetes cluster


Cloud Shell and Editor might be currently opened. If [Google Cloud console](https://console.cloud.google.com/) is not opened, please open the console screen.


### **Enabling API**


Enable Google API that you use in the hands-on with the following command.


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


### **Creating Kubernetes cluster**


Once the API is enabled, create a Kubernetes cluster.
Run the following command.


```bash
gcloud container --project "$GOOGLE_CLOUD_PROJECT" clusters create "cluster-1" \
  --zone "asia-northeast1-a" \
  --enable-autoupgrade \
  --username "admin" \
  --image-type "COS" \
  --enable-ip-alias \
  --workload-pool=$GOOGLE_CLOUD_PROJECT.svc.id.goog
```


It takes a few minutes to create a Kubernetes cluster.


Once a Kubernetes cluster is created, you can confirm it from [Admin Console] - [Kubernetes Engine] - [Cluster]. 


![](https://storage.googleapis.com/egg-resources/egg3-2/public/gke/1-1.png)


By creating a Kubernetes cluster, the current system configuration looks like this.


![](https://storage.googleapis.com/egg-resources/egg3-2/public/gke/1-2.png)


### **Command setting**


Execute the following command to set up the command execution environment.


```bash
gcloud config set project {{project-id}}
gcloud config set compute/zone asia-northeast1-a
gcloud config set container/cluster cluster-1
gcloud container clusters get-credentials cluster-1
```


By the following command from the commands above, bring the credential information required to operate Kubernetes cluster to local (Cloud Shell).


```
gcloud container clusters get-credentials cluster-1
```


Execute the following command to test connectivity with Kubernetes cluster and check the version.


```bash
kubectl version
```


If you get the following result, you are connecting with Kubernetes Cluster (Version is output for each Client and Server).


```
Client Version: version.Info{Major:"1", Minor:"21", GitVersion:"v1.21.0", GitCommit:"cb303e613a121a29364f75cc67d3d580833a7479", GitTreeState:"clean", BuildDate:"2021-04-08T16:31:21Z", GoVersion:"go1.16.1", Compiler:"gc", Platform:"linux/amd64"}
Server Version: version.Info{Major:"1", Minor:"18+", GitVersion:"v1.18.16-gke.2100", GitCommit:"36d0b0a39224fef7a40df3d2bc61dfd96c8c7f6a", GitTreeState:"clean", BuildDate:"2021-03-16T09:15:29Z", GoVersion:"go1.13.15b4", Compiler:"gc", Platform:"linux/amd64"}
```


By setting up the commands, the current system configuration looks like this.


![](https://storage.googleapis.com/egg-resources/egg3-2/public/gke/1-3.png)


## [Exercise] 2. Creating Docker container image


### **Building Docker container image**


When you create a Docker container image, prepare a Dockerfile.
Dockerfile is stored in the spanner directory.
Content of the file is the following command, which you can check by Cloud Shell Editor.


```bash
cloudshell edit spanner/Dockerfile
```


Go back to the terminal and start the build of Docker container image with the following command.


```bash
docker build -t asia.gcr.io/${GOOGLE_CLOUD_PROJECT}/spanner-app:v1 ./spanner
```


![](https://storage.googleapis.com/egg-resources/egg3-2/public/gke/2-1.png)


It takes a few minutes to build a Docker container image.


You can check the comment image on local (Cloud Shell) with the following command.


```bash
docker image ls
```


Container image should be output as below.


```
REPOSITORY                                       TAG  IMAGE ID       CREATED         SIZE
asia.gcr.io/<GOOGLE_CLOUD_PROJECT>/spanner-app   v1   8952a9a242f5   5 minutes ago   23.2MB
```


### **Pushing Docker container image**


Once the build of the container image is done, upload the built image on Google Container Registry.


Set up with the following command to use credentials of `gcloud` when you `docker push`. 


```bash
gcloud auth configure-docker
```


Push to Google Container Registry with the following command.
(It takes some time if it’s the first time)


```bash
docker push asia.gcr.io/${GOOGLE_CLOUD_PROJECT}/spanner-app:v1
```


You can confirm it is Pushed to Google Container Registry with the following command.


```bash
gcloud container images list-tags asia.gcr.io/${GOOGLE_CLOUD_PROJECT}/spanner-app
```


You can also confirm it from Admin Console > [Tools] > [Container Registry] 


![](https://storage.googleapis.com/egg-resources/egg3-2/public/gke/2-2.png)


By adding container images to Google Container Registry, the current system configuration looks like this.


![](https://storage.googleapis.com/egg-resources/egg3-2/public/gke/2-3.png)


## [Exercise] 3. Setting up Workload Identity


### **Confirming Workload Identity enabled**


Confirm Workload Identity is enabled in the GKE cluster.
Execute the following command.


```bash
gcloud container clusters describe cluster-1 \
  --format="value(workloadIdentityConfig.workloadPool)" --zone asia-northeast1-a
```


If it displays `<GOOGLE_CLOUD_PROJECT>.svc.id.goog`, it is set up correctly.


Also, other than the cluster, confirm Workload Identity enabled in NodePool.
Execute the following command.


```bash
gcloud container node-pools describe default-pool --cluster=cluster-1 \
  --format="value(config.workloadMetadataConfig.mode)" --zone asia-northeast1-a
```


If it displays `GKE_METADATA`, it is set up correctly.


### **Creating Service Account**


Create Service Accounts that use Workload Identity.
We create Kubernetes Service Account(KSA) and Google Service Account(GSA) here.
Create Kubernetes Service Account (KSA) on the Kubernetes cluster with the following command.


```bash
kubectl create serviceaccount spanner-app
```


Create Google Service Account (GSA) with the following command.


```bash
gcloud iam service-accounts create spanner-app
```


The Spanner App we use here is a web application that accesses Cloud Spanner.
`roles/spanner.databaseUser` permission is required to operate (add/update/delete etc.) on the data in Cloud Spanner Database.
Get the permission for the Service Account to operate on the data in Cloud Spanner Database with the following command.


```bash
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
  --role "roles/spanner.databaseUser" \
  --member serviceAccount:spanner-app@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com
```


At this point, we will only create KSA and GSA as separate ones. Next step is the linking of KSA and GSA.


### **Linking of Service Account**


For the Kubernetes Service Account to borrow permission from the Google Service Account, we will link them in this step.
Execute the following command to do the linking.


```bash
gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:$GOOGLE_CLOUD_PROJECT.svc.id.goog[default/spanner-app]" \
  spanner-app@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com
```


Add the Google Service Account information to the Kubernetes Service Account annotation with the following command.


```bash
kubectl annotate serviceaccount spanner-app \
  iam.gke.io/gcp-service-account=spanner-app@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com
```


## [Exercise] 4. Creating Kubernetes Deployment


We will create resources that will be run on Kubernetes cluster


### **Editing the Manifest file of Deployment** 


Manifest file is stored in k8s directory.
You can check the contents of the file in the Cloud Shell Editor with the following command.


```bash
cloudshell edit k8s/spanner-app-deployment.yaml
```


**Updating the  project id in the file to your {{project-id}} **


![](https://storage.googleapis.com/egg-resources/egg3-2/public/gke/3-1.png)




### **Creating Deployment**


Create Deployment on the Kubernetes cluster with the following command.


```bash
kubectl apply -f k8s/spanner-app-deployment.yaml
```


Check the created Deployment and Pod with the following command.


```bash
kubectl get deployments
```


```bash
kubectl get pods -o wide
```


By creating Deployment, the current system configuration looks like this.


![](https://storage.googleapis.com/egg-resources/egg3-2/public/gke/4-1.png)


**Appendix) kubectl command reference Part 1**


 * To check the Pod in a list
```bash
kubectl get pods
```


 * To know the Pod IP address or execution Node
```bash
kubectl get pods -o wide
```


 * To check the details of the Pod
```bash
kubectl describe pods <pod name>
```


 * To get the definition of Pod by YAML
```bash
kubectl get pods <pod name> -o yaml
```




## [Exercise] 5. Creating Kubernetes Service (Discovery) 


### **Creating Service**


Manifest file is stored in k8s directory.
You can check the contents of the file in the Cloud Shell Editor with the following command.


```bash
cloudshell edit k8s/spanner-app-service.yaml
```


Create Service on Kubernetes cluster with the following command.


```bash
kubectl apply -f k8s/spanner-app-service.yaml
```


Check the created Service with the following command.


```bash
kubectl get svc
```


Due to the creation of network load balancer (TCP), it takes a few minutes for an external IP address (EXTERNAL-IP) to be assigned.
With the following command, you will always watch updates with the -w flag (Ctrl + C to stop).


```bash
kubectl get svc -w
```




**Appendix) kubectl command reference Part 2**


 * To check Service in a list
```bash
kubectl get services
```


 * To know the Pod (IP) when a Service is routing communication
```bash
# endpoints resources are auto-managed by Service resources
kubectl get endpoints
```


 * To see the details of Service
```bash
kubectl describe svc <service name>
```


 * To get the definition of Service by YAML
```bash
kubectl get svc <service name> -o yaml
```


### **Accessing the Service**


When you create a Service of `Type: LoadBalancer`, a network load balancer will be issued.


You can check it from [Admin Console] - [Networking] - [Network Service] - [Load Distribution] 


![](https://storage.googleapis.com/egg-resources/egg3-2/public/gke/5-1.png)


Let’s actually access it by specifying the external IP address of the load balancer.
Check the external IP address of the Service with the following command.


```bash
kubectl get svc
```


Among the following output, `EXTERNAL-IP` is the external IP address.
It differs in each environment, so read it according to your environment.


```
NAME         TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)          AGE
spanner-app  LoadBalancer   10.0.12.198   203.0.113.245  8080:30189/TCP   58s
kubernetes   ClusterIP      10.56.0.1     <none>         443/TCP          47m
```


Get the Players information with the following curl command to access.
As for the <EXTERNAL IP> part, replace it with the IP address checked above.


```bash
curl <EXTERNAL IP>:8080/players
```


If you can access it by the curl command, Service resources and Deployment (and Pod) is working correctly.


Also, by using Workload Identity, it is confirmed that you can access Cloud Spanner without Service Account key.


![](https://storage.googleapis.com/egg-resources/egg3-2/public/gke/5-2.png)


### **Operating Spanner App**


 * Adding New Player(playerId is automatically assigned after this)
```bash
curl -X POST -d '{"name": "testPlayer1", "level": 1, "money": 100}' <EXTERNAL IP>:8080/players
```


If you see the error message **`invalid character '\\' looking for beginning of value`**, delete the backslash (\\) and execute it without line break when you execute curl command.


 * Get the list of Player
```bash
curl <EXTERNAL IP>:8080/players
```


 * Update Player (Change the playerId as appropriate)
```bash
curl -X PUT -d '{"playerId":"afceaaab-54b3-4546-baba-319fc7b2b5b0","name": "testPlayer1", "level": 2, "money": 200}' <EXTERNAL IP>:8080/players
```


 * Delete Player (Change the playerId as appropriate)
```bash
curl -X DELETE http://<EXTERNAL IP>:8080/players/afceaaab-54b3-4546-baba-319fc7b2b5b0
```


**Appendix) Troubleshooting using kubectl**


If you have problems with the resources on Kubernetes, check it with `kubectl describe` command.
When you create/update/delete resources in Kubernetes, it will issue `Event` resource. 
You can check an `Event` within one hour with `kubectl describe` command.


```bash
kubectl describe <resource name> <object name>
# Example
kubectl describe deployments hello-node
```


Also, you can check the application log to see if there are any errors in the application..
Use `kubectl logs` command to check the application log.


```bash
kubectl logs -f <pod name>
```


## [Exercise] 6. Cleanup


After all the exercises are finished, delete the resources.


 1. Delete the load balancer. Disk and LB should be deleted first. Otherwise, they will keep remaining even if you delete the Kubernetes cluster as a whole.
```bash
kubectl delete svc spanner-app
```


 2. Delete the docker image storeid in Container Registry.
```bash
gcloud container images delete asia.gcr.io/$PROJECT_ID/spanner-app:v1 --quiet
```


 3. Delete the Kubernetes cluster.
```bash
gcloud container clusters delete "cluster-1" --zone "asia-northeast1-a"
```


Type `y` for the question `Do you want to continue (Y/n)?`


 4. Delete the Google Service Account.
```bash
gcloud iam service-accounts delete spanner-app@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com
```


Type `y` for the question `Do you want to continue (Y/n)?`


 5. Delete the Cloud Spanner Instance.
```bash
gcloud spanner instances delete dev-instance
```


Type `y` for the question `Do you want to continue (Y/n)?`


## **Thank You!**


That’s it for the Google Kubernetes Engine hands-on.