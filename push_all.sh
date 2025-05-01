#!/bin/bash

IMAGES=(
  "cnfltraining/node-webserver-avro:2.0"
  "confluentinc/cp-ksqldb-server:7.0.0"
  "confluentinc/cp-schema-registry:7.0.0"
  "confluentinc/cp-kafka-connect:7.0.0"
  "confluentinc/cp-enterprise-kafka:7.0.0"
  "confluentinc/cp-enterprise-control-center:7.0.0"
  "confluentinc/cp-zookeeper:7.0.0"
  "cnfltraining/node-webserver:1.0"
  "cnfltraining/java-producer-avro:1.0"
  "postgres:11.2-alpine"
)

for IMAGE in "${IMAGES[@]}"; do
  TAG=$(echo "$IMAGE" | cut -d: -f2)
  NAME=$(echo "$IMAGE" | cut -d: -f1 | awk -F/ '{print $NF}')
  TARGET="itasoftdidit/$NAME:$TAG"
  
  echo "==> Tagging $IMAGE as $TARGET"
  docker tag "$IMAGE" "$TARGET"

  echo "==> Pushing $TARGET"
  docker push "$TARGET"
  echo
done
