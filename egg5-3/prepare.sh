#!/bin/bash

function ConfirmProjectId() {
  echo "プロジェクトIDを入力してください。: "
  read input

  if [ -z $input ] ; then
    ConfirmExecution
  fi
}

ConfirmProjectId
gcloud config set project $input
export GOOGLE_CLOUD_PROJECT=$(gcloud config list project --format "value(core.project)")
echo "プロジェクトID: "$GOOGLE_CLOUD_PROJECT