# Terraform Contract

이 문서는 MSA 서비스가 공통으로 따라야 하는 Terraform 구조 기준이다.

## 적용 대상
| Logical service | Repository | Terraform role |
| --- | --- | --- |
| `user-service` | `user-service` | 일반 backend app service |
| `auth-service` | `auth-service` | 일반 backend app service |
| `gateway-server` | `gateway-service` | public entrypoint / gateway service |
| `authz-service` | `authz-service` | 일반 backend app service |
| `editor-service` | `editor-service` | 일반 backend app service |
| `monitor-server` | `monitoring-service` | observability service |
| `redis-service` | `redis-service` | stateful cache/session store |

## 원칙
- Terraform은 서비스별 복사본을 늘리지 않고 공통 모듈을 기준으로 관리한다.
- 환경별 live configuration은 `dev`, `prod`처럼 분리한다.
- shared infrastructure와 service infrastructure는 state를 분리한다.
- 서비스별 차이는 Terraform 코드 복사가 아니라 변수로 표현한다.
- 모든 서비스를 하나의 모듈에 억지로 넣지 않고 역할별 모듈로 나눈다.
- 네이밍, tag, backend, remote state 기준은 모든 서비스가 동일하게 따른다.

## 표준 디렉토리
```text
infra/
  modules/
    app-service/
      main.tf
      variables.tf
      outputs.tf

    gateway-service/
      main.tf
      variables.tf
      outputs.tf

    monitoring/
      main.tf
      variables.tf
      outputs.tf

    redis/
      main.tf
      variables.tf
      outputs.tf

    shared-network/
      main.tf
      variables.tf
      outputs.tf

    shared-observability/
      main.tf
      variables.tf
      outputs.tf

  envs/
    dev/
      shared/
        main.tf
        backend.tf
        terraform.tfvars

      services/
        main.tf
        backend.tf
        services.tfvars

    prod/
      shared/
        main.tf
        backend.tf
        terraform.tfvars

      services/
        main.tf
        backend.tf
        services.tfvars
```

## 모듈 분류
| Module | 대상 | 설명 |
| --- | --- | --- |
| `app-service` | `user-service`, `auth-service`, `authz-service`, `editor-service` | 공통 backend application 배포 단위 |
| `gateway-service` | `gateway-server` | 외부 진입점, public listener/routing, edge policy |
| `monitoring` | `monitor-server` | Prometheus/Grafana/Loki/collector 등 관측 리소스 |
| `redis` | `redis-service` | Redis cache/session 저장 계층 |
| `shared-network` | 전체 | VPC, subnet, routing, NAT, 공통 security boundary |
| `shared-observability` | 전체 | 공통 log, metric, alarm, dashboard 기준 |

## App service 입력 기준
`app-service` 모듈은 backend application 서비스가 공유하는 최소 입력을 받는다.

```hcl
variable "env" {}
variable "service_name" {}
variable "image" {}
variable "port" {}
variable "cpu" {}
variable "memory" {}
variable "desired_count" {}
variable "health_check_path" {}

variable "env_vars" {
  type    = map(string)
  default = {}
}

variable "secrets" {
  type    = map(string)
  default = {}
}
```

`app-service` 모듈은 아래 리소스를 한 서비스 단위로 생성한다.

| Resource group | 설명 |
| --- | --- |
| service runtime | ECS service/task, container definition 또는 동등한 실행 단위 |
| IAM | task role, execution role, service-specific policy |
| network | service security group, target group attachment |
| logging | service log group, retention |
| scaling | autoscaling target/policy |
| health | health check path, readiness 기준 |

## 서비스 선언 방식
일반 backend application은 서비스 목록을 map으로 선언하고 `for_each`로 `app-service`를 호출한다.

```hcl
locals {
  app_services = {
    user-service = {
      port              = 8081
      cpu               = 512
      memory            = 1024
      desired_count     = 1
      health_check_path = "/actuator/health"
    }

    auth-service = {
      port              = 8082
      cpu               = 512
      memory            = 1024
      desired_count     = 1
      health_check_path = "/actuator/health"
    }

    authz-service = {
      port              = 8083
      cpu               = 512
      memory            = 1024
      desired_count     = 1
      health_check_path = "/actuator/health"
    }

    editor-service = {
      port              = 8084
      cpu               = 512
      memory            = 1024
      desired_count     = 1
      health_check_path = "/actuator/health"
    }
  }
}

module "app_services" {
  for_each = local.app_services

  source = "../../../modules/app-service"

  env               = var.env
  service_name      = each.key
  port              = each.value.port
  cpu               = each.value.cpu
  memory            = each.value.memory
  desired_count     = each.value.desired_count
  health_check_path = each.value.health_check_path
}
```

역할이 다른 서비스는 별도 모듈로 선언한다.

```hcl
module "gateway_server" {
  source = "../../../modules/gateway-service"

  env          = var.env
  service_name = "gateway-server"
  port         = 8080
  public       = true
}

module "monitor_server" {
  source = "../../../modules/monitoring"

  env          = var.env
  service_name = "monitor-server"
}

module "redis_server" {
  source = "../../../modules/redis"

  env          = var.env
  service_name = "redis-service"
}
```

## State 분리 기준
| State | 포함 리소스 |
| --- | --- |
| `env/shared` | VPC, subnet, NAT, route table, shared security group, shared ECR/KMS/Route53 |
| `env/services` | app/gateway/monitoring/redis 서비스 배포 단위 |

운영 환경에서는 최소한 `dev/shared`, `dev/services`, `prod/shared`, `prod/services`를 분리한다.

## Naming
리소스 이름은 아래 형식을 따른다.

```text
{env}-{service_name}-{resource}
```

예시:

```text
dev-auth-service-service
dev-user-service-task
prod-gateway-server-alb
prod-redis-service
prod-monitor-server-dashboard
```

## Tags
모든 리소스는 최소 공통 tag를 가진다.

```hcl
locals {
  common_tags = {
    Environment = var.env
    Service     = var.service_name
    ManagedBy   = "terraform"
    Project     = "msa"
  }
}
```

## 금지 사항
- 서비스별 Terraform 코드를 복사해 거의 같은 리소스를 따로 관리하지 않는다.
- `app-service` 모듈에 gateway, redis, monitoring 전용 조건을 계속 추가하지 않는다.
- 공통 network 리소스를 서비스 state 안에서 생성하지 않는다.
- prod와 dev를 같은 state에 넣지 않는다.
- 수동으로 만든 클라우드 리소스를 계약 없이 Terraform 관리 대상으로 편입하지 않는다.

## 변경 기준
- 3개 이상 서비스에서 같은 Terraform 패턴이 반복되면 공통 모듈 후보로 본다.
- 모듈 변수에 역할별 조건이 과도하게 늘어나면 새 모듈로 분리한다.
- 서비스 계약 변경으로 port, health path, public route, dependency가 바뀌면 Terraform service declaration도 함께 갱신한다.
- Redis처럼 stateful service는 application module이 아니라 전용 module에서 관리한다.
