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

dnf install nginx -y 
VALIDATE $? "Nginx installation"


systemctl enable nginx
VALIDATE $? "Enabling Nginx service"

systemctl start nginx
VALIDATE $? "Starting Nginx service"

rm -rf /usr/share/nginx/html/*
VALIDATE $? "Removing default Nginx content"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip
VALIDATE $? "Downloading frontend zip file"

cd /usr/share/nginx/html
VALIDATE $? "Changing directory to Nginx html folder"

rm -rf /usr/share/nginx/html/*
VALIDATE $? "Removing existing Nginx content"

unzip /tmp/frontend.zip
VALIDATE $? "Unzipping frontend zip file"

cp /home/ec2-user/Shell-Script-Expense-Updated/expense.conf /etc/nginx/default.d/expense.conf
VALIDATE $? "Copying Nginx configuration file"

systemctl restart nginx
VALIDATE $? "Restarting Nginx service"