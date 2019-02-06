FROM python:3.6

RUN apt-get update -y
RUN apt-get install mysql-server -y
