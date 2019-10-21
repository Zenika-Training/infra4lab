#!/bin/sh

docker run --rm --interactive --tty \
  --volume ${PWD}:/training \
  --volume ${PWD}/../Exercices/workspaces:/workspaces \
  --env AWS_ACCESS_KEY_ID --env AWS_SECRET_ACCESS_KEY \
  zenika/infra4lab "$@"
