#!/bin/sh

AWS_OPTS="--volume ${HOME}/.aws:/home/ansible/.aws --env AWS_PROFILE=zenika-training"
if [ -n "${AWS_PROFILE}" ]; then
  AWS_OPTS="--volume ${HOME}/.aws:/home/ansible/.aws --env AWS_PROFILE"
elif [ -n "${AWS_ACCESS_KEY_ID}" ]; then
  AWS_OPTS="--env AWS_ACCESS_KEY_ID --env AWS_SECRET_ACCESS_KEY"
fi

docker run --rm --interactive --tty \
  --volume ${PWD}:/training \
  --volume ${PWD}/../Exercices/workspaces:/workspaces \
  ${AWS_OPTS} \
  zenika/infra4lab "$@"
