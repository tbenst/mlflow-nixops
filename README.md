# mlflow-nixops

Deploys [mlflow](https://mlflow.org/) tracking server using [NixOps](https://nixos.org/nixops/) on AWS EC2.

## Instructions
First, add secrets/basicauth.nix:
```
{ "user" = "password"; }
```

Now make `secrets/keyId.nix`:
```
"local_aws_profile"
```

Then, make `secrets/boto.cfg` (if using AWS bucket):
```
[Credentials]
aws_access_key_id = XXXXXXXXXXXXXXXXXXXX
aws_secret_access_key = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

```

Finally make `secrets/server_config.nix` (for Amazon Aurora mysql):
```
{
  store_uri = "mysql://admin:@mlflow-instance-1.xxxxx.us-west-2.rds.amazonaws.com:3306/mlflow";
  artifact_root = "s3://xxxxxxxx/mlflow-artifacts/";
  hostname = "mlflow.xxxxx.com";
}

```

This was tested on tbenst/nixpkgs with commit `40e11a4fd00b82805e7f647dcbd32aeaa1eeffb5`.
**Note that mlflow-server is not yet available on unstable as of 2020/01/09 (prob will be in a couple weeks).**
(one time):
```
nixops create ./mlflow-server.nix ./mlflow-server-ec2.nix -d mlflow-server-ec2
```

Then to (re)deploy with latest config:
```
nixops deploy -d mlflow-server-ec2
```
