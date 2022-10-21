FROM python:3.9-bullseye

RUN apt-get update && apt-get install -y \
    git

RUN git clone https://github.com/KangchengHou/admix-kit && \
    cd admix-kit && pip install -e .
