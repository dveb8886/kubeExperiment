# syntax=docker/dockerfile:1

FROM --platform=linux/amd64 python:3.8-slim-buster

WORKDIR /app

COPY requirements.txt requirements.txt
RUN pip3 install -r requirements.txt

COPY . .

CMD [ "gunicorn",  "--workers=1",  "--chdir=.",  "--bind",  "0.0.0.0:8080",  "main:app" ]