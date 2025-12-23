#!/bin/bash
set -e

CASS_FOLDER_URL="https://drive.google.com/drive/folders/1M9bEOYbbVaaYd7f54ND684_Oo90s_vDW"
CASS_DIR="cassandra"

HBASE_FOLDER_URL="https://drive.google.com/drive/folders/1uQZpnWuPaMoDJRE6bv_hF1B_epsRULN0"
HBASE_DIR="hbase"

HDFS_FOLDER_URL="https://drive.google.com/drive/folders/1EElA0esFCRnDRzVsncDE9J1AhYG8UqCo"
HDFS_DIR="hdfs"

if ! command -v gdown &> /dev/null; then
  echo "[INFO] gdown not found, installing via python3..."
  pip3 install --user gdown
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
  source ~/.zshrc
fi

mkdir -p ${CASS_DIR}
gdown --folder ${CASS_FOLDER_URL} -O ${CASS_DIR}

mkdir -p ${HBASE_DIR}
gdown --folder ${HBASE_FOLDER_URL} -O ${HBASE_DIR}

mkdir -p ${HDFS_DIR}
gdown --folder ${HDFS_FOLDER_URL} -O ${HDFS_DIR}

echo "[DONE] Traces downloaded:"

