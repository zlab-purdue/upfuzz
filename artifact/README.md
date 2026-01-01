# Artifact of upfuzz

## Overview

This repository contains the source code and artifact materials for **UpFuzz**, a framework for discovering data-format and upgrade bugs in distributed storage systems.

We provided our source code, the push-button script to run the testing framework and our experiment trace for evaluation. 

## Experiment data

To evaluate upfuzz, we conducted a large number of experiments, totaling > five months of a single machine time (We paralleled experiments with more servers). In accordance with the artifact evaluation (AE) guidelines, we do not expect reviewers to rerun all experiments from scratch to validate our results.

Instead, we release our **raw experimental data**, allowing reviewers to download the data and run scripts to reproduce all figures and tables reported in the paper.

For experiments that require substantial computational resources, we additionally provide:
- Bug-triggering traces
- Execution logs

These artifacts enable result reproduction without re-running the full-scale experiments.

---
## Requirements

We strongly encourage you to run experiments using cloudlab machines, specifically `c220g5`. All our experiments were conducted using cloudlab `c220g5`.

Start up an instance for `c220g5`, run the following scripts to install all required dependencies.

(TODO: allow directly downloading this script)
Create a script by `vim install.sh` and copy the following script into it.
Then execute `bash install.sh`

```bash
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

# trace figure
sudo apt install -y python3-pip
python3 -m pip install --user numpy matplotlib scipy

# Set up zsh
echo "Y" | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="daveverwer"/' ~/.zshrc
echo "exec zsh" >> ~/.bashrc

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

sudo usermod -aG docker $USER
sudo systemctl stop docker.service
sudo systemctl stop docker.socket

sudo mv /var/lib/docker /mnt_ssd/
sudo ln -s /mnt_ssd/docker /var/lib/docker

sudo systemctl daemon-reload   
sudo systemctl start docker

sudo mkdir /mydata/test_binary
sudo chown $USER /mydata/test_binary

newgrp docker
```

## Kick-the-tires Instructions (~30 minutes)

The previous steps make sure there exists `~/project/` folder.

### Clone the repo
```bash
cd ~/project
git clone https://github.com/zlab-purdue/upfuzz.git

cd ~/project/upfuzz
```

Basic upfuzz: This section demonstrates how to start upgrade testing immediately using branch coverage mode.

### Test Cassandra: 3.11.17 => 4.1.4

**Start up testing process**
* It starts up one fuzzing server and one fuzzing client (parallel num = 1)

```bash
cd ~/project/upfuzz
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

docker pull hanke580/upfuzz-ae:cassandra-3.11.17_4.1.4
docker tag \
  hanke580/upfuzz-ae:cassandra-3.11.17_4.1.4 \
  upfuzz_cassandra:apache-cassandra-3.11.17_apache-cassandra-4.1.4

cd ${UPFUZZ_DIR}
./gradlew copyDependencies
./gradlew :spotlessApply build

# Create session + Test run
tmux new-session -d -s 0 \; split-window -v \;
tmux send-keys -t 0:0.0 C-m 'bin/start_server.sh config.json > server.log' C-m \;
tmux send-keys -t 0:0.1 C-m 'sleep 2; bin/start_clients.sh 1 config.json > client.log' C-m
```

**Check Testing Status**
```bash
cd ~/project/upfuzz
# check logs

# server logs: contain testing coverage, failure info
vim server.log
vim client.log

# check containers
docker ps

# check failure
ls failure/
```

**Stop Testing**
```bash
bin/clean.sh
```

**Remove Generated files**
Long time fuzzing could generate lots of files (recorded tests, logs, failure reports...), which could take a large amount of the disk space. Usually after examining the bug reports, we use the following commands to remove useless files.
```bash
bin/rm.sh
```


### Test HBase: 2.4.18 => 2.5.9

```bash
cd ~/project/upfuzz
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

cp $UPFUZZ_DIR/src/main/resources/hbase/compile-src/hbase_daemon3.py $UPFUZZ_DIR/prebuild/hbase/hbase-$ORI_VERSION/bin/hbase_daemon.py
cp $UPFUZZ_DIR/src/main/resources/hbase/compile-src/hbase_daemon3.py $UPFUZZ_DIR/prebuild/hbase/hbase-$UP_VERSION/bin/hbase_daemon.py


docker pull hanke580/upfuzz-ae:hbase-2.4.18_2.5.9
docker tag hanke580/upfuzz-ae:hbase-2.4.18_2.5.9 \
  upfuzz_hbase:hbase-2.4.18_hbase-2.5.9

docker pull hanke580/upfuzz-ae:hdfs-2.10.2
docker tag hanke580/upfuzz-ae:hdfs-2.10.2 \
  upfuzz_hdfs:hadoop-2.10.2

cd $UPFUZZ_DIR
./gradlew copyDependencies
./gradlew :spotlessApply build

# Create session + Test run
tmux new-session -d -s 0 \; split-window -v \;
tmux send-keys -t 0:0.0 C-m 'bin/start_server.sh hbase_config.json > server.log' C-m \;
tmux send-keys -t 0:0.1 C-m 'sleep 2; bin/start_clients.sh 1 hbase_config.json > client.log' C-m
```

**Check Testing Status**

same as Cassandra

**Stop Testing**

same as Cassandra

**Remove Generated files**

same as Cassandra

### Test HDFS: 2.10.2 => 3.3.6

```bash
cd ~/project/upfuzz
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

# Pull the pre-built HDFS upgrade image
docker pull hanke580/upfuzz-ae:hdfs-2.10.2_3.3.6
# Create a local alias expected by UpFuzz scripts
docker tag hanke580/upfuzz-ae:hdfs-2.10.2_3.3.6 \
  upfuzz_hdfs:hadoop-2.10.2_hadoop-3.3.6

cd $UPFUZZ_DIR
./gradlew copyDependencies
./gradlew :spotlessApply build

# Create session + Test run
tmux new-session -d -s 0 \; split-window -v \;
tmux send-keys -t 0:0.0 C-m 'bin/start_server.sh hdfs_config.json > server.log' C-m \;
tmux send-keys -t 0:0.1 C-m 'sleep 2; bin/start_clients.sh 1 hdfs_config.json > client.log' C-m
```

**Check Testing Status**

same as Cassandra

**Stop Testing**

same as Cassandra

**Remove Generated files**

same as Cassandra

## Full Evaluation Instructions

To facilitate a push-button artifact evaluation workflow, we provide pre-built instrumented binaries for all system versions evaluated in the paper. Using these binaries, reviewers do not need to re-run source code analysis or instrumentation.

We provide scripts and traces to reproduce all reported results.

### Reproduce Figure 14: State Exploration
Run UpFuzz in state exploration mode.

Scripts are provided to generate the final figure.

```bash
cd ~/project/upfuzz
cd artifact/state-exploration
wget https://github.com/zlab-purdue/upfuzz/releases/download/v1.0-data/state-exploration-data.tar.gz
tar -xzvf state-exploration-data.tar.gz
python3 run.py

# all.pdf will be generated at path artifact/state-exploration/all.pdf
ls -l all.pdf
```

### Reproduce Table 2: trigger newly detected bugs 

In this mode, UpFuzz runs directly using pre-generated command sequences to reproduce each bug individually. Reviews could simply run the reproducing mode and observe the triggering results.

Each bug reproduction contains a separate script. As long as upfuzz repo is cloned, use the push-button script could reproduce the bug immediately.

1. CASSANDRA-18105
```bash
# 2.2.19 => 3.0.30
cd ~/project/upfuzz
bash cass_repo_2_3.sh 18105 false
```

2. CASSANDRA-18108
```bash
# 4.1.6 => 5.0.2
cd ~/project/upfuzz
bash cass_repo_4_5.sh 18108 false
```

3. CASSANDRA-19590
```bash
# 2.2.19 => 3.0.30
cd ~/project/upfuzz
bash cass_repo_2_3.sh 19590 false
```

4. CASSANDRA-19591
```bash
cd ~/project/upfuzz
bash cass_repo_2_3.sh 19639 false
```


5. CASSANDRA-19623
```bash
cd ~/project/upfuzz
bash cass_repo_2_3.sh 19623 true
```

6. CASSANDRA-19639
```bash
cd ~/project/upfuzz
bash cass_repo_2_3.sh 19639 true
```

7. CASSANDRA-19689
```bash
cd ~/project/upfuzz
bash cass_repo_2_3.sh 19689 false
```

8. CASSANDRA-20182
```bash
cd ~/project/upfuzz
bash cass_repo_2_3.sh 20182 true
```

9. HBASE-28583
```bash
# 2.5.9 => 3.0.0 (516c89e8597fb6)
cd ~/project/upfuzz
bash hbase_repo.sh 28583 false
```

10. HBASE-28812
```bash
# 2.6.0 => 3.0.0
# similar procedural as the previous bugs
cd ~/project/upfuzz
bash hbase_repo.sh 28812 false
```

11. HBASE-28815
```bash
# 1.7.2 => 2.6.0
# similar procedural as the previous bugs
cd ~/project/upfuzz
bash hbase_repo.sh 28815 false
```

12. HBASE-29021
```bash
# 2.5.9 => 3.0.0 (516c89e8597fb6)
# similar procedural as the previous bugs
cd ~/project/upfuzz
bash hbase_repo.sh 29021 false
```

13. HDFS-16984
```bash
# 2.10.2 => 3.3.6
cd ~/project/upfuzz
bash hdfs_repo.sh 16984 false
```
14.HDFS-17219
```bash
# 2.10.2 => 3.3.6
cd ~/project/upfuzz
bash hdfs_repo.sh 17219 false
```

15.HDFS-17686
```bash
# 2.10.2 => 3.3.6
cd ~/project/upfuzz
bash hdfs_repo.sh 17686 false
```

### Reproduce Table 2: triggering trace

We'll provide the detailed testing logs for the following 2 modes:
* Baseline (BC) mode 
* Final mode (BC + DF + VD)

### Reproduce Table 4: Overhead
Scripts are provided to reproduce the overhead measurements reported in the paper.

* Download our prebuilt instrumented binaries, run upfuzz with a test with/without collecting data format feedback and then compute the overhead.

We'll provide a push-button script to get this result directly.