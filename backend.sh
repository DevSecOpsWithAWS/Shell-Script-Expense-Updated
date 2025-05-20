#!/bin/bash


USER_ID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

CHECK_ROOT(){
  if [ $USER_ID -ne 0 ]
  then
    echo "Error:: You must have root privileges to run this script" 
    exit 1
  else
    echo "You have root privileges"
  fi
}
CHECK_ROOT

LOGS_FOLDER="/var/logs/expense-logs"
mkdir -p $LOGS_FOLDER
LOG_FILE=$( echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log"
echo "Script Execution started at $TIMESTAMP"

VALIDATE(){
  if [ $1 -ne 0 ]
  then 
    echo -e "$2...$R Failure $N"
    exit 1
  else
    echo -e "$2...$G Success $N"
  fi
}

dnf module disable nodejs -y
VALIDATE $? "Disable NodeJS module"


dnf module enable nodejs:20 -y
VALIDATE $? "Enable NodeJS module"


dnf install nodejs -y
VALIDATE $? "NodeJS installation"

useradd expense
VALIDATE $? "User creation"

mkdir -p /app
VALIDATE $? "Create application directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip
VALIDATE $? "Download backend zip file"

cd /app
VALIDATE $? "Change directory to /app"

unzip /tmp/backend.zip
VALIDATE $? "Unzip backend zip file"

npm install
VALIDATE $? "Install NodeJS dependencies"

mv /home/ec2-user/Shell-Script-Expense-Updated/backend.service /etc/systemd/system/backend.service
VALIDATE $? "Move backend service file"

systemctl daemon-reload
VALIDATE $? "Reload systemd daemon"

systemctl start backend
VALIDATE $? "Start backend service"

systemctl enable backend
VALIDATE $? "Enable backend service"


dnf install mysql -y
VALIDATE $? "MySQL installation"


mysql -h database.sridevsecops.store -uroot -pExpenseApp@1 < /app/schema/backend.sql
VALIDATE $? "Import backend schema"

systemctl restart backend
VALIDATE $? "Restart backend service"