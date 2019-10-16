# Create and setup VMs for labs

## Configure training

Create a `training.yml` file inspired on [`training/training.yml`](training/training.yml) to set training info:

- `training_name`: training name, e.g `k8s-user`

## Create VMs

Create VMs for lab:

```shell
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...

./infra4lab.sh
```

You can adapt variables (like the list of trainees) a posteriori then launch the tool again.

## Destroy VMs

Don't forget to delete the VMs at the end of the session:

```shell
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...

./infra4lab.sh --tags destroy
```
