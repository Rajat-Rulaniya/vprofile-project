# vProfile — DevOps & Cloud Project Portfolio

> **7 real-world DevOps projects** built around a Java web application — each in its own branch, each demonstrating a different CI/CD, Infrastructure as Code, or Container Orchestration approach on AWS.

![Jenkins](https://img.shields.io/badge/Jenkins-D24939?style=flat&logo=jenkins&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-844FBA?style=flat&logo=terraform&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=flat&logo=kubernetes&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-232F3E?style=flat&logo=amazonwebservices&logoColor=white)
![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=flat&logo=ansible&logoColor=white)
![SonarQube](https://img.shields.io/badge/SonarQube-4E9BCD?style=flat&logo=sonarqube&logoColor=white)
![Nexus](https://img.shields.io/badge/Nexus-1B1C30?style=flat&logo=sonatype&logoColor=white)

---

## How This Repo Is Organized

This repository uses **branches as projects**. Each branch contains a complete, self-contained DevOps implementation for the same Java application — making it easy to compare approaches side by side.

```
main                  ← You are here (project index)
├── cicd-jenkins       ← Jenkins CI/CD → Docker → ECR → ECS
├── cicd-jenkiAns      ← Jenkins CI → Nexus → Ansible CD
├── jenkins-hybd-prod  ← Jenkins → S3 → Elastic Beanstalk
├── terraform-project  ← Terraform: VPC + EB + RDS + ElastiCache + MQ
├── terraform-eks      ← Terraform: VPC + EKS Cluster
├── kubeapp            ← Kubernetes Manifests (full-stack)
└── ci-aws / cd-aws    ← AWS CodeBuild + CodeArtifact + SonarCloud
```

---

## Projects at a Glance

| # | Project | Branch | Tools & Services |
|:--|:--------|:-------|:-----------------|
| 1 | [Jenkins CI/CD → ECS](#1-jenkins-cicd--docker--ecs) | [`cicd-jenkins`](../../tree/cicd-jenkins) | Jenkins · Docker · ECR · ECS · SonarQube · Nexus · Slack |
| 2 | [Jenkins + Ansible CD](#2-jenkins-ci--ansible-cd) | [`cicd-jenkiAns`](../../tree/cicd-jenkiAns) | Jenkins · Ansible · Nexus · SonarQube · Slack |
| 3 | [Jenkins → Elastic Beanstalk](#3-jenkins--s3--elastic-beanstalk) | [`jenkins-hybd-prod`](../../tree/jenkins-hybd-prod) | Jenkins · S3 · Elastic Beanstalk · SonarQube · Nexus · Slack |
| 4 | [Terraform AWS Infrastructure](#4-terraform-aws-infrastructure) | [`terraform-project`](../../tree/terraform-project) | Terraform · VPC · RDS · ElastiCache · Amazon MQ · Elastic Beanstalk |
| 5 | [Terraform EKS Cluster](#5-terraform-eks-cluster) | [`terraform-eks`](../../tree/terraform-eks) | Terraform · EKS · VPC · S3 Backend |
| 6 | [Kubernetes App Deployment](#6-kubernetes-app-deployment) | [`kubeapp`](../../tree/kubeapp) | Kubernetes · NGINX Ingress · PVC · Secrets |
| 7 | [AWS-Native CI/CD](#7-aws-native-cicd) | [`ci-aws`](../../tree/ci-aws) / [`cd-aws`](../../tree/cd-aws) | CodeBuild · CodeArtifact · SonarCloud · Parameter Store |

---

## 1. Jenkins CI/CD → Docker → ECS

**Branch:** [`cicd-jenkins`](../../tree/cicd-jenkins)

End-to-end containerized CI/CD pipeline with separate staging and production deployments on AWS ECS.

```
Code Push → Jenkins → Build → Test → SonarQube → Quality Gate
         → Docker Build → Push to ECR → Deploy to ECS Staging
         → (Manual Trigger) → Deploy to ECS Production
         → Slack Notification
```

**Pipeline Stages:**

| Stage | What Happens |
|:------|:-------------|
| Build & Test | Maven build, unit tests, integration tests, Checkstyle |
| Code Quality | SonarQube analysis with quality gate enforcement (aborts on failure) |
| Containerize | Docker image built, tagged with build number, pushed to ECR Public |
| Deploy Staging | `aws ecs update-service --force-new-deployment` on staging cluster |
| Deploy Prod | Separate pipeline triggers production ECS deployment |
| Notify | Slack notifications on image upload and deployment status |

**Key Details:**
- **Registry:** ECR Public (`public.ecr.aws`)
- **ECS Clusters:** `vproapp-staging` / `vproapp-prod`
- **Dockerfile:** Tomcat 9 on JDK 11, WAR deployed as ROOT.war
- **Image Cleanup:** Keeps only last 2 images on build agent

---

## 2. Jenkins CI + Ansible CD

**Branch:** [`cicd-jenkiAns`](../../tree/cicd-jenkiAns)

Jenkins handles CI (build, test, quality checks, artifact upload), then Ansible takes over for deployment to Tomcat servers — with **automated rollback** on failure.

```
Code Push → Jenkins → Build → Test → SonarQube → Quality Gate
         → Upload WAR to Nexus → Save Build Version
         → Ansible Deploy to Staging Tomcat
         → (Manual Trigger) → Ansible Deploy to Production Tomcat
```

**Pipeline Stages:**

| Stage | What Happens |
|:------|:-------------|
| Build & Test | Maven build, unit tests, Checkstyle |
| Code Quality | SonarQube analysis with quality gate |
| Artifact Store | WAR uploaded to Nexus (versioned by build ID + timestamp) |
| Deploy Staging | Ansible playbook runs against staging inventory |
| Deploy Prod | Separate pipeline reads saved build version, deploys to prod |

**Ansible Deployment Workflow:**
1. Downloads versioned WAR from Nexus (authenticated)
2. Stops Tomcat service
3. Archives current `ROOT` directory with timestamp
4. Creates backup copy as `old_ROOT`
5. Deploys new WAR
6. **On failure:** `block/rescue` restores `old_ROOT` automatically

**Key Details:**
- **Inventories:** Separate `stage.inventory` and `prod.inventory`
- **Credentials:** Staging (`applogin`) and Production (`applogin-prod`) SSH credentials
- **Nexus extraVars:** URL, credentials, group ID, build version — all passed dynamically

---

## 3. Jenkins → S3 → Elastic Beanstalk

**Branch:** [`jenkins-hybd-prod`](../../tree/jenkins-hybd-prod)

Hybrid CI/CD using Jenkins for build orchestration with S3 as the artifact store and Elastic Beanstalk for managed application hosting — staged deployments from staging to production.

```
Code Push → Jenkins → Build → Test → SonarQube → Quality Gate
         → Upload WAR to S3 → Create EB App Version
         → Deploy to EB Staging Environment
         → (Manual Trigger) → Deploy to EB Production Environment
```

**Pipeline Stages:**

| Stage | What Happens |
|:------|:-------------|
| Build & Test | Maven build (WAR renamed with build ID + timestamp), tests, Checkstyle |
| Code Quality | SonarQube analysis with quality gate |
| Artifact Upload | WAR uploaded to S3 bucket (`rajat-blog-app-artifacts`) |
| Save Version | Build version written to Jenkins filesystem for prod pipeline |
| Deploy Staging | `aws elasticbeanstalk create-application-version` + `update-environment` |
| Deploy Prod | Reads saved version, updates production EB environment |

**Key Details:**
- **EB Application:** `vproapp`
- **Environments:** `Vproapp-staging-env` / `Vproapp-prod-env`
- **Artifact Path:** `s3://rajat-blog-app-artifacts/java-app/`
- **Version Passing:** Build version persisted to `/var/lib/jenkins/vprofileBuildVersion.txt`, read by prod pipeline

---

## 4. Terraform AWS Infrastructure

**Branch:** [`terraform-project`](../../tree/terraform-project)

Complete AWS infrastructure provisioned via Terraform — a 3-tier VPC hosting the full application stack on managed services with Elastic Beanstalk as the compute layer.

**Resources Provisioned:**

| Resource | Configuration |
|:---------|:-------------|
| **VPC** | 3 AZs, 3 public + 3 private subnets, NAT Gateway, DNS hostnames |
| **Elastic Beanstalk** | Tomcat 10 / Corretto 21, autoscaling 1–8, rolling deployment, enhanced health |
| **RDS** | MySQL 8.0.39, db.t4g.micro, gp3 storage, private subnet |
| **ElastiCache** | Memcached, cache.t3.micro, 1 node, private subnet |
| **Amazon MQ** | RabbitMQ 3.13, mq.t3.micro, single-instance |
| **Bastion Host** | Ubuntu 22.04, t3.micro, remote-exec provisioner initializes RDS schema |
| **Security Groups** | 4 groups — ALB, Bastion, Beanstalk instances, Backend services |

**Key Details:**
- **State Backend:** S3 (`terraformstate32456`)
- **DB Initialization:** Bastion uses `templatefile()` to inject RDS endpoint into deploy script, then runs `remote-exec` to import SQL schema
- **IMDSv2:** Enforced on all Beanstalk instances

---

## 5. Terraform EKS Cluster

**Branch:** [`terraform-eks`](../../tree/terraform-eks)

Kubernetes cluster on AWS provisioned entirely through Terraform — VPC with proper K8s subnet tagging and EKS with managed node groups.

**Resources Provisioned:**

| Resource | Configuration |
|:---------|:-------------|
| **VPC** | CIDR 172.20.0.0/16, 3 AZs, 3 public + 3 private subnets, NAT Gateway |
| **Subnet Tags** | `kubernetes.io/role/elb` (public) · `kubernetes.io/role/internal-elb` (private) |
| **EKS Cluster** | Kubernetes 1.27, public endpoint, nodes in private subnets |
| **Node Group 1** | t3.small, min 1 / max 3 / desired 2 (AL2 x86_64) |
| **Node Group 2** | t3.small, min 1 / max 2 / desired 1 (AL2 x86_64) |

**Key Details:**
- **State Backend:** S3 (`terra-eks12`)
- **Cluster Name:** `vpro-eks`
- **Outputs:** Cluster name, endpoint, region, security group ID
- **Modules:** `terraform-aws-modules/vpc` v3.14.2, `terraform-aws-modules/eks` v19.0.4

---

## 6. Kubernetes App Deployment

**Branch:** [`kubeapp`](../../tree/kubeapp)

Full application stack deployed on Kubernetes using declarative manifests — 4 microservice-style deployments with ClusterIP networking, NGINX Ingress, persistent storage, and secrets management.

**Manifests:**

| Resource | Name | Details |
|:---------|:-----|:--------|
| Deployment | `vproapp` | Tomcat app, port 8080, initContainers wait for DB + cache DNS |
| Deployment | `vprodb` | MySQL, port 3306, PVC for data, password from Secret |
| Deployment | `vpromc` | Memcached, port 11211 |
| Deployment | `vpromq01` | RabbitMQ, port 5672, credentials from Secret |
| Service (×4) | ClusterIP | Internal-only services for all components |
| Ingress | `vpro-ingress` | NGINX Ingress class, host-based routing |
| PVC | `db-pv-claim` | 3Gi, ReadWriteOnce for MySQL persistence |
| Secret | `app-secret` | DB and RabbitMQ passwords (base64) |

**Key Details:**
- **InitContainers:** App pod waits for `vprodb` and `vprocache01` DNS resolution before starting
- **Ingress Controller:** NGINX with host-based routing
- **Persistence:** MySQL data survives pod restarts via PVC
- Designed to run on the EKS cluster from [Project 5](#5-terraform-eks-cluster)

---

## 7. AWS-Native CI/CD

**Branches:** [`ci-aws`](../../tree/ci-aws) (CI) / [`cd-aws`](../../tree/cd-aws) (CI + CD)

Fully AWS-managed CI/CD pipeline — no Jenkins. Uses CodeBuild for build and analysis, CodeArtifact for dependency management, SonarCloud for quality gates, and Parameter Store for secrets.

```
Code Push → CodePipeline → CodeBuild (Build) → CodeBuild (SonarCloud Analysis)
         → CodeBuild (Build & Release) → Deploy to Elastic Beanstalk
```

**Build Specs:**

| Buildspec | Purpose |
|:----------|:--------|
| `build_buildspec.yml` | Maven build with CodeArtifact auth, produces WAR artifact |
| `sonar_buildspec.yml` | Runs tests, Checkstyle, SonarCloud analysis, quality gate check |
| `buildAndRelease_buildspec.yml` | Injects RDS endpoint from Parameter Store via `sed`, builds release WAR |
| `buildAndStore_buildspec.yml` | Injects all backend endpoints (RDS, Memcached, Amazon MQ) from Parameter Store |

**Key Details:**
- **Dependency Management:** AWS CodeArtifact (replaces Nexus)
- **Code Quality:** SonarCloud with programmatic quality gate check (`curl` API + `jq`)
- **Secrets:** AWS Systems Manager Parameter Store for RDS credentials, Memcached URL, RabbitMQ host/user/pass
- **Runtime:** Java Corretto 17

---

## About the Application

All projects use the same underlying Java application — a Spring MVC web app with:
- **MySQL** — User and account data
- **Memcached** — Database query caching
- **RabbitMQ** — Message queuing
- **Tomcat** — Application server
- **Nginx** — Reverse proxy (in containerized/VM setups)

The application code itself is not the focus — it serves as a realistic multi-tier workload to demonstrate various DevOps and Cloud Engineering practices.

---

## Quick Start

```bash
# Switch to any project branch
git checkout cicd-jenkins        # Jenkins → Docker → ECS
git checkout cicd-jenkiAns       # Jenkins → Ansible CD
git checkout jenkins-hybd-prod   # Jenkins → Elastic Beanstalk
git checkout terraform-project   # Terraform AWS Infra
git checkout terraform-eks       # Terraform EKS
git checkout kubeapp             # Kubernetes Manifests
git checkout ci-aws              # AWS CodeBuild CI
git checkout cd-aws              # AWS CodeBuild CI/CD
```

Each branch has its own set of configuration files specific to that project's tooling. Refer to the branch contents for detailed setup.
