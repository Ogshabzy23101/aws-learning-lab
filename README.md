# AWS DevOps Learning Lab

A hands-on DevOps learning repository focused on AWS, Terraform, Kubernetes, Amazon EKS, IAM, autoscaling, persistent storage, troubleshooting, and production-style infrastructure practices.
The purpose of this repository is not only to deploy working infrastructure, but to understand how the components interact, deliberately troubleshoot failures, and document practical DevOps experience.

---

## Current Architecture

The lab currently uses:

- AWS VPC with public and private subnets
- Amazon EKS
- Managed EKS node groups
- NAT Gateway for private worker-node outbound access
- Amazon ECR
- Terraform
- Kubernetes manifests
- EKS Pod Identity
- Cluster Autoscaler
- Metrics Server
- Horizontal Pod Autoscaler
- Amazon EBS CSI Driver
- gp3 persistent storage
- IAM roles and least-privilege policies

---

## Repository Structure

```text
aws-learning-lab/
├── docs/
│   └── policies/
│       ├── cluster-autoscaler-policy.json
│       ├── cluster-autoscaler-trust.json
│       └── ebs_csi_trustpolicy.json
│
├── eks-lab-manifest/
│   ├── 01_platform/
│   │   ├── cluster-autoscaler/
│   │   └── storage/
│   │
│   ├── 02_app/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── hpa.yaml
│   │   └── pvc.yaml
│   │
│   └── 03_test/
│       ├── testpod.yaml
│       └── testpod_sa.yaml
│
├── terraform/
│   ├── bootstrap/
│   ├── eks_cluster/
│   ├── eks_runtime/
│   └── ebs_csi/
│
├── .gitignore
└── README.md

The structure separates AWS infrastructure, Kubernetes platform resources, application resources, and temporary test workloads.

⸻

Progress

1. Terraform Remote State

Configured Terraform remote-state storage using Amazon S3.

Terraform state, variable files, local backend configuration, and .terraform directories are excluded from Git where appropriate.

This provides a safer and more reproducible infrastructure workflow.

⸻

2. EKS Cluster Provisioning

Amazon EKS is provisioned using Terraform.

The cluster configuration includes:

* EKS control plane
* private subnets
* IAM cluster role
* EKS API authentication
* EKS access entries for administrator access
* VPC CNI
* kube-proxy
* EKS Pod Identity Agent

The Kubernetes kubeconfig is generated after cluster creation using:

aws eks update-kubeconfig

Cluster access is then verified with kubectl.

Troubleshooting performed

After recreating the cluster with Terraform, kubectl returned:

You must be logged in to the server

The cluster API endpoint was reachable, but the IAM user had not been granted access to the new cluster.

The problem was resolved by creating:

* an EKS access entry
* an EKS cluster access policy association

This demonstrated the separation between:

AWS IAM identity
→ EKS access entry
→ EKS access policy / Kubernetes permissions

⸻

3. Cost-Controlled EKS Runtime

Expensive runtime resources are separated from the EKS cluster configuration.

Terraform provisions resources such as:

* Elastic IP
* NAT Gateway
* private route
* EKS managed node group

This allows the lab runtime to be created only when needed and destroyed after study sessions.

The intended workflow is:

terraform apply
→ practise
→ troubleshoot
→ terraform destroy

IAM roles and other inexpensive reusable resources may remain outside the temporary runtime lifecycle.

⸻

4. Kubernetes Application Deployment

A test application has been deployed to EKS using Kubernetes manifests.

The application configuration includes:

* Deployment
* Service
* CPU requests and limits
* memory requests and limits
* readiness probes
* liveness probes

Practical troubleshooting included diagnosing failed probes caused by using the wrong application port.

The investigation used:

kubectl get
kubectl describe
kubectl logs
kubectl logs --previous
kubectl rollout status

⸻

5. Metrics Server and Resource Monitoring

Metrics Server is installed in the cluster.

Resource usage has been inspected using:

kubectl top nodes
kubectl top pods

This was used to compare:

* requested resources
* resource limits
* actual CPU usage
* actual memory usage

⸻

6. Horizontal Pod Autoscaler

Horizontal Pod Autoscaler has been configured for the application.

HPA scales application Pods based on CPU utilisation relative to the CPU request.

The practical relationship demonstrated was:

application load
→ CPU utilisation increases
→ HPA increases replicas

A key lesson was that HPA scales Pods, not worker nodes.

⸻

7. Cluster Autoscaler

Cluster Autoscaler was installed to scale the EKS managed node group.

The node group is configured with minimum, desired, and maximum capacity.

Cluster Autoscaler uses node-group tags to discover the Auto Scaling Group.

IAM integration

Cluster Autoscaler uses:

cluster-autoscaler Pod
→ Kubernetes ServiceAccount
→ EKS Pod Identity
→ IAM role
→ Auto Scaling permissions

RBAC troubleshooting

Initial Cluster Autoscaler deployment produced multiple Kubernetes Forbidden errors.

The ServiceAccount was authenticated successfully but lacked permission to list and watch required Kubernetes resources.

RBAC permissions were corrected for resources including:

* nodes
* Pods
* replication controllers
* Jobs
* storage resources
* resource claims
* volume attachments

Pod Identity troubleshooting

Cluster Autoscaler later entered CrashLoopBackOff.

Investigation showed that its ServiceAccount had no Pod Identity association.

The missing association was created between:

cluster-autoscaler-sa
→ Cluster Autoscaler IAM role

After correcting the association, Cluster Autoscaler became healthy.

Autoscaling result

The node group successfully scaled from:

1 worker node
→ 2 worker nodes

after unschedulable Pods required additional capacity.

This demonstrated:

Pending Pod
→ Cluster Autoscaler detects scheduling failure
→ ASG desired capacity increases
→ new EC2 worker launches
→ worker joins EKS
→ scheduler places Pending Pods

Terraform ignores changes to desired_size so Terraform does not fight Cluster Autoscaler.

⸻

8. Node Maintenance

Practical node-maintenance operations were tested.

Cordon

A node was marked:

SchedulingDisabled

Existing Pods continued running, but new workloads were prevented from being scheduled on the node.

Drain

The node was drained using Kubernetes eviction.

During the drain, PodDisruptionBudgets temporarily prevented some CoreDNS and Metrics Server Pods from being evicted until sufficient replicas were available elsewhere.

This demonstrated how Kubernetes protects application availability during voluntary disruptions.

Uncordon

The node was returned to normal scheduling after maintenance.

⸻

9. Amazon EBS CSI Driver

The Amazon EBS CSI Driver has been installed as an EKS add-on.

The CSI controller uses:

ebs-csi-controller-sa
→ EKS Pod Identity
→ EBS CSI IAM role
→ AWS EBS API

The IAM role uses a Pod Identity trust policy with:

pods.eks.amazonaws.com

and an AWS-managed EBS CSI permissions policy.

The CSI controller and CSI node Pods were verified as healthy.

⸻

10. StorageClass and Dynamic EBS Provisioning

A gp3 StorageClass was created using the standard EBS CSI provisioner:

ebs.csi.aws.com

The StorageClass uses:

WaitForFirstConsumer

so the EBS volume is created only after Kubernetes knows which worker node and Availability Zone will consume the volume.

⸻

11. PersistentVolumeClaim and Persistent Storage

A PersistentVolumeClaim was created requesting:

1 GiB gp3 storage

Before a Pod consumed the claim, the PVC remained:

Pending

After a Pod referenced the PVC:

PVC
→ StorageClass
→ EBS CSI
→ AWS EBS volume
→ PersistentVolume
→ Bound PVC

The Pod successfully mounted the volume.

⸻

12. EBS Persistence Test

A file was written inside the mounted EBS volume.

The test Pod was then deleted.

The PVC and EBS-backed PersistentVolume remained.

A new Pod was created using the same PVC.

The original file was successfully read from the recreated Pod.

This demonstrated:

Pod is temporary
PersistentVolume is independent
EBS volume survives Pod replacement
data remains available

⸻

13. Application Pod Identity

A separate Kubernetes ServiceAccount was created for a test application workload:

testpod-sa

The ServiceAccount was associated with an IAM role using EKS Pod Identity.

The Pod was configured with:

serviceAccountName: testpod-sa

Inside the Pod:

aws sts get-caller-identity

returned an assumed-role identity for the application IAM role.

This proved that the workload was receiving temporary AWS credentials without storing static access keys inside the container.

The identity chain was:

Pod
→ testpod-sa
→ EKS Pod Identity association
→ IAM role
→ STS temporary credentials

⸻

14. Least-Privilege IAM Test

The application IAM role was restricted to a specific S3 bucket.

From inside the Pod:

aws s3 ls

was denied because the role did not have:

s3:ListAllMyBuckets

However:

aws s3 ls s3://<allowed-bucket>

succeeded.

This demonstrated practical least privilege:

account-wide S3 listing
→ denied
authorised bucket access
→ allowed

⸻

Troubleshooting Experience

The lab has included real troubleshooting rather than only successful deployments.

Issues investigated so far include:

* EKS worker nodes failing to join the cluster
* missing NAT connectivity for private worker nodes
* Kubernetes Pods remaining Pending
* insufficient node capacity
* maximum Pod capacity
* readiness probe failures
* liveness probe failures
* incorrect application ports
* Kubernetes RBAC Forbidden errors
* missing EKS access entries
* Cluster Autoscaler CrashLoopBackOff
* missing Pod Identity association
* CoreDNS add-on degradation before worker nodes existed
* Metrics Server add-on configuration
* EBS CSI IAM integration
* PVC lifecycle and dynamic EBS provisioning

The general troubleshooting workflow used is:

observe symptom
→ inspect resource
→ check events
→ inspect logs
→ identify failing layer
→ verify permissions/network/configuration
→ fix
→ validate

⸻

Git and Documentation Workflow

The repository is now version-controlled with Git and hosted on GitHub.

Changes are committed in logical units such as:

chore: initialize AWS DevOps learning repo
feat: add Terraform infrastructure for EKS lab
feat: add Kubernetes manifests for EKS lab
feat: add policy docs for IAM infrastructure

The workflow used is:

git status
git diff
git add <specific-files>
git diff --staged
git commit
git push


Sensitive Terraform state, variable files, credentials, backend configuration and local working directories are excluded through .gitignore.

⸻

Cost Management

Cost Explorer was used to identify high-cost lab resources.

Major sources included:

* EKS control plane
* RDS
* EC2-related resources
* VPC resources

The lab is being redesigned so expensive infrastructure is provisioned only when needed.

The long-term goal is:

Permanent / low-cost
--------------------
Git repository
ECR images
S3 Terraform backend
selected IAM roles
Temporary
---------
EKS cluster
worker nodes
NAT Gateway
RDS
ALB
EBS lab resources
other billable infrastructure

⸻

Current Skills Demonstrated

This lab currently provides practical evidence of:

* AWS networking
* Amazon EKS
* Kubernetes workloads
* Terraform
* IAM
* EKS Pod Identity
* Kubernetes RBAC
* ECR
* autoscaling
* HPA
* Cluster Autoscaler
* EBS CSI
* PersistentVolumes
* PersistentVolumeClaims
* StorageClasses
* node maintenance
* resource requests and limits
* troubleshooting
* least-privilege access
* Git workflows
* cloud cost awareness

⸻

Next Topics

Planned next areas include:

* AWS Load Balancer Controller
* ALB-backed Kubernetes Ingress
* application exposure through AWS load balancing
* ALB health checks and target troubleshooting
* deeper EKS observability
* CloudWatch integration
* additional live failure scenarios
* Kubernetes NetworkPolicies
* PodDisruptionBudget practical work
* EKS interview scenarios
* deeper Terraform production patterns
* integration with the Phone Store project

```

## 15. AWS Load Balancer Controller and ALB Ingress

The AWS Load Balancer Controller was installed to allow Kubernetes Ingress resources to provision and manage AWS Application Load Balancers.
The controller was installed using Helm.
The IAM integration used EKS Pod Identity rather than IRSA/OIDC.

### IAM setup

A dedicated IAM policy was created from the official AWS Load Balancer Controller IAM policy document.
A dedicated IAM role was created for the controller:

```text
devops-lab-alb-controller-role

The role trust policy allows:

pods.eks.amazonaws.com

with:

sts:AssumeRole
sts:TagSession

The controller IAM policy was attached to the role.

ServiceAccount

A Kubernetes ServiceAccount was created:

Name: aws-load-balancer-controller
Namespace: kube-system

The ServiceAccount was intentionally created separately rather than allowing Helm to create it.

EKS Pod Identity association

A Pod Identity association was created:

devops-lab-eks
→ kube-system
→ aws-load-balancer-controller
→ devops-lab-alb-controller-role

This allows the controller Pods to obtain temporary AWS credentials without storing static credentials or using an OIDC-based IRSA setup.


16. AWS Load Balancer Controller Helm Installation

The AWS Load Balancer Controller Helm chart was installed from:

eks/aws-load-balancer-controller

The installation reused the existing ServiceAccount rather than creating a new one.

The initial Helm configuration included:

clusterName = devops-lab-eks
serviceAccount.create = false
serviceAccount.name = aws-load-balancer-controller

Controller startup failure

After installation, both controller Pods entered:

CrashLoopBackOff

Controller logs showed:

unable to initialize AWS cloud
failed to get VPC ID
failed to fetch VPC ID from instance metadata
context deadline exceeded

The controller was attempting to discover the VPC through EC2 Instance Metadata Service.

Because metadata access was not available to the controller Pods, the VPC could not be detected automatically.

The Helm release was upgraded to explicitly provide:

region = eu-west-2
vpcId = <devops-lab-vpc-id>

After the Helm upgrade, new controller Pods started successfully and remained:

1/1 Running
0 restarts

This demonstrated the troubleshooting process:

CrashLoopBackOff
→ inspect controller logs
→ identify VPC discovery failure
→ recognise IMDS dependency
→ explicitly configure region and VPC ID
→ Helm upgrade
→ controller recovered

17. Kubernetes Service Troubleshooting

Before creating the Ingress, the application Service was inspected.

The Service was configured as:

Type: ClusterIP
Port: 80
TargetPort: 5173

Initially the Service showed:

Endpoints: <none>

The issue was traced to an incorrect Service selector.

A Deployment selector uses:

selector
→ matchLabels

while a Kubernetes Service selector uses direct label key/value mappings.
selector
  app: <app-name>

instead of 

selector
  matchLabel

After correcting the Service selector, the Service successfully discovered both application Pods.

Example endpoint result:

10.0.3.x:5173
10.0.3.x:5173

This confirmed:

Service :80
→ application Pods :5173

before the Ingress was introduced.

18. ALB Ingress

A Kubernetes Ingress was created using:

apiVersion: networking.k8s.io/v1
IngressClass: alb

The ALB configuration used:

scheme = internet-facing
target-type = ip
healthcheck-path = /
listen-port = HTTP 80

The backend routed:

/
→ devops-lab-service :80

The path type used was:

Prefix

This allows the root path and routes beneath it to be matched.

Target type

The Ingress uses:

target-type: ip

This means the AWS ALB registers Kubernetes Pod IP addresses directly in the target group.

The resulting traffic model is:

Internet
→ ALB :80
→ Kubernetes Ingress
→ devops-lab-service :80
→ application Pods :5173

This differs from instance target mode, where traffic would first reach the worker node through a NodePort.


19. Ingress Validation and API Troubleshooting

The Ingress manifest was validated before application.

Client-side dry-run initially passed some syntax but later server-side application exposed additional issues.

Problems corrected included:

Metadata
→ metadata

because Kubernetes field names are case-sensitive.

The resource kind also required:

Ingress

rather than:

ingress

The ALB annotations also required proper YAML key/value syntax using:

:

rather than:

=

The listener configuration was stored as an annotation string.

The distinction between validation modes was reinforced:

kubectl apply --dry-run=client

validates locally, while:

kubectl apply --dry-run=server

also validates the resource against the Kubernetes API server.


20. ALB Provisioning

After applying the Ingress, the AWS Load Balancer Controller successfully reconciled it.

The Ingress received a public AWS ALB DNS address.

The Ingress description showed:

Ingress Class: alb
Backend:
devops-lab-service:80
Targets:
Pod IPs on port 5173

Events showed:

SuccessfullyReconciled

This confirmed that the controller successfully created and configured the AWS ALB resources.


21. End-to-End ALB Troubleshooting

The ALB initially returned an application response containing:

Blocked request.
This host (...) is not allowed.

This was not an AWS networking failure.

The response proved the request had successfully travelled through:

Internet
→ ALB
→ Ingress
→ Service
→ Pod

The rejection occurred inside the application.

Root cause

The demo image was running the Vite development server:

npm run dev --host 0.0.0.0

on:

port 5173

The Vite configuration did not allow the ALB DNS hostname.

The running process was confirmed from inside the Pod.

The container also contained:

Dockerfile.dev
Dockerfile.prod
nginx.conf
vite.config.js

but the active workload was using the Vite development server, not Nginx.

Temporary lab fix

Because the image was only a disposable demo image, the running Pod configuration was temporarily modified to allow the ALB hostname.

After updating the Vite host configuration, the application became accessible from the browser through the public ALB.

This modification was intentionally treated as temporary because changes made directly inside a running Pod disappear when that Pod is recreated.

The production lesson is:

application configuration
→ source repository
→ Docker image
→ registry
→ Kubernetes Deployment

rather than manually editing running containers.

22. ALB Lab Outcome

The complete ALB path was successfully demonstrated:

Browser
→ internet-facing Application Load Balancer
→ Kubernetes Ingress
→ ClusterIP Service
→ Pod IP
→ Vite application

The lab demonstrated practical experience with:

* AWS Load Balancer Controller
* Helm
* EKS Pod Identity
* IAM role trust relationships
* ALB provisioning
* Kubernetes Ingress
* ClusterIP Services
* direct Pod IP target registration
* health checks
* VPC discovery
* controller logs
* CrashLoopBackOff troubleshooting
* Kubernetes Service selectors
* server-side manifest validation
* application-level HTTP host validation

Troubleshooting cases completed

The ALB exercise included multiple real failures:

1. Controller CrashLoopBackOff
   → VPC discovery through IMDS failed
   → explicit region and VPC ID fixed the controller
2. Service had no endpoints
   → incorrect Service selector
   → selector corrected
   → Pod endpoints discovered
3. Ingress manifest errors
   → case-sensitive Kubernetes fields
   → incorrect resource kind
   → annotation syntax corrected
4. ALB worked but application rejected request
   → Vite Host validation
   → temporary application configuration fix

This exercise demonstrated an important troubleshooting principle:

Do not assume every failed browser request is a load balancer problem.
Trace the request layer by layer:
ALB
→ Ingress
→ Service
→ Endpoints
→ Pod
→ application

Current EKS Practical Progress

Completed practical areas now include:

* EKS cluster provisioning
* EKS access entries
* managed node groups
* private worker networking
* NAT Gateway runtime networking
* Metrics Server
* HPA
* Cluster Autoscaler
* Pod scheduling under pressure
* cordon
* drain
* PodDisruptionBudget behaviour
* EBS CSI Driver
* StorageClass
* PVC and PV
* persistent EBS storage
* application Pod Identity
* least-privilege IAM testing
* AWS Load Balancer Controller
* ALB Ingress
* end-to-end external application access
* controller and application troubleshooting

Next Topic

The next major EKS topic is observability.

Planned work includes:

EKS control-plane logging
→ CloudWatch
→ node/container metrics
→ application logs
→ cluster events
→ incident investigation
```
