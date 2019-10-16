# Development procedure

## Build

Build the image:

```shell
docker build --tag zenika/infra4lab .
```

## Development

To test your development using the local `training` folder:

```shell
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...

./infra4lab.dev.sh  # --tags destroy
```
