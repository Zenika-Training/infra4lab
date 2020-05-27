#!/bin/sh

docker run --rm \
  --volume ${PWD}:/training \
  --volume ${PWD}/../Exercices/workspaces:/workspaces \
  zenika/infra4lab strigo.yml "$@"
