# auto-register-aws-ec2-in-route53

## Prerequisites

- Node.js
- Terraform

## Architecture

![img](./docs/architecture.png)

## Installation

```
export TF_VAR_zone_name=demo.com
export TF_VAR_instance_id=i-xxxxxxxxx
export TF_VAR_instance_alias=host

yarn start
```
