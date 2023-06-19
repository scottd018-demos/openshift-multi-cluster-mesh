#
# infra
# 
infra-init:
	@cd terraform && terraform init

infra-plan:
	@export TF_VAR_token="$$(bw get password ocm-api-key)" && \
		export TF_VAR_db_password="$$(bw get password cockroach-db-password)" && \
		export COCKROACH_API_KEY="$$(bw get password cockroach-api-key)" && \
		cd terraform && terraform plan -out main.plan

infra-apply:
	@export COCKROACH_API_KEY="$$(bw get password cockroach-api-key)" && \
		cd terraform && terraform apply -auto-approve main.plan

infra-destroy:
	@export TF_VAR_token="$$(bw get password ocm-api-key)" && \
		export COCKROACH_API_KEY="$$(bw get password cockroach-api-key)" && \
		cd terraform && terraform apply -auto-approve -destroy

#
# openshift
#
OPENSHIFT_NAMESPACE ?= dscott
openshift-namespace:
	@oc new-project $(OPENSHIFT_NAMESPACE)

OPENSHIFT_SECRET ?= cockroach
openshift-secret:
	@export CLUSTER_DNS=`cat terraform/terraform.tfstate | jq -r '.resources[] | select(.type == "cockroach_cluster") | .instances[0].attributes.regions[0].sql_dns'` && \
		export CLUSTER_NAME=`cat terraform/terraform.tfstate | jq -r '.resources[] | select(.type == "cockroach_cluster") | .instances[0].attributes.serverless.routing_id'` && \
		export CLUSTER_DB=`cat terraform/terraform.tfstate | jq -r '.resources[] | select(.type == "cockroach_database") | .instances[0].attributes.name'` && \
		export CLUSTER_DB_USER=`cat terraform/terraform.tfstate | jq -r '.resources[] | select(.type == "cockroach_sql_user") | .instances[0].attributes.name'` && \
		export CLUSTER_DB_PASSWORD=`cat terraform/terraform.tfstate | jq -r '.resources[] | select(.type == "cockroach_sql_user") | .instances[0].attributes.password'` && \
		oc create secret generic $(OPENSHIFT_SECRET) \
		--namespace=$(OPENSHIFT_NAMESPACE) \
		--from-literal=JDBC_URL=jdbc:postgresql://$${CLUSTER_DNS}:26257/$${CLUSTER_NAME}.$${CLUSTER_DB}?sslmode=verify-full \
		--from-literal=PGUSER="$${CLUSTER_DB_USER}" \
		--from-literal=PGPASSWORD="$${CLUSTER_DB_PASSWORD}"

#
# application
#
# NOTE: see guide at https://quarkus.io/guides/deploying-to-openshift
APP_NAME ?= demo
APP_DOMAIN_REVERSE ?= io.dustinscott
app-init:
	@cd app && quarkus create app $(APP_DOMAIN_REVERSE):$(APP_NAME) \
		--extension='resteasy-reactive,openshift,jdbc-postgresql,quarkus-hibernate-orm-panache,quarkus-resteasy-reactive-jackson'

app-build:
	@cd app/$(APP_NAME) && quarkus build

app-deploy:
	@cd app/$(APP_NAME) && quarkus build -Dquarkus.kubernetes.deploy=true

app-connect:
	export CLUSTER_DNS=`cat terraform/terraform.tfstate | jq -r '.resources[] | select(.type == "cockroach_cluster") | .instances[0].attributes.regions[0].sql_dns'` && \
		export CLUSTER_NAME=`cat terraform/terraform.tfstate | jq -r '.resources[] | select(.type == "cockroach_cluster") | .instances[0].attributes.serverless.routing_id'` && \
		export CLUSTER_DB=`cat terraform/terraform.tfstate | jq -r '.resources[] | select(.type == "cockroach_database") | .instances[0].attributes.name'` && \
		export CLUSTER_DB_USER=`cat terraform/terraform.tfstate | jq -r '.resources[] | select(.type == "cockroach_sql_user") | .instances[0].attributes.name'` && \
		export CLUSTER_DB_PASSWORD=`cat terraform/terraform.tfstate | jq -r '.resources[] | select(.type == "cockroach_sql_user") | .instances[0].attributes.password'` && \
		cockroach sql --user $${CLUSTER_DB_USER} --url "postgres://$${CLUSTER_DNS}:26257/$${CLUSTER_NAME}.$${CLUSTER_DB}?sslmode=verify-full"

app-dev-db-start:
	@rm -rf app/certs && mkdir -p app/certs && \
		docker run -it --rm=true \
			--name cockroach \
			--hostname cockroach \
			--env COCKROACH_DATABASE=dev \
			--env COCKROACH_USER=dev \
			--env COCKROACH_PASSWORD=dev \
			-p 26257:26257 \
			-p 8081:8080 \
			-v `pwd`/app/certs:/cockroach/certs \
			cockroachdb/cockroach:v22.2.9 start-single-node \
				--http-addr=localhost:8080

app-dev-start:
	cd app/$(APP_NAME) && quarkus dev

app-dev-connect:
	cockroach sql --user dev --url "postgresql://localhost:26257/dev?sslmode=prefer" --certs-dir app/certs

app-dev-test:
	curl -s localhost:8080/api/person | jq && \
	curl -s localhost:8080/api/person/100 | jq && \
	curl -s localhost:8080/api/person/101 | jq && \
	curl -H 'Content-Type: application/json' -s -d '{"firstName": "Miss", "lastName": "Jackson"}' -X POST localhost:8080/api/person | jq && \
	curl -H 'Content-Type: application/json' -s -d '{"firstName": "Mister", "lastName": "Jackson"}' -X POST localhost:8080/api/person | jq && \
	curl -H 'Content-Type: application/json' -s -d '{"firstName": "Mrs"}' -X PUT localhost:8080/api/person/1 | jq && \
	curl -H 'Content-Type: application/json' -s -d '{"firstName": "Mr"}' -X PUT localhost:8080/api/person/2 | jq && \
	curl -H 'Content-Type: application/json' -s -d '{"lastName": "Johnson"}' -X PUT localhost:8080/api/person/1 | jq && \
	curl -H 'Content-Type: application/json' -s -d '{"lastName": "Johnson"}' -X PUT localhost:8080/api/person/2 | jq && \
	curl -s -X DELETE localhost:8080/api/person/1 | jq && \
	curl -s -X DELETE localhost:8080/api/person/2 | jq
