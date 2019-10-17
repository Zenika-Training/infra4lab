# Create and setup VMs for labs

## Configure training

Create a `training.yml` file inspired on [`training/training.yml`](training/training.yml) to set training info:

- `training_name`: training name, e.g `k8s-user`
- `aws_instances`: AWS instances for each trainee, list of objects with:
  - `name`: name of the instance, e.g. `node-0`
  - `type`: AWS type of the instance, e.g. `t2.micro`
- `roles`: roles to apply to each instances, list of objects with:
  - `name`: name of the role to apply
  - `target`: list of instance name to apply the role to, use `all` to apply to all instances

Existing roles:

- [`guacamole`](roles/guacamole/README.md)

Create any extra role you want in a `roles` folder in your training.

## Create VMs

Create VMs for lab:

```shell
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...

./infra4lab.sh
```

You can adapt variables (like the list of trainees) a posteriori then launch the tool again.

To launch only the VMs creation, you can use the tag `create`:

```shell
./infra4lab.sh --tags create
```

To launch only the instances setup, you can use the tag `setup`:

```shell
./infra4lab.sh --tags setup
```

## Destroy VMs

Don't forget to delete the VMs at the end of the session:

```shell
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...

./infra4lab.sh --tags destroy
```
