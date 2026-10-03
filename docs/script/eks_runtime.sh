#!/usr/bin/env bash

set -e

#this create the eks cluster first
echo "=== applying eks cluster terraform ==="
cd terraform/eks_cluster
terraform apply -auto-approve

#this create all the add-ons and node group
echo "=== applying eks runtime terraform ==="
cd ../eks_runtime
terraform apply -auto-approve

#this cupdate kube-config to point at newly created cluster
echo "=== updating kube config file ==="
aws eks update-kubeconfig --name devops-lab-eks --region eu-west-2

#this deploy system and app manifest
echo "=== deploying system apps ==="
cd ../../eks-lab-manifest
kubectl apply -f ./01_system
echo "=== deploying application ==="
kubectl apply -f ./02_app
echo "=== deploying aload balancer ==="
kubectl apply -f ./04_alb

echo "=== eks-lab start up successfully ==="