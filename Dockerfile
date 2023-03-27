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

# liftOver
RUN mkdir -p /tmp/liftover && \
    cd /tmp/liftover && \
    curl -L -o liftOver "http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/liftOver" && \
    chmod +x liftOver && \
    mv liftOver /bin/liftOver && \
    cd $HOME && \
    rm -rf /tmp/liftover

# HAPGEN2
RUN mkdir -p /tmp/hapgen2 && \
    cd /tmp/hapgen2 && \
    curl -L -o hapgen2.tar.gz "http://mathgen.stats.ox.ac.uk/genetics_software/hapgen/download/builds/x86_64/v2.2.0/hapgen2_x86_64.tar.gz" && \
    tar -xvf hapgen2.tar.gz && \
    mv hapgen2 /bin/hapgen2  && \
    cd $HOME && \
    rm -rf /tmp/hapgen2

# admix-simu
RUN mkdir -p /tmp/admix && \
    cd /tmp/admix && \
    curl -L -o master.zip "https://github.com/williamslab/admix-simu/archive/refs/heads/master.zip" && \
    unzip master.zip -d dir && \
    cd dir/admix-simu-master && make && \
    cd /tmp/admix && mv dir/admix-simu-master/ /bin/ && \
    cd $HOME && \
    rm -rf /tmp/admix

# genetic map
RUN mkdir -p /admix-kit/.admix_cache/data/genetic_map && \
    cd /admix-kit/.admix_cache/data/genetic_map && \
    curl -L -o genetic_map_hg38_withX.txt.gz "https://storage.googleapis.com/broad-alkesgroup-public/Eagle/downloads/tables/genetic_map_hg38_withX.txt.gz" && \
    curl -L -o genetic_map_hg19_withX.txt.gz "https://storage.googleapis.com/broad-alkesgroup-public/Eagle/downloads/tables/genetic_map_hg19_withX.txt.gz"

# HapMap3 SNPs
RUN mkdir -p /admix-kit/.admix_cache/data/hapmap3_snps && \
    cd /admix-kit/.admix_cache/data/hapmap3_snps && \
    curl -L -o hapmap3_snps.rds "https://ndownloader.figshare.com/files/25503788"

USER $USER
