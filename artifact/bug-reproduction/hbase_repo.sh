hbase_repo_func() {
  # $1: BUG_ID
  # $2: SPECIAL_CONFIG (true/false)

  local BUG_ID=$1
  local SPECIAL_CONFIG=$2
  local SYSTEM="HBASE"
  local SYSTEM_SHORT="hbase"
  local UPFUZZ_DIR=~/project/upfuzz

  local ORI_VERSION=2.5.9
  local UP_VERSION=3.0.0

  cd $UPFUZZ_DIR

  mkdir -p prebuild/hbase
  cd prebuild/hbase

  if [ ! -d "hbase-$ORI_VERSION" ]; then
    wget https://archive.apache.org/dist/hbase/"$ORI_VERSION"/hbase-"$ORI_VERSION"-bin.tar.gz
    tar -xzvf hbase-"$ORI_VERSION"-bin.tar.gz
  fi
  if [ ! -d "hbase-$UP_VERSION" ]; then
    wget https://archive.apache.org/dist/hbase/"$UP_VERSION"/hbase-"$UP_VERSION"-bin.tar.gz
    tar -xzvf hbase-"$UP_VERSION"-bin.tar.gz
  fi

  cp $UPFUZZ_DIR/src/main/resources/hbase/compile-src/hbase-env.sh $UPFUZZ_DIR/prebuild/hbase/hbase-$ORI_VERSION/conf/ -f
  cp $UPFUZZ_DIR/src/main/resources/hbase/compile-src/hbase-env.sh $UPFUZZ_DIR/prebuild/hbase/hbase-$UP_VERSION/conf/ -f

  # If testing 3.0.0
  cp $UPFUZZ_DIR/src/main/resources/hbase/compile-src/hbase-env-jdk17.sh $UPFUZZ_DIR/prebuild/hbase/hbase-$UP_VERSION/conf/hbase-env.sh -f

  # for hbase version >= 2.4.0, use hbase_daemon3.py
  # for hbase version < 2.4.0, use hbase_daemon2.py
  cp $UPFUZZ_DIR/src/main/resources/hbase/compile-src/hbase_daemon3.py $UPFUZZ_DIR/prebuild/hbase/hbase-$ORI_VERSION/bin/hbase_daemon.py
  cp $UPFUZZ_DIR/src/main/resources/hbase/compile-src/hbase_daemon3.py $UPFUZZ_DIR/prebuild/hbase/hbase-$UP_VERSION/bin/hbase_daemon.py

  docker pull hanke580/upfuzz-ae:hbase-${ORI_VERSION}_${UP_VERSION}
  docker tag \
    hanke580/upfuzz-ae:hbase-${ORI_VERSION}_${UP_VERSION} \
    upfuzz_hbase:hbase-${ORI_VERSION}_hbase-${UP_VERSION}

  docker pull hanke580/upfuzz-ae:hdfs-2.10.2
  docker tag hanke580/upfuzz-ae:hdfs-2.10.2 \
    upfuzz_hdfs:hadoop-2.10.2

  cd ${UPFUZZ_DIR}
  ./gradlew copyDependencies
  ./gradlew :spotlessApply build

  # copy config and triggering commands
  cd ${UPFUZZ_DIR}
  cp examplecase/nsdi26-ae/${SYSTEM}-${BUG_ID}/hbase_config.json hbase_config.json
  cp examplecase/nsdi26-ae/${SYSTEM}-${BUG_ID}/commands.txt examplecase/commands.txt
  cp examplecase/nsdi26-ae/${SYSTEM}-${BUG_ID}/validcommands.txt examplecase/validcommands.txt

  # special config (only for this bug)
  if [ "$SPECIAL_CONFIG" == "true" ]; then
    cp examplecase/nsdi26-ae/${SYSTEM}-${BUG_ID}/hbase_ori.yaml prebuild/hbase/hbase-${ORI_VERSION}/conf/hbase.yaml
    cp examplecase/nsdi26-ae/${SYSTEM}-${BUG_ID}/hbase_up.yaml prebuild/hbase/hbase-${UP_VERSION}/conf/hbase.yaml
  fi

  # Reproduction run
  tmux new-session -d -s 0 \; split-window -v \;
  tmux send-keys -t 0:0.0 C-m 'bin/start_server.sh config.json > server.log' C-m \;
  tmux send-keys -t 0:0.1 C-m 'sleep 2; bin/start_clients.sh 1 config.json' C-m

  # Clean after one test (< 2 minutes)
  sleep 120 && cd ~/project/upfuzz; sudo chmod 777 /var/run/docker.sock; bin/clean.sh --force;

  # check failure reports
  ls failure
  bin/check_${SYSTEM_SHORT}_${BUG_ID}.sh
}


# Binary path
ls /proj/sosp21-upgrade-PG0/upfuzz_files/binary/hbase
ls /proj/sosp21-upgrade-PG0/upfuzz_files/format_inst_binary/hbase

# Prepare env
cd ~/project
git clone git@github.com:zlab-purdue/upfuzz.git

# ===
cd ~/project/upfuzz
git checkout .
git checkout dev
git pull

cd ~/project/upfuzz
export UPFUZZ_DIR=$PWD
export ORI_VERSION=2.5.9
export UP_VERSION=3.0.0

mkdir -p $UPFUZZ_DIR/prebuild/hadoop
cd $UPFUZZ_DIR/prebuild/hadoop
sudo rm -rf hadoop-2.10.2
HDFS_BIN_PATH=/proj/sosp21-upgrade-PG0/upfuzz_files/binary/hdfs/
tar -xzvf $HDFS_BIN_PATH/hadoop-2.10.2.tar.gz
cp $UPFUZZ_DIR/src/main/resources/hdfs/hbase-pure/core-site.xml $UPFUZZ_DIR/prebuild/hadoop/hadoop-2.10.2/etc/hadoop/ -f
cp $UPFUZZ_DIR/src/main/resources/hdfs/hbase-pure/hdfs-site.xml $UPFUZZ_DIR/prebuild/hadoop/hadoop-2.10.2/etc/hadoop/ -f
cp $UPFUZZ_DIR/src/main/resources/hdfs/hbase-pure/hadoop-env.sh $UPFUZZ_DIR/prebuild/hadoop/hadoop-2.10.2/etc/hadoop/ -f

mkdir -p $UPFUZZ_DIR/prebuild/hbase
cd $UPFUZZ_DIR/prebuild/hbase

sudo rm -rf hbase-$ORI_VERSION
sudo rm -rf hbase-$UP_VERSION

HBASE_BIN_PATH=/proj/sosp21-upgrade-PG0/upfuzz_files/binary/hbase/
HBASE_FORMAT_BIN_PATH=/proj/sosp21-upgrade-PG0/upfuzz_files/format_inst_binary/hbase/

# tar -xzvf $HBASE_BIN_PATH/hbase-"$ORI_VERSION".tar.gz
# tar -xzvf $HBASE_FORMAT_BIN_PATH/hbase-"$ORI_VERSION"-bin-INST.tar.gz
tar -xzvf $HBASE_FORMAT_BIN_PATH/hbase-"$ORI_VERSION"-bin-INST-global.tar.gz
# tar -xzvf $HBASE_BIN_PATH/hbase-"$UP_VERSION".tar.gz
tar -xzvf $HBASE_BIN_PATH/hbase-"$UP_VERSION"-516c89e8597fb6-bin.tar.gz 

cp $UPFUZZ_DIR/src/main/resources/hbase/compile-src/hbase-env.sh $UPFUZZ_DIR/prebuild/hbase/hbase-$ORI_VERSION/conf/ -f
cp $UPFUZZ_DIR/src/main/resources/hbase/compile-src/hbase-env.sh $UPFUZZ_DIR/prebuild/hbase/hbase-$UP_VERSION/conf/ -f

# If testing 3.0.0
cp $UPFUZZ_DIR/src/main/resources/hbase/compile-src/hbase-env-jdk17.sh $UPFUZZ_DIR/prebuild/hbase/hbase-$UP_VERSION/conf/hbase-env.sh -f

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
