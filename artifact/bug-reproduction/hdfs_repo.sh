
hdfs_repo_func() {
  # $1: BUG_ID
  # $2: SPECIAL_CONFIG (true/false)

  local BUG_ID=$1
  local SPECIAL_CONFIG=$2
  local SYSTEM="HDFS"
  local SYSTEM_SHORT="hdfs"
  local UPFUZZ_DIR=~/project/upfuzz

  local ORI_VERSION=2.10.2
  local UP_VERSION=3.3.6

  cd $UPFUZZ_DIR

  mkdir -p prebuild/hdfs
  cd prebuild/hdfs

  if [ ! -d "hadoop-$ORI_VERSION" ]; then
    wget https://archive.apache.org/dist/hadoop/common/hadoop-"$ORI_VERSION"/hadoop-"$ORI_VERSION".tar.gz
    tar -xzvf hadoop-"$ORI_VERSION".tar.gz
  fi
  if [ ! -d "hadoop-$UP_VERSION" ]; then
    wget https://archive.apache.org/dist/hadoop/common/hadoop-"$UP_VERSION"/hadoop-"$UP_VERSION".tar.gz
    tar -xzvf hadoop-"$UP_VERSION".tar.gz
  fi

  cd ${UPFUZZ_DIR}
  cp src/main/resources/FsShellDaemon2.java prebuild/hdfs/hadoop-"$ORI_VERSION"/FsShellDaemon.java
  cp src/main/resources/FsShellDaemon_trunk.java prebuild/hdfs/hadoop-"$UP_VERSION"/FsShellDaemon.java

  docker pull hanke580/upfuzz-ae:hdfs-${ORI_VERSION}_${UP_VERSION}
  docker tag \
    hanke580/upfuzz-ae:hdfs-${ORI_VERSION}_${UP_VERSION} \
    upfuzz_hdfs:hadoop-${ORI_VERSION}_hadoop-${UP_VERSION}

  cd ${UPFUZZ_DIR}
  ./gradlew copyDependencies
  ./gradlew :spotlessApply build

  # copy config and triggering commands
  cd ${UPFUZZ_DIR}
  cp examplecase/nsdi26-ae/${SYSTEM}-${BUG_ID}/hdfs_config.json hdfs_config.json
  cp examplecase/nsdi26-ae/${SYSTEM}-${BUG_ID}/commands.txt examplecase/commands.txt
  cp examplecase/nsdi26-ae/${SYSTEM}-${BUG_ID}/validcommands.txt examplecase/validcommands.txt

  # Reproduction run
  tmux kill-session -t 0
  tmux new-session -d -s 0 \; split-window -v \;
  tmux send-keys -t 0:0.0 C-m 'bin/start_server.sh hdfs_config.json > server.log' C-m \;
  tmux send-keys -t 0:0.1 C-m 'sleep 2; bin/start_clients.sh 1 hdfs_config.json' C-m

  # Clean after one test (< 2 minutes)
  sleep 480 && cd ~/project/upfuzz; sudo chmod 777 /var/run/docker.sock; bin/clean.sh --force;

  # check failure reports
  ls failure
  bin/check_${SYSTEM_SHORT}_${BUG_ID}.sh
}

hdfs_repo_func "$1" "$2"