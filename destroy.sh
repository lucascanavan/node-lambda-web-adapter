#!/bin/bash
cd ./terraform
terraform destroy --var-file=vars.tfvars -auto-approve
