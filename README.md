# Auto Register AWS EC2 Public IP in Route53

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

yarn install
yarn start
```
