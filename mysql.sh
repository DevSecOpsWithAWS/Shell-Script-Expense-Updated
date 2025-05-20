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


dnf install mysql-server -y &>>$LOG_FILE_NAME
VALIDATE $? "MySQL installation"

systemctl enable mysqld &>>$LOG_FILE_NAME
VALIDATE $? "Enabling MySQL service"

systemctl start mysqld &>>$LOG_FILE_NAME
VALIDATE $? "Starting MySQL service"

mysql -h database.sridevsecops.store -u root -pExpenseApp@1 -e 'show databases;' &>>$LOG_FILE_NAME

if [ $? -ne 0 ]
then
  echo "MySQL Root password is not set up" &>>$LOG_FILE_NAME
  mysql_secure_installation --set-root-pass ExpenseApp@1
  VALIDATE $? "MySQL Root password setup"
else
  echo -e "$Y MySQL Root password is already set $N"
fi
mysql_secure_installation --set-root-pass ExpenseApp@1


