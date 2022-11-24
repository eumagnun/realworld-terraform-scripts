# terraform-scripts

* Warning: if you receive the error  "Error 412: Constraint constraints/compute.vmExternalIpAccess violated for project", change the organization policy "vmExternalIpAccess" to "Google-managed default"


* clone this repo
````
git clone https://github.com/eumagnun/realworld-terraform-scripts.git
````

* change dir to the desired env [cloud-env or on-prem-env]
````
cd realworld-terraform-scripts/DESIRED_FOLDER
````

* init terraform
````
terraform init
````

* apply script
````
terraform apply
````

** Environment diagram:
![alt text](https://raw.githubusercontent.com/eumagnun/realworld-terraform-scripts/main/on-prem-env.png)
