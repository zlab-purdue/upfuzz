cass_repo_func() {
  # $1: BUG_ID
  # $2: SPECIAL_CONFIG (true/false)

  local BUG_ID=$1
  local SPECIAL_CONFIG=$2
  local SYSTEM="CASSANDRA"
  local SYSTEM_SHORT="cass"
  local UPFUZZ_DIR=~/project/upfuzz

  local ORI_VERSION=4.1.6
  local UP_VERSION=5.0.2

  cd $UPFUZZ_DIR

  mkdir -p prebuild/cassandra
  cd prebuild/cassandra

  if [ ! -d "apache-cassandra-$ORI_VERSION" ]; then
    wget https://archive.apache.org/dist/cassandra/"$ORI_VERSION"/apache-cassandra-"$ORI_VERSION"-bin.tar.gz
    tar -xzvf apache-cassandra-"$ORI_VERSION"-bin.tar.gz
  fi
  if [ ! -d "apache-cassandra-$UP_VERSION" ]; then
    wget https://archive.apache.org/dist/cassandra/"$UP_VERSION"/apache-cassandra-"$UP_VERSION"-bin.tar.gz
    tar -xzvf apache-cassandra-"$UP_VERSION"-bin.tar.gz
  fi

  cd ${UPFUZZ_DIR}
  cp src/main/resources/cqlsh_daemon4.py prebuild/cassandra/apache-cassandra-"$ORI_VERSION"/bin/cqlsh_daemon.py
  cp src/main/resources/cqlsh_daemon5.py  prebuild/cassandra/apache-cassandra-"$UP_VERSION"/bin/cqlsh_daemon.py

  docker pull hanke580/upfuzz-ae:cassandra-${ORI_VERSION}_${UP_VERSION}
  docker tag \
    hanke580/upfuzz-ae:cassandra-${ORI_VERSION}_${UP_VERSION} \
    upfuzz_cassandra:apache-cassandra-${ORI_VERSION}_apache-cassandra-${UP_VERSION}

  cd ${UPFUZZ_DIR}
  ./gradlew copyDependencies
  ./gradlew :spotlessApply build

  # copy config and triggering commands
  cd ${UPFUZZ_DIR}
  cp examplecase/nsdi26-ae/${SYSTEM}-${BUG_ID}/config.json config.json
  cp examplecase/nsdi26-ae/${SYSTEM}-${BUG_ID}/commands.txt examplecase/commands.txt
  cp examplecase/nsdi26-ae/${SYSTEM}-${BUG_ID}/validcommands.txt examplecase/validcommands.txt

  # special config (only for this bug)
  if [ "$SPECIAL_CONFIG" == "true" ]; then
    cp examplecase/nsdi26-ae/${SYSTEM}-${BUG_ID}/cassandra_ori.yaml prebuild/cassandra/apache-cassandra-${ORI_VERSION}/conf/cassandra.yaml
    cp examplecase/nsdi26-ae/${SYSTEM}-${BUG_ID}/cassandra_up.yaml prebuild/cassandra/apache-cassandra-${UP_VERSION}/conf/cassandra.yaml
  fi

  # Reproduction run
  tmux kill-session -t 0
  tmux new-session -d -s 0 \; split-window -v \;
  tmux send-keys -t 0:0.0 C-m 'bin/start_server.sh config.json > server.log' C-m \;
  tmux send-keys -t 0:0.1 C-m 'sleep 2; bin/start_clients.sh 1 config.json' C-m

  # Clean after one test (< 2 minutes)
  sleep 120 && cd ~/project/upfuzz; sudo chmod 777 /var/run/docker.sock; bin/clean.sh --force;

  # check failure reports
  ls failure
  bin/check_${SYSTEM_SHORT}_${BUG_ID}.sh
}

cass_repo_func "$1" "$2"