#!/bin/sh

docker run --rm --interactive --tty \
  --volume ${PWD}:/work \
  --volume ${PWD}/training:/training \
  --volume ${PWD}/training/workspaces:/workspaces \
  zenika/infra4lab strigo.yml "$@"
