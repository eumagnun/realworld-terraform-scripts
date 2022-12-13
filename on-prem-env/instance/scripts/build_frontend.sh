echo ":::::::: installing nginx"
gcloud compute ssh frontend-vm --zone=southamerica-east1-a --internal-ip --command "sudo apt install nginx -y"

echo ":::::::: removing old repository"
rm -R angular-realworld-example-app

echo ":::::::: clonning repository"
git clone https://github.com/eumagnun/angular-realworld-example-app.git

echo ":::::::: changing current directory"
cd angular-realworld-example-app

echo ":::::::: installing project dependencies"
yarn install

echo ":::::::: getting backend public ip"
IP_BACKEND=$(gcloud compute instances describe backend-vm --zone='southamerica-east1-a'  --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

echo ":::::::: replacing backend ip"
sed -i "s|BACKEND_API_ENDPOINT_AND_PORT|"${IP_BACKEND}":8080|g" src/environments/environment.prod.ts

cat src/environments/environment.prod.ts

echo ":::::::: build frontend"
sudo ng build --configuration production

echo ":::::::: removing current frontend"
gcloud compute ssh frontend-vm --zone=southamerica-east1-a --internal-ip --command "sudo rm -r /var/www/html/ ; sudo mkdir /var/www/html/ ; sudo chmod 777 /var/www/html"


echo ":::::::: transferring builded frontend"
gcloud compute scp --recurse dist/* frontend-vm:/var/www/html/ --internal-ip --zone=southamerica-east1-a

echo ":::::::: restarting ngynx"
gcloud compute ssh frontend-vm --zone=southamerica-east1-a --internal-ip --command "sudo systemctl status nginx"


