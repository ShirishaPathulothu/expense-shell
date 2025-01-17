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
       echo -e "$R Please run this script with root previleges $N" | tee -a &>>$LOG_FILE
       exit 1
    fi     
}

VALIDATE(){
    if [ $1 -ne 0 ]
    then
       echo -e "$2 is... $R Failed $N" | tee -a &>>$LOG_FILE
       exit 1
    else
       echo -e "$2 is... $G Success $N" | tee -a &>>$LOG_FILE
    fi      
}

echo "Script started execute at: $(date)" | tee -a &>>$LOG_FILE

CHECK_ROOT

dnf install mysql-server -y &>>$LOG_FILE
VALIDATE $? "Installing mysql server"

systemctl enable mysqld &>>$LOG_FILE
VALIDATE $? "Enabled MySQL Server"

systemctl start mysqld &>>$LOG_FILE
VALIDATE $? "Started MySQL server"

mysql -h mysql.dev12.shop -u root -pExpenseApp@1 -e 'show databases'; &>>$LOG_FILE
if [ $? -ne 0 ]
then
   echo "MySql root password is not set Up..going to set Up" &>>$LOG_FILE
   mysql_secure_installation --set-root-pass ExpenseApp@1
   VALIDATE $? "Setting up root password"
else
   echo -e "MySql root password already set Up..$Y SKIPPING $N" | tee -a $LOG_FILE
fi 