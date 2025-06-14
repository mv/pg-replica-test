# vim:ft=make:ts=8:sts=8:sw=8:noet:tw=80:nowrap:list

# My vars: simple
_os             := $(shell uname -sr)
_venv           := .venv
_python_version := $(shell python -V)

# _pkg_repo    := pismo/pismo-subnetcalc
# _pkg_version := $(shell awk -F" = " '/version/ {print $$2}' src/subnetcalc/__init__.py | tr -d "'")

.DEFAULT_GOAL:=help

################################################################################
##@ Help
.PHONY: help
help:   ## - Default goal: list of targets in Makefile
	@awk '\
	  BEGIN { FS = ":.*##"; printf "\nUsage:\n  make \033[01;33m<target>\033[0m\n" }        \
	  /^##@/                  { printf "\n\033[01;37m  %s   \033[0m\n"   , substr($$0, 5) } \
	  /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[01;33m  %-25s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo

.PHONY: show
show:   ## - Show header vars
	@echo
	@echo "  ## OS             [${_os}]"
	@echo "  ## Python Version [${_python_version}]"
	@echo "  ## Virtualenv     [${_venv}]"
#	@echo "  ## Pkg Repo       [${_pkg_repo}]"
#	@echo "  ## Pkg Version    [${_pkg_version}]"
	@echo


################################################################################
##@ Docker
.PHONY: img
img: ## - Docker images
	docker images

.PHONY: clean
clean: ## - Docker: clean ps+img
	@make clean-ps
	@make clean-img

.PHONY: clean-img
clean-img: ## - Docker rmi: untagged
	docker rmi $$(docker images -f "dangling=true" -q) && \
	printf "\nCleaned...\n\n" && \
	docker images

.PHONY: clean-ps
clean-ps: ## - Docker rm: ps exited
	docker ps -a && \
	docker rm $$( docker ps -a -q -f status=exited ) && \
	printf "\nCleaned...\n\n" && \
	docker ps -a


_cimg:=pg-17
_base:=latest
_primary:=db-primary
_replica:=db-replica

.PHONY: build-pg17
build-pg17: ## - Docker build: container image: $(_cimg):$(_tag)
#	export _img=pg-17  ;\
#	export _tag=latest ;\

	docker build -f docker/Dockerfile.$(_cimg) -t $(_cimg):$(_base) . && \
	docker images | egrep -B5 -A5 --color "$(_cimg) *$(_base)"


.PHONY: run-pg17
run-pg17: ## - Docker run /bin/sh
	docker run -ti --rm -p 5432:5432 -v .:/work --entrypoint /bin/sh $(_cimg):$(_base)


################################################################################
##@ Postgres

##
##
.PHONY: db-primary-run
db-primary-run: ## - Docker daemon: db-primary
	docker volume create archive
	docker create \
		-p 5432:5432 \
		-v .:/work -v archive:/mnt/archive \
		--name $(_primary) --hostname $(_primary) \
		$(_cimg)
	docker cp docker/pg-replication-primary.conf $(_primary):/var/lib/postgresql/
	docker start $(_primary)
	docker ps | egrep  --color "$(_primary)"

#		--ip 172.17.0.32 \

.PHONY: db-primary-start
db-primary-start: ## - Docker start: db-primary
	docker start $(_primary)
	@echo
	@docker ps -a | egrep -e "NAMES|$(_primary)"

.PHONY: db-primary-stop
db-primary-stop: ## - Docker stop: db-primary
	docker stop $(_primary)
	@echo
	@docker ps -a | egrep -e "NAMES|$(_primary)"


.PHONY: db-primary-setup
db-primary-setup: ## - Docker ...
	psql -U postgres -h 127.0.0.1 -p 5432 postgres < sql/ddl/schema.tst.sql
	psql -U tst      -h 127.0.0.1 -p 5432 postgres < sql/ddl/orders.tab.sql
	@make db-primary-check


.PHONY: db-primary-check
db-primary-check: ## - Docker ...
	psql -U tst      -h 127.0.0.1 -p 5432 postgres -c '\l' -c '\du' -c '\dn' -c '\dt' -c '\d tst.orders'


.PHONY: db-primary-all
db-primary-all: ## - Docker ...
	@make db-primary-run
	@make db-primary-setup

.PHONY: db-primary-clean
db-primary-clean: ## - Docker ...
	docker stop $(_primary)
	docker rm   $(_primary)
	docker volume rm archive


##
##
.PHONY: replica-run
replica-run: ## - Docker daemon: replica
	docker create \
		-p 5433:5432 \
		-v .:/work -v archive:/mnt/archive \
		--name $(_replica) --hostname $(_replica) \
		$(_cimg)
	docker cp docker/pg-replication-replica.conf $(_replica):/var/lib/postgresql/
	docker cp /dev/null                          $(_replica):/var/lib/postgresql/standby.signal
	docker start $(_replica)
	docker ps | egrep  --color "$(_replica)"


.PHONY: replica-start
replica-start: ## - Docker start: replica
	docker start $(_replica)
	@echo
	@docker ps -a | egrep -e "NAMES|$(_replica)"

.PHONY: replica-stop
replica-stop: ## - Docker stop: replica
	docker stop $(_replica)
	@echo
	@docker ps -a | egrep -e "NAMES|$(_replica)"


.PHONY: replica-check
replica-check: ## - Docker ...
	psql -U postgres -h 127.0.0.1 -p 5433 postgres -c '\l' -c '\du' -c '\dn' -c '\dt' -c '\d tst.orders'


.PHONY: replica-all
replica-all: ## - Docker ...
	@make replica-run
	@make replica-start

.PHONY: replica-clean
replica-clean: ## - Docker ...
	docker stop $(_replica)
	docker rm   $(_replica)

.PHONY: start-all
start-all: ## - Docker ...
	docker start $(_primary)
	docker start $(_replica)
	docker ps -a

.PHONY: stop-all
stop-all: ## - Docker ...
	docker stop $(_primary)
	docker stop $(_replica)
	docker ps -a

.PHONY: force-log-switch
force-log-switch: ## - Pg
	psql -U postgres -p 5432 -c 'SELECT pg_switch_wal();'

