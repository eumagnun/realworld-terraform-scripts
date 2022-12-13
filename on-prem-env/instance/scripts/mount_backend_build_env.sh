echo "Creation of Backend Build Env: Start"

echo "install software"
apt install default-jdk -y

apt install wget -y

apt install unzip -y

apt install git -y

echo "download graddle"
rm /tmp/gradle-7.4.2-bin.zip
wget https://services.gradle.org/distributions/gradle-7.4.2-bin.zip -P /tmp

echo "unzip"
rm -r /opt/gradle 
unzip -d /opt/gradle /tmp/gradle-7.4.2-bin.zip

echo "create file"
printf 'export GRADLE_HOME=/opt/gradle/gradle-7.4.2\nexport PATH=${GRADLE_HOME}/bin:${PATH}\n' > gradle.sh

echo "mv"
mv gradle.sh /etc/profile.d/gradle.sh

echo "chmod"
sudo chmod +x /etc/profile.d/gradle.sh

echo "source"
. /etc/profile.d/gradle.sh


gradle --version

echo "Creation of backend Build Env: Finished"


