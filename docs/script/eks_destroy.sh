#!/usr/bin/env bash

set -e 

echo "=== destroying node group and add-ons ==="
cd ./terraform/eks_runtime
terraform destroy -auto-approve

echo "=== destroying cluster ==="
cd ../eks_cluster
terraform destroy -auto-approve