#!/bin/sh

docker run --rm \
  --volume ${PWD}:/training \
  --volume ${PWD}/../Exercices/workspaces:/workspaces \
  --env STRIGO_ORG_ID --env STRIGO_API_KEY \
  zenika/infra4lab strigo.yml "$@"
