## Main Goal
* Create a simulated onpremises 3 layer application to use as base to modernization simulations


## 1 On-premises env creation step-by-step

### 1.1 Create google cloud resources with terraform
* Create the infra with terraform scripts (folder: on-prem-env)
* Warning: if you receive the error  "Error 412: Constraint constraints/compute.vmExternalIpAccess violated for project", change the organization policy "vmExternalIpAccess" to "Google-managed default"


* clone this repo
````
git clone https://github.com/eumagnun/realworld-terraform-scripts.git
````

* change the current directory
````
cd realworld-terraform-scripts/on-prem-env
````

* init terraform
````
terraform init
````

* apply script
````
terraform apply
````

## Environment diagram:
![alt text](https://raw.githubusercontent.com/eumagnun/realworld-terraform-scripts/main/on-prem-env.png)


### 1.2 - Install de Datatabase on database-vm:

* Currently the postgres database deployment is taking place during the terraform scripts execution.

* Some examples of commands do validate the database
* #list databases
```
\l
```
* connect to a database
````
\c postgres
````

* list tables
````
select * from information_schema.tables

````

* list articles
````
select * from articles

````

### 1.3 - Do the setup on build-vm
* create a service account with role "instanceAdmin" and associate it to build-vm
* install git on build-vm
````
sudo apt install git
````
* clone this repo on build-vm 
* execute the script mount_backend_build_env.sh
* execute the script mount_frontend_build_env.sh

### 1.4 - Deploy the application through build-vm
* execute the script build-backend.sh
* execute the script build-frontend.sh

## 2 Cloud env creation
### 2.1 Create a peering configuration on your cloud-project
* Create the infra with terraform  scripts (folder: cloud-env)
````
https://github.com/eumagnun/realworld-terraform-scripts
````
## 3 Let's go to the migration
### 3.1 Estabilish communication beetween both projects.
* Warning:  To execute this step on the real world we can use a VPN or Interconnect. In this demo, to keep things simple,  we are going to establish a peering.
* 
* On cloud project execute (on peer-project attribute use your PROJECT-ID)
````
gcloud compute networks peerings create demo-env-cloud-peering \
    --network=mynetwork1 \
    --peer-project civic-replica-369511 \
    --peer-network mynetwork 
````

* On on-prem project execute (on peer-project attribute use your PROJECT-ID)
````
gcloud compute networks peerings create demo-env-on-prem-peering \
    --network=mynetwork \
    --peer-project nodal-shift-369517 \
    --peer-network mynetwork1 
````

### 3.2 Create a firewall rule on on-prem project to enable the communication
````
name fw-peering-migration
target: all instances in the network
source ipv4 ranges: 10.2.0.0/24
protocols and ports: allow all
````
### 3.3 Access Migrate to Virtual Machines page in the Google Cloud console
* https://console.cloud.google.com/compute/mfce



## Utils:
* Working with private github repos: https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent#generating-a-new-ssh-key)

* Installing Postgres: https://www.digitalocean.com/community/tutorials/how-to-install-postgresql-on-ubuntu-20-04-quickstart

* Default Postgres port:5432

* If necessary remove Postgresql: https://kb.objectrocket.com/postgresql/how-to-completely-uninstall-postgresql-757

* List Unix users: less /etc/passwd

* Run process on background: https://udgwebdev.github.io/dicas-de-terminal-processos-em-background/

* Run the backend porject on IntelliJ: Press Ctrl, Ctrl and gradle bootRun

