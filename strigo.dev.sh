#!/bin/sh

docker run --rm --interactive --tty \
  --volume ${PWD}:/work \
  --volume ${PWD}/training:/training \
  --volume ${PWD}/training/workspaces:/workspaces \
  --env STRIGO_ORG_ID --env STRIGO_API_KEY \
  zenika/infra4lab strigo.yml "$@"
