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
##@ Virtualenv

.PHONY: clean
clean:	## - Cleanup: pycache stuff
	rm -rf .pytest_cache .ipynb_checkpoints
	rm -rf dist/ build/ *.gz *.zip
	rm -rf src/*.egg*
	rm -rf src/*/*.egg*

################################################################################
.PHONY: venv
venv:   ## - virtualenv: create
	virtualenv $(_venv)        && \
	source $(_venv)/bin/activate   && \
	echo pip3 install --upgrade pip

.PHONY: venv-clean
venv-clean: ## - virtualenv: rm
	/bin/rm -rf $(_venv)


################################################################################
.PHONY: pip
pip:    ## - Pip: install from requirements.txt
	pip3 install --upgrade pip && \
	pip3 install -r requirements.txt


.PHONY: pip-dev
pip-dev: ## - Pip: install from requirements-dev.txt
	pip3 install -r requirements-dev.txt


################################################################################
##@ Docker
.PHONY: img
img: ## - Docker images
	docker images

.PHONY: clean-docker
clean-docker: ## - Docker: clean ps+img
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

.PHONY: pg-17-build
pg-17-build: ## - Docker build: container image: $(_cimg):$(_tag)
#	export _img=pg-17  ;\
#	export _tag=latest ;\

	docker build -f docker/Dockerfile.$(_cimg) -t $(_cimg):$(_base) . && \
	docker images | egrep -B5 -A5 --color "$(_cimg) *$(_base)"


.PHONY: pg-17-run
pg-17-run: ## - Docker run /bin/sh
	docker run -ti --rm -p 5432:5432 -v .:/work --entrypoint /bin/sh $(_cimg):$(_base)


################################################################################
##@ Postgres

##
##
.PHONY: db-primary-run
db-primary-run: ## - Docker daemon: db-primary
	docker run -d -p 5432:5432 -v .:/work --name $(_primary) $(_cimg) && \
	docker ps | egrep  --color "$(_primary)"


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


##
##
.PHONY: replica-run
replica-run: ## - Docker daemon: replica
	docker run -d -p 5433:5432 -v .:/work --name $(_replica) $(_cimg) && \
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


.PHONY: replica-setup
replica-setup: ## - Docker ...
	psql -U postgres -h 127.0.0.1 -p 5433 postgres < sql/ddl/schema.tst.sql
	psql -U tst      -h 127.0.0.1 -p 5433 postgres < sql/ddl/orders.tab.sql
	@make replica-check


.PHONY: replica-check
replica-check: ## - Docker ...
	psql -U tst      -h 127.0.0.1 -p 5433 postgres -c '\l' -c '\du' -c '\dn' -c '\dt' -c '\d tst.orders'

