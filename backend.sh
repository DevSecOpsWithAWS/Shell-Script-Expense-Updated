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

dnf module disable nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Disable NodeJS module"


dnf module enable nodejs:20 -y &>>$LOG_FILE_NAME
VALIDATE $? "Enable NodeJS module"


dnf install nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "NodeJS installation"

id expense &>>$LOG_FILE_NAME

if [ $? -ne 0 ]
then
  useradd expense &>>$LOG_FILE_NAME
  VALIDATE $? "User creation"
else
  echo "User expense Already exist"
fi


mkdir -p /app &>>$LOG_FILE_NAME
VALIDATE $? "Create application directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE_NAME
VALIDATE $? "Download backend zip file"

cd /app &>>$LOG_FILE_NAME
VALIDATE $? "Change directory to /app"

rm -rf /app/* &>>$LOG_FILE_NAME
VALIDATE $? "Remove temp files"

unzip /tmp/backend.zip &>>$LOG_FILE_NAME
VALIDATE $? "Unzip backend zip file"

npm install &>>$LOG_FILE_NAME
VALIDATE $? "Install NodeJS dependencies"

cp /home/ec2-user/Shell-Script-Expense-Updated/backend.service /etc/systemd/system/backend.service &>>$LOG_FILE_NAME
VALIDATE $? "Coping backend service file"

systemctl daemon-reload &>>$LOG_FILE_NAME
VALIDATE $? "Reload systemd daemon"

systemctl start backend &>>$LOG_FILE_NAME
VALIDATE $? "Start backend service"

systemctl enable backend &>>$LOG_FILE_NAME
VALIDATE $? "Enable backend service"


dnf install mysql -y &>>$LOG_FILE_NAME
VALIDATE $? "MySQL installation"


mysql -h database.sridevsecops.store -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE_NAME
VALIDATE $? "Import backend schema"

systemctl restart backend &>>$LOG_FILE_NAME
VALIDATE $? "Restart backend service"