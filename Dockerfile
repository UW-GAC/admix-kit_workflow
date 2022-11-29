FROM python:3.9-bullseye

USER root

RUN apt-get update && apt-get install -y git

ENV PIP_USER=false

# dependencies of admix-kit
RUN pip install cmake numpy Cython pyreadr

# admix-kit
RUN git clone https://github.com/KangchengHou/admix-kit && \
    cd admix-kit && pip install -e . && cd $HOME

# PLINK2
RUN mkdir -p /tmp/plink2 && \
    cd /tmp/plink2 && \
    curl -L -o plink2.zip "https://s3.amazonaws.com/plink2-assets/alpha3/plink2_linux_x86_64_20220519.zip" && \
    unzip plink2.zip && \
    mv plink2 /bin/plink2 && \
    cd $HOME && \
    rm -rf /tmp/plink2

# PLINK1
ENV PLINK_VERSION 20220402
RUN mkdir -p /tmp/plink && \
    cd /tmp/plink && \
    curl -L -o plink.zip "http://s3.amazonaws.com/plink1-assets/plink_linux_x86_64_${PLINK_VERSION}.zip" && \
    unzip plink.zip && \
    mv plink /bin/plink && \
    cd $HOME && \
    rm -rf /tmp/plink

# GCTA
ENV GCTA_VERSION=v1.94.0Beta
RUN mkdir -p /tmp/gcta && \
    cd /tmp/gcta && \
    curl -L -o gcta.zip "https://yanglab.westlake.edu.cn/software/gcta/bin/gcta_${GCTA_VERSION}_linux_kernel_4_x86_64.zip" && \
    unzip gcta.zip && \
    mv "gcta_${GCTA_VERSION}_linux_kernel_4_x86_64/gcta_${GCTA_VERSION}_linux_kernel_4_x86_64_static" /bin/gcta64 && \
    cd $HOME && \
    rm -rf /tmp/gcta

USER $USER
