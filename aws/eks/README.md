# KKPP EKS Terraform

이 Terraform 스택은 기존 VPC에 EKS 클러스터를 생성합니다.

## 사전 요구사항

`terraform init`을 실행하기 전에 Terraform 백엔드 리소스를 생성합니다.

```bash
aws s3api create-bucket \
  --bucket kkpp-aws-terraform-state \
  --region ap-northeast-2 \
  --create-bucket-configuration LocationConstraint=ap-northeast-2

aws s3api put-bucket-versioning \
  --bucket kkpp-aws-terraform-state \
  --versioning-configuration Status=Enabled

aws dynamodb create-table \
  --table-name kkpp-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-northeast-2
```

## 사용법

```bash
cd ./aws/eks
terraform init
terraform plan
terraform apply
```

적용 후 aws 콘솔에서 EKS 클러스터, 워커노드 EC2 두 개, VPC 생성 되는 것을 확인할 수 있습니다.

## 참고사항

- 워커 노드는 프라이빗 서브넷에 생성됩니다.
- 퍼블릭 서브넷은 퍼블릭 LoadBalancer 서비스에 태깅됩니다.
- 프라이빗 서브넷은 내부 LoadBalancer 서비스에 태깅됩니다.
