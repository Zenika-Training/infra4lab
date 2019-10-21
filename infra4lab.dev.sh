#!/bin/sh

docker run --rm --interactive --tty \
  --volume ${PWD}:/work \
  --volume ${PWD}/training:/training \
  --volume ${PWD}/training/workspaces:/workspaces \
  --env AWS_ACCESS_KEY_ID --env AWS_SECRET_ACCESS_KEY \
  zenika/infra4lab "$@"
