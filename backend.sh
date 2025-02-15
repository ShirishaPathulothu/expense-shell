#!/bin/bash

LOGS_FOLDER="/var/log/expense"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME-$TIMESTAMP.log"
mkdir -p $LOGS_FOLDER

Userid=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

CHECK_ROOT(){
    if [ $Userid -ne 0 ]
    then
       echo -e "$R please run this script with root previleges $N" | tee -a $LOG_FILE
       exit 1
    fi   
}

VALIDATE(){
    if [ $1 -ne 0 ]
    then
       echo -e "$2 is... $R Failed $N" | tee -a $LOG_FILE
       exit 1
    else
       echo -e "$2 is... $G Success $N" | tee -a $LOG_FILE
    fi      
}

echo "Script started executed at: $(date)" | tee -a $LOG_FILE

CHECK_ROOT

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disable default nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enable Nodejs:20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing Nodejs"

id expense &>>$LOG_FILE
if [ $? -ne 0 ]
then
   echo -e "expense user is not exists.. $G Creating $N"
   useradd expense &>>$LOG_FILE
   VALIDATE $? "Creating expense user"
else
   echo -e "expense user already exists.. $Y SKIPPING $N"
fi 

mkdir -p /app
VALIDATE $? "Creating /app folder"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE
VALIDATE $? "Downloading backend application code"

cd /app
rm -rf /app/* #remove the existing code
unzip /tmp/backend.zip &>>$LOG_FILE
VALIDATE $? "Extracting backend application code"

npm install &>>$LOG_FILE
cp /home/ec2-user/expense-shell/backend.service  /etc/systemd/system/backend.service

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Installing mysql"

mysql -h mysql.dev12.shop -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE
VALIDATE $? "Schema Loading"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Daemon reload"

systemctl enable backend &>>$LOG_FILE
VALIDATE $? "Enabled backend"

systemctl restart backend &>>$LOG_FILE
VALIDATE $? "Restart backend" 





