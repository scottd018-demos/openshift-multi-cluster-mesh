#
# infra
# 
infra-init:
	@cd terraform && terraform init

infra-plan:
	@export TF_VAR_token="$$(bw get password ocm-api-key)" && cd terraform && terraform plan -out main.plan

infra-apply:
	@cd terraform && terraform apply -auto-approve main.plan

infra-destroy:
	@export TF_VAR_token="$$(bw get password ocm-api-key)" && cd terraform && terraform apply -auto-approve -destroy

#
# openshift
#
