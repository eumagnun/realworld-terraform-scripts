#Database variables
VAR_DATABASE_NAME=$1
VAR_DATABASE_USER=$2
VAR_DATABASE_PASSWORD=$3

if [ "$1" = "" ] || [ "$2" = "" ] || [ "$3" = "" ];then
  echo "Please input DATABASE_NAME DATABASE_USER DATABASE_PASSWORD"
  exit 0
fi

echo "::::::::installing JRE"
gcloud compute ssh backend-vm --zone=southamerica-east1-a --internal-ip --command "sudo apt install default-jre -y"

echo "::::::::removing projects dir"
sudo rm -R realworld-springboot-java

echo "::::::::cloning project"
git clone https://github.com/eumagnun/realworld-springboot-java.git

echo "::::::::changing current dir"
cd realworld-springboot-java

echo ":::::::: getting database internal ip"
VAR_DATABASE_IP=$(gcloud compute instances describe database-vm --zone='southamerica-east1-a'  --format='get(networkInterfaces[0].networkIP)')

echo ":::::::: getting frontend public ip"
VAR_FRONTEND_IP=$(gcloud compute instances describe frontend-vm --zone='southamerica-east1-a'  --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

echo ":::::::: replacing variables"
sed -i "s|REPLACE_FRONTEND_IP|"${VAR_FRONTEND_IP}"|g" src/main/resources/application.properties

sed -i "s|REPLACE_DATABASE_IP|"${VAR_DATABASE_IP}"|g" src/main/resources/application.properties

sed -i "s|REPLACE_DATABASE_NAME|"${VAR_DATABASE_NAME}"|g" src/main/resources/application.properties

sed -i "s|REPLACE_DATABASE_USER|"${VAR_DATABASE_USER}"|g" src/main/resources/application.properties

sed -i "s|REPLACE_DATABASE_PASSWORD|"${VAR_DATABASE_PASSWORD}"|g" src/main/resources/application.properties

echo "::::::::building project"
./gradlew build -x test

echo "::::::::creating remote dir"
gcloud compute ssh backend-vm --zone=southamerica-east1-a --internal-ip --command "sudo mkdir /home/backend-app ; sudo chmod 777 /home/backend-app"

echo "::::::::copying builded files to remote server"
gcloud compute scp build/libs/realworld-spring-boot-java-2.1.1.jar backend-vm:/home/backend-app/backend.jar --internal-ip --zone=southamerica-east1-a

echo "::::::::killing old version and starting new"
FILE_NAME=$(date "+%Y%m%d")
gcloud compute ssh backend-vm --zone=southamerica-east1-a --internal-ip --command "pkill -9 java ; nohup java -jar /home/backend-app/backend.jar > ./backend_'${FILE_NAME}'.out 2>backend_'${FILE_NAME}'.err &"

echo "::::::::getting info from new release execution"
gcloud compute ssh backend-vm --zone=southamerica-east1-a --internal-ip --command "ps -fC java"

echo "::::::::deploy finished"
