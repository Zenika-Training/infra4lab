# Create and setup VMs for labs

## Configure AWS

### Configure AWS credentials

You need to get your `ACCESS_KEY_ID` and `SECRET_ACCESS_KEY` from your AWS account.

You can then set the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables.

For better security it is advised to use [named profiles](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html):

- Create folder `~/.aws/` folder
- Create file `~/.aws/credentials` with mode `0600` and content:

    ```ini
    [zenika-training]
    aws_access_key_id = ...
    aws_secret_access_key = ...
    ```
- Set `AWS_PROFILE` to the name of the profile if you use something else than `zenika-training`

### Configure Amazon Simple Email Service

Email to trainees is sent using [Amazon Simple Email Service](https://aws.amazon.com/ses/).

To be able to use it, you need to:

- [move out of the Amazon SES Sandbox](https://docs.aws.amazon.com/en_pv/ses/latest/DeveloperGuide/request-production-access.html)
- [verify your `@zenika.com` email address](https://docs.aws.amazon.com/en_pv/ses/latest/DeveloperGuide/verify-email-addresses-procedure.html) (if it doesn't work right away as the `zenika.com` domain should be already [validated](https://docs.aws.amazon.com/en_pv/ses/latest/DeveloperGuide/verify-domain-procedure.html))

## Configure training

Create a `training.yml` file inspired on [`training/training.yml`](training/training.yml) to set training info:

- `training_name`: training name, e.g `k8s-user`
- `aws_instances`: AWS instances for each trainee, list of objects with:
  - `name`: name of the instance, e.g. `node-0`
  - `type`: AWS type of the instance, e.g. `t2.micro`
- `roles`: roles to apply to each instances, list of objects with:
  - `name`: name of the role to apply
  - `target`: list of instance name to apply the role to, use `all` to apply to all instances
  - `vars`: dict of variables for the role. See each role documentation to know them
- `open_ports`: optionnal ports to open (other than `22`, `80`, `443` and `8000-8999`), list of port values and port ranges, e.g. `[3000, {'from': 1500, 'to': 2500}]`

Existing roles:

- [`guacamole`](roles/guacamole/README.md)
- [`workspaces`](roles/workspaces/README.md)
- [`docker`](roles/docker/README.md)
- [`kubernetes`](roles/kubernetes/README.md)

Create any extra role you want in a `roles` folder in your training.

## Session extra configuration

When asked for session extra config, you can fill `sessions/current/group_vars/extra.yml`.

You can also fill it afterwards and relaunch the tool.

Possible configurations are:

- `authorized_ips`: a list of IP addresses to authorize to access VMs

## Create VMs

Create VMs for lab:

```shell
#export AWS_ACCESS_KEY_ID=...
#export AWS_SECRET_ACCESS_KEY=...
# OR
#export AWS_PROFILE=...

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

To only send the instances email, you can use the tag `email`:

```shell
./infra4lab.sh --tags email
```

## Destroy VMs

Don't forget to delete the VMs at the end of the session:

```shell
#export AWS_ACCESS_KEY_ID=...
#export AWS_SECRET_ACCESS_KEY=...
# OR
#export AWS_PROFILE=...

./infra4lab.sh --tags destroy
```
