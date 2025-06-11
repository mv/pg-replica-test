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

.PHONY: img-clean
img-clean: ## - Docker rmi: untagged
	docker rmi $$(docker images -f "dangling=true" -q) ;\
	docker images


_img := pg-17
_base:=latest
_primary:=db-primary
_replica:=db-replica

.PHONY: build-pg-17
build-pg-17: ## - Docker build: tag=${_tag}
	export _img=pg-17  ;\
	export _tag=latest ;\
	docker build -f docker/Dockerfile.${_img} -t ${_img}:${_base} . && \
	docker images | egrep --color "${_img} *${_base}" -B5 -A5


.PHONY: run-pg-17
run-pg-17: ## - Docker ...
	docker run -ti -p 5432:5432 -v .:/work $(_img):${_base} /bin/sh

.PHONY: build-db-primary
build-db-primary: ## - Docker build: tag=${_tag}
	docker build -f docker/Dockerfile.$(_primary) -t $(_img):$(_primary) . && \
	docker images | egrep --color "$(_img) *$(_primary)" -B5 -A5


.PHONY: setup-primary
setup-primary: ## - Docker ...
	psql -U postgres -h 127.0.0.1 -p 5432 postgres < sql/user.postgres.sql
	psql -U postgres -h 127.0.0.1 -p 5432 postgres < sql/user.tst.sql
	psql -U postgres -h 127.0.0.1 -p 5432 postgres < sql/schema.orders.sql
#	psql -U orders   -h 127.0.0.1 -p 5432 postgres < sql/orders.tab.sql

.PHONY: setup-replica
setup-replica: ## - Docker ...
	psql -U postgres -h 127.0.0.1 -p 5433 postgres < sql/user.postgres.sql
#	psql -U postgres -h 127.0.0.1 -p 5433 postgres < sql/user.tst.sql
#	psql -U postgres -h 127.0.0.1 -p 5433 postgres < sql/schema.orders.sql
#	psql -U orders   -h 127.0.0.1 -p 5433 postgres < sql/orders.tab.sql

.PHONY: run-primary
run-primary: ## - Docker ...
	docker run -ti -p 5432:5432 -v .:/work $(_img):$(_base) /bin/sh

.PHONY: run-replica
run-replica: ## - Docker ...
	docker run -ti -p 5433:5432 -v .:/work $(_img):$(_base) /bin/sh
