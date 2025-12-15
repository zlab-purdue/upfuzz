# Source code repository for the upfuzz project

## Overview

This repository contains the source code and artifact materials for **UpFuzz**, a framework for discovering data-format and upgrade bugs in distributed storage systems.



## Experiment data

To evaluate UpFuzz, we conducted a large number of experiments, totaling > five months of a single machine time (We paralleled experiments with more servers). In accordance with the artifact evaluation (AE) guidelines, we do not expect reviewers to rerun all experiments from scratch to validate our results.

Instead, we release our **raw experimental data**, allowing reviewers to download the data and run scripts to reproduce all figures and tables reported in the paper.

- The data is hosted on **Google Cloud Storage** (TODO: add link).
- The dataset is publicly accessible to anyone with a Google account.

For experiments that require substantial computational resources, we additionally provide:
- Bug-triggering traces
- Execution logs

These artifacts enable result reproduction without re-running the full-scale experiments.

---
## Requirements

We strongly encourage you to run experiments using cloudlab machines, specifically c220g5. All our experiments were conducted using cloudlab c220g5.

Start up an instance for c220g5, run the following scripts to install all required dependencies.

```bash
# Installation
#!/bin/bash

# sudo fdisk -l
sudo umount /mydata
sudo lvremove -y /dev/emulab/node*
sudo mkfs.ext4 -F /dev/sda4

# SSD
sudo mkdir /mnt_ssd
sudo mount /dev/sda4 /mnt_ssd
sudo chown $USER /mnt_ssd

# HDD
sudo mkfs.ext4 -F /dev/sdb
sudo mount /dev/sdb /mydata
sudo chown $USER /mydata 

mkdir /mydata/project
ln -s /mydata/project ~/project
sudo chown $USER ~/project/

sudo apt-get update
sudo apt-get install openjdk-11-jdk openjdk-8-jdk python2 maven fzf ant htop tmux -y -f

# Set up zsh
echo "Y" | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="daveverwer"/' ~/.zshrc
echo "exec zsh" >> ~/.bashrc

git config --global user.name "Ke Han"
git config --global user.email "kehan5800@gmail.com"
git config --global core.editor "vim"

# docker
sudo apt-get update
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release -y
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y

# Sym link to change docker folder!
sudo usermod -aG docker $USER
# Mount docker image folder to another path (cloudlab only)
sudo systemctl stop docker.service
sudo systemctl stop docker.socket

# If use mydata
# sudo mv /var/lib/docker /mydata/
sudo mv /var/lib/docker /mnt_ssd/
# sudo ln -s /mydata/docker /var/lib/docker
sudo ln -s /mnt_ssd/docker /var/lib/docker

sudo systemctl daemon-reload   
sudo systemctl start docker

sudo mkdir /mydata/test_binary
sudo chown $USER /mydata/test_binary

newgrp docker
# ps aux | grep -i docker | grep -v grep
# sudo systemctl status docker.service
# sudo systemctl status docker.socket
```

## Kick-the-tires Instructions (~30 minutes)

Basic upfuzz: This section demonstrates how to start upgrade testing immediately using branch coverage mode.

#### Cassandra: 3.11.17 => 4.1.4

```bash
git clone git@github.com:zlab-purdue/upfuzz.git
cd upfuzz
export UPFUZZ_DIR=$PWD
export ORI_VERSION=3.11.17
export UP_VERSION=4.1.4

mkdir -p "$UPFUZZ_DIR"/prebuild/cassandra
cd prebuild/cassandra
wget https://archive.apache.org/dist/cassandra/"$ORI_VERSION"/apache-cassandra-"$ORI_VERSION"-bin.tar.gz ; tar -xzvf apache-cassandra-"$ORI_VERSION"-bin.tar.gz
wget https://archive.apache.org/dist/cassandra/"$UP_VERSION"/apache-cassandra-"$UP_VERSION"-bin.tar.gz ; tar -xzvf apache-cassandra-"$UP_VERSION"-bin.tar.gz
sed -i 's/num_tokens: 16/num_tokens: 256/' apache-cassandra-"$UP_VERSION"/conf/cassandra.yaml

cd ${UPFUZZ_DIR}
cp src/main/resources/cqlsh_daemon2.py prebuild/cassandra/apache-cassandra-"$ORI_VERSION"/bin/cqlsh_daemon.py
cp src/main/resources/cqlsh_daemon4.py  prebuild/cassandra/apache-cassandra-"$UP_VERSION"/bin/cqlsh_daemon.py

cd src/main/resources/cassandra/upgrade-testing/compile-src/
sed -i "s/ORI_VERSION=apache-cassandra-.*$/ORI_VERSION=apache-cassandra-$ORI_VERSION/" cassandra-clusternode.sh
sed -i "s/UP_VERSION=apache-cassandra-.*$/UP_VERSION=apache-cassandra-$UP_VERSION/" cassandra-clusternode.sh
docker build . -t upfuzz_cassandra:apache-cassandra-"$ORI_VERSION"_apache-cassandra-"$UP_VERSION"

cd ${UPFUZZ_DIR}
./gradlew copyDependencies
./gradlew :spotlessApply build

# open terminal1: start server
bin/start_server.sh config.json
# open terminal2: start one client
bin/start_clients.sh 1 config.json

# stop testing
bin/clean.sh
```

#### HBase: 3.11.17 => 4.1.4


```bash
git clone git@github.com:zlab-purdue/upfuzz.git
cd upfuzz
export UPFUZZ_DIR=$PWD
export ORI_VERSION=2.4.18
export UP_VERSION=2.5.9

mkdir -p $UPFUZZ_DIR/prebuild/hadoop
cd $UPFUZZ_DIR/prebuild/hadoop
wget https://archive.apache.org/dist/hadoop/common/hadoop-2.10.2/hadoop-2.10.2.tar.gz ; tar -xzvf hadoop-2.10.2.tar.gz
cp $UPFUZZ_DIR/src/main/resources/hdfs/hbase-pure/core-site.xml $UPFUZZ_DIR/prebuild/hadoop/hadoop-2.10.2/etc/hadoop/ -f
cp $UPFUZZ_DIR/src/main/resources/hdfs/hbase-pure/hdfs-site.xml $UPFUZZ_DIR/prebuild/hadoop/hadoop-2.10.2/etc/hadoop/ -f
cp $UPFUZZ_DIR/src/main/resources/hdfs/hbase-pure/hadoop-env.sh $UPFUZZ_DIR/prebuild/hadoop/hadoop-2.10.2/etc/hadoop/ -f

mkdir -p $UPFUZZ_DIR/prebuild/hbase
cd $UPFUZZ_DIR/prebuild/hbase
wget https://archive.apache.org/dist/hbase/"$ORI_VERSION"/hbase-"$ORI_VERSION"-bin.tar.gz -O hbase-"$ORI_VERSION".tar.gz ; tar -xzvf hbase-"$ORI_VERSION".tar.gz
wget https://archive.apache.org/dist/hbase/"$UP_VERSION"/hbase-"$UP_VERSION"-bin.tar.gz -O hbase-"$UP_VERSION".tar.gz ; tar -xzvf hbase-"$UP_VERSION".tar.gz
cp $UPFUZZ_DIR/src/main/resources/hbase/compile-src/hbase-env.sh $UPFUZZ_DIR/prebuild/hbase/hbase-$ORI_VERSION/conf/ -f
cp $UPFUZZ_DIR/src/main/resources/hbase/compile-src/hbase-env.sh $UPFUZZ_DIR/prebuild/hbase/hbase-$UP_VERSION/conf/ -f

# If testing 3.0.0
# cp $UPFUZZ_DIR/src/main/resources/hbase/compile-src/hbase-env-jdk17.sh $UPFUZZ_DIR/prebuild/hbase/hbase-$UP_VERSION/conf/hbase-env.sh -f


# for hbase version >= 2.4.0, use hbase_daemon3.py
# for hbase version < 2.4.0, use hbase_daemon2.py
cp $UPFUZZ_DIR/src/main/resources/hbase/compile-src/hbase_daemon3.py $UPFUZZ_DIR/prebuild/hbase/hbase-$ORI_VERSION/bin/hbase_daemon.py
cp $UPFUZZ_DIR/src/main/resources/hbase/compile-src/hbase_daemon3.py $UPFUZZ_DIR/prebuild/hbase/hbase-$UP_VERSION/bin/hbase_daemon.py


cd $UPFUZZ_DIR/src/main/resources/hdfs/hbase-pure/
docker build . -t upfuzz_hdfs:hadoop-2.10.2

cd $UPFUZZ_DIR/src/main/resources/hbase/compile-src/
docker build . -t upfuzz_hbase:hbase-"$ORI_VERSION"_hbase-"$UP_VERSION"

cd $UPFUZZ_DIR
./gradlew copyDependencies
./gradlew :spotlessApply build

# open terminal1: start server (this runs in foreground)
bin/start_server.sh hbase_config.json
# open terminal2: start one client (this runs in background)
bin/start_clients.sh 1 hbase_config.json

# stop testing
bin/hbase_cl.sh
```

#### HDFS: 3.11.17 => 4.1.4

```bash
git clone git@github.com:zlab-purdue/upfuzz.git
cd upfuzz
export UPFUZZ_DIR=$PWD
export ORI_VERSION=2.10.2
export UP_VERSION=3.3.6

mkdir -p $UPFUZZ_DIR/prebuild/hdfs
cd $UPFUZZ_DIR/prebuild/hdfs
wget https://archive.apache.org/dist/hadoop/common/hadoop-"$ORI_VERSION"/hadoop-"$ORI_VERSION".tar.gz ; tar -xzvf hadoop-$ORI_VERSION.tar.gz
wget https://archive.apache.org/dist/hadoop/common/hadoop-"$UP_VERSION"/hadoop-"$UP_VERSION".tar.gz ; tar -xzvf hadoop-"$UP_VERSION".tar.gz

# old version hdfs daemon
cp $UPFUZZ_DIR/src/main/resources/FsShellDaemon2.java $UPFUZZ_DIR/prebuild/hdfs/hadoop-"$ORI_VERSION"/FsShellDaemon.java
cd $UPFUZZ_DIR/prebuild/hdfs/hadoop-"$ORI_VERSION"/
/usr/lib/jvm/java-8-openjdk-amd64/bin/javac -d . -cp "share/hadoop/hdfs/*:share/hadoop/common/*:share/hadoop/common/lib/*" FsShellDaemon.java
sed -i "s/elif \[ \"\$COMMAND\" = \"dfs\" \] ; then/elif [ \"\$COMMAND\" = \"dfsdaemon\" ] ; then\n  CLASS=org.apache.hadoop.fs.FsShellDaemon\n  HADOOP_OPTS=\"\$HADOOP_OPTS \$HADOOP_CLIENT_OPTS\"\n&/" bin/hdfs

# new version hdfs daemon
cp $UPFUZZ_DIR/src/main/resources/FsShellDaemon_trunk.java $UPFUZZ_DIR/prebuild/hdfs/hadoop-"$UP_VERSION"/FsShellDaemon.java
cd $UPFUZZ_DIR/prebuild/hdfs/hadoop-"$UP_VERSION"/
/usr/lib/jvm/java-8-openjdk-amd64/bin/javac -d . -cp "share/hadoop/hdfs/*:share/hadoop/common/*:share/hadoop/common/lib/*" FsShellDaemon.java
sed -i "s/  case \${subcmd} in/&\n    dfsdaemon)\n      HADOOP_CLASSNAME=\"org.apache.hadoop.fs.FsShellDaemon\"\n    ;;/" bin/hdfs

cd $UPFUZZ_DIR/src/main/resources/hdfs/compile-src/
sed -i "s/ORI_VERSION=hadoop-.*$/ORI_VERSION=hadoop-$ORI_VERSION/" hdfs-clusternode.sh
sed -i "s/UPG_VERSION=hadoop-.*$/UPG_VERSION=hadoop-$UP_VERSION/" hdfs-clusternode.sh
docker build . -t upfuzz_hdfs:hadoop-"$ORI_VERSION"_hadoop-"$UP_VERSION"

cd $UPFUZZ_DIR
./gradlew copyDependencies
./gradlew :spotlessApply build

# open terminal1: start server
bin/start_server.sh hdfs_config.json
# open terminal2: start one client
bin/start_clients.sh 1 hdfs_config.json

# stop testing
bin/hdfs_cl.sh
```

## Full Evaluation Instructions (2 hours)

To facilitate a push-button artifact evaluation workflow, we provide pre-built instrumented binaries for all system versions evaluated in the paper. Using these binaries, reviewers do not need to re-run source code analysis or instrumentation.

We also provide scripts and traces to reproduce all reported results.

### Reproduce Table 2: New Bugs Found by UpFuzz
15 newly discovered data-format bugs.

Bug-triggering traces are provided for:
* Baseline (BC) mode 
* Final mode (BC + DF + VD)

### Reproduce Table 3: Existing Bugs
Scripts and traces are provided to reproduce previously known bugs under the same experimental setup.

### Reproduce Figure 14: State Exploration
Run UpFuzz in state exploration mode.

Scripts are provided to generate the final figure.

### Reproduce Table 4: Overhead
Scripts are provided to reproduce the overhead measurements reported in the paper.

### Reproducing Bugs Directly with UpFuzz

In this mode, UpFuzz runs directly using pre-generated command sequences to reproduce each bug individually.
