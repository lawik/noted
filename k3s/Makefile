SHELL := bash# we want bash behaviour in all shell invocations
MAKEFILE := $(firstword $(MAKEFILE_LIST))
PLATFORM := $(shell uname -s)
MACHINE := $(shell uname -m)
platform = $(shell echo $(PLATFORM) | tr A-Z a-z)

# https://stackoverflow.com/questions/4842424/list-of-ansi-color-escape-sequences
RED := \033[1;31m
GREEN := \033[1;32m
YELLOW := \033[1;33m
BOLD := \033[1m
NORMAL := \033[0m

FQDN ?= k3s.gerhard.io
REMOTE_LINUX_HOST ?= root@$(FQDN)

define start_op
@printf "▶️  $(BOLD)$$(date +'%H:%M:%S') | $(1)...$(NORMAL)\n"
endef

define end_op
@printf "✅ $(BOLD)$$(date +'%H:%M:%S')$(NORMAL)\n"
endef

define learn_more
@printf "👀 $(YELLOW)$(1) $(NORMAL)\n"
endef

define MAKE_TARGETS
  awk -F':+' '/^[^.%\t_][0-9a-zA-Z._%-]*:+.*$$/ { printf "%s\n", $$1 }' $(MAKEFILE_LIST)
endef

define BASH_AUTOCOMPLETE
complete -W \"$$($(MAKE_TARGETS) | sort | uniq)\" make m
endef

# Only meant to be run locally
ifneq (,$(wildcard $(CURDIR)/../.git))
# https://tools.ietf.org/html/rfc3339 format - s/:/./g so that Docker tag is valid
export BUILD_VERSION := $(shell date -u +'%Y-%m-%dT%H.%M.%SZ')
.PHONY: _container_image
_container_image:
	cd $(CURDIR)/.. \
	&& docker build -t $(USER)/noted:$(BUILD_VERSION) . \
	&& docker push $(USER)/noted:$(BUILD_VERSION)

.envrc:
	@echo "# https://cloud.linode.com/profile/tokens" > $(@)
	@echo "export LINODE_API_TOKEN=" >> $(@)
	@echo "# /newbot" >> $(@)
	@echo "export TELEGRAM_BOT_SECRET=" >> $(@)
	@echo "pwgen 64 1" >> $(@)
	@echo "export SECRET_KEY_BASE=" >> $(@)

.PHONY: _reset_host_id
_reset_host_id:
	ssh-keygen -R $(FQDN)
	ssh-keygen -R $$(dig +short $(FQDN))

.PHONY: _todo
_todo:
	grep -r -A 1 "TODO:" $(CURDIR)
endif

.PHONY: env
env::
	@echo 'alias m=make'
	@echo "$(BASH_AUTOCOMPLETE)"

.env:
	$(MAKE) --no-print-directory env SILENT="1>/dev/null 2>&1" > .env
	if [ -f .bashrc ]; then grep --quiet "source .env" $(HOME)/.bashrc || echo "[ ! -f .env ] || source .env" >> $(HOME)/.bashrc; fi
	@printf "$(YELLOW)Now run:$(NORMAL) $(BOLD)source .env$(NORMAL)\n"

.PHONY: clean
clean:: # Restore this host to a vanilla state - removes Kubernetes and everything else that we have installed
	rm -fr $(CURDIR)/{.env,.kube} $(CURDIR)/*
	sed -i '/source .env/d' $(HOME)/.bashrc

.PHONY: ops
ops: # Install ops-friendly utilities
	$(call start_op,Installing ops-friendly utilities)
	apt-get update
	apt-get install \
		tmux neovim \
		htop nmon dstat \
		iperf3 dnsutils
	$(call end_op)
env::
	@echo 'alias t=tmux'
	@echo 'alias h=htop'
	@echo 'alias v=nvim'

.DEFAULT_GOAL := start
HELP_TARGET_DEPTH ?= \#
YOUTUBE_URL := https://youtu.be/v7_Ebpkazis
.PHONY: start
ifneq (,$(wildcard $(CURDIR)/../.git))
start:
	@printf "\n$(BOLD)This is meant to be run on a remote Linux host, Debian >=10 or Ubuntu >=20.04$(NORMAL)\n\n"
	@printf "Start by running the following command, e.g. $(BOLD)make seed REMOTE_LINUX_HOST=YOUR_REMOTE_LINUX_HOST$(NORMAL)\n"
	@printf "Now just ssh into this host, run $(BOLD)make$(NORMAL), and follow the next steps\n\n"
	@printf "⚠️  Remember that you will need to run $(BOLD)make seed_secrets$(NORMAL) locally at some point ⚠️\n\n"
	$(call learn_more,Watch the YouTube livestream: $(YOUTUBE_URL))
	@printf "\n"
else
start: .env
	@printf "\n$(BOLD)These are your training wheels for getting started with Kubernetes$(NORMAL)\n"
	@printf "+ Tested on Debian 10 by @gerhard on 2021.06.17\n"
	@printf "+ Tested on Ubuntu 20.04 by @lawik on 2021.06.18\n"
	$(call learn_more,Watch the YouTube livestream: $(YOUTUBE_URL))
	@printf "\nIf this is your first time running this, remember to run: $(BOLD)source .env$(NORMAL)\n"
	@printf "Now just type $(BOLD)make <TAB>$(NORMAL) to enjoy shell autocompletion\n"
	@printf "By the way, $(BOLD)m$(NORMAL) is an alias for $(BOLD)make$(NORMAL)\n\n"
	@printf "Here is a list of all the make targets that you can run, e.g. $(BOLD)make k3s$(NORMAL) - or $(BOLD)m k3s$(NORMAL)\n\n"
	@awk -F':+ |$(HELP_TARGET_DEPTH)' '/^[^.][0-9a-zA-Z._%-]+:+.+$(HELP_TARGET_DEPTH).+$$/ { printf "$(GREEN)%-12s\033[0m %s\n", $$1, $$3 }' $(MAKEFILE_LIST) | sort
	@printf "\nFinally, you may want to run $(BOLD)make ops$(NORMAL) to get a bunch of other ops-friendly utilities 🚀\n\n"
endif

.PHONY: seed
seed:
ifeq (,$(REMOTE_LINUX_HOST))
	$(error REMOTE_LINUX_HOST must reference a valid remote host, including any entry from .ssh/config)
endif
	ssh $(REMOTE_LINUX_HOST) -t "if ! make --version; then apt-get update && apt-get install make && hostname $(FQDN); fi"
	scp -r $(CURDIR)/* $(REMOTE_LINUX_HOST):~/
	ssh $(REMOTE_LINUX_HOST) -t "make .env"

define seed_secret
@[ -z "$(1)" ] \
|| ssh $(REMOTE_LINUX_HOST) -t "make k3s-secret SECRET_NAME=$(2) SECRET_VALUE=$(1) NAMESPACE=$(3)"
endef
.PHONY: seed_secrets
seed_secrets: seed
	$(call seed_secret,$(LINODE_API_TOKEN),linode-api-token,external-dns)
	$(call seed_secret,$(TELEGRAM_BOT_SECRET),telegram-bot-secret,default)
	$(call seed_secret,$(SECRET_KEY_BASE),secret-key-base,default)

.PHONY: ssh
ssh:
	ssh $(REMOTE_LINUX_HOST)

CURL := /usr/bin/curl
$(CURL):
	apt-get update
	apt-get install curl

BIN_DIR ?= /usr/local/bin

K3s := $(BIN_DIR)/k3s
KUBECTL := $(K3s) kubectl
$(K3s): $(CURL)
	$(call start_op,Installing k3s.io)
	$(call learn_more,Learn more at https://rancher.com/docs/k3s/latest/en/installation/install-options/)
	$(call learn_more,Why do we disable network policy? https://github.com/k3s-io/k3s/issues/3117#issuecomment-846475148)
	$(call learn_more,Try this another day: https://docs.projectcalico.org/getting-started/kubernetes/k3s/quickstart)
	$(CURL) -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --disable-network-policy" sh -
	$(call end_op)
.PHONY: k3s
k3s: $(K3s) # Install a certified Kubernetes distribution - in under 15 seconds!
env::
	@echo 'alias kubectl="$(KUBECTL)"'
	@echo 'alias k=kubectl'
	@echo 'export KUBECONFIG=/etc/rancher/k3s/k3s.yaml'
clean::
	[ ! -x $(BIN_DIR)/k3s-uninstall.sh ] || $(BIN_DIR)/k3s-uninstall.sh

.PHONY: k3s-check
k3s-check: $(K3s) # Check k3s installation
	$(K3s) check-config

node-info: $(K3s) # Show K8s node info
	$(KUBECTL) get node --output=wide

.PHONY: k3s-secret
k3s-secret: $(K3s)
ifeq (,$(NAMESPACE))
	$(error NAMESPACE must be set to the namespace where the secret will be created)
endif
ifeq (,$(SECRET_NAME))
	$(error SECRET_NAME must be set to the name of the secret that will be created)
endif
ifeq (,$(SECRET_VALUE))
	$(error SECRET_VALUE must be set to the value of the secret that will be created)
endif
	@$(KUBECTL) --namespace $(NAMESPACE) --dry-run=client --output=yaml \
	  create secret generic $(SECRET_NAME) \
	  --from-literal=value=$(SECRET_VALUE) \
	| $(KUBECTL) apply --filename -

K9s_RELEASES := https://github.com/derailed/k9s/releases
K9s_VERSION := 0.24.10
K9s_BIN_DIR := /var/lib/k9s-$(K9s_VERSION)-$(PLATFORM)-x86_64
K9s_URL := $(K9s_RELEASES)/download/v$(K9s_VERSION)/k9s_v$(K9s_VERSION)_$(PLATFORM)_x86_64.tar.gz
K9s := $(K9s_BIN_DIR)/k9s
$(K9s): $(CURL)
	$(CURL) --progress-bar --fail --location --output $(K9s_BIN_DIR).tar.gz "$(K9s_URL)"
	mkdir -p $(K9s_BIN_DIR) && tar zxf $(K9s_BIN_DIR).tar.gz -C $(K9s_BIN_DIR)
	rm $(K9s_BIN_DIR).tar.gz
	touch $(K9s)
	chmod +x $(K9s)
	$(K9s) version | grep $(K9s_VERSION)
	ln -sf $(K9s) $(BIN_DIR)/k9s
.PHONY: k9s
k9s: $(K9s) # Interact with Kubernetes via a terminal UI - ncurses FTW!
	$(K9s) --all-namespaces
clean::
	rm -fr $(K9s_BIN_DIR) $(BIN_DIR)/k9s

EXTERNAL_DNS_RELEASES := https://github.com/kubernetes-sigs/external-dns/releases
.PHONY: external-dns
external-dns: $(K3s) # Install external-dns with Linode Domains integration ⚠️  make seed_secrets
	$(KUBECTL) apply -f $(CURDIR)/external-dns.yaml
	$(KUBECTL) apply -n external-dns -f https://raw.githubusercontent.com/kubernetes-sigs/external-dns/v0.8.0/docs/contributing/crd-source/crd-manifest.yaml

# TODO: envsubst instead of config? 🤔
# We want to fail if variables are not set or empty.
# The envsubst that comes with gettext does not support this,
# using this Go version instead: https://github.com/a8m/envsubst#docs
ENVSUBST_RELEASES := https://github.com/a8m/envsubst/releases
ENVSUBST_VERSION := 1.2.0
ENVSUBST_BIN := envsubst-$(ENVSUBST_VERSION)-$(PLATFORM)-x86_64
ENVSUBST_URL := $(ENVSUBST_RELEASES)/download/v$(ENVSUBST_VERSION)/envsubst-$(PLATFORM)-x86_64
ENVSUBST := $(BIN_DIR)/$(ENVSUBST_BIN)
ENVSUBST_SAFE := $(ENVSUBST) -no-unset -no-empty
$(ENVSUBST): $(CURL)
	$(CURL) --progress-bar --fail --location --output $(ENVSUBST) "$(ENVSUBST_URL)"
	touch $(ENVSUBST)
	chmod +x $(ENVSUBST)
	ln -sf $(ENVSUBST) $(BIN_DIR)/envsubst
.PHONY: envsubst
envsubst: $(ENVSUBST)
clean::
	rm -fr $(ENVSUBST) $(BIN_DIR)/envsubst

ARGOCD_RELEASES := https://github.com/argoproj/argo-cd/releases
ARGOCD_VERSION := 2.0.3
.PHONY: argocd
argocd: external-dns # Install ArgoCD
	$(call start_op,Installing ArgoCD)
	$(call learn_more,https://argo-cd.readthedocs.io/en/stable/)
	$(KUBECTL) apply -f $(CURDIR)/argocd.yaml
	$(KUBECTL) apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v$(ARGOCD_VERSION)/manifests/install.yaml
	$(KUBECTL) patch deploy argocd-server -n argocd -p '[{"op": "add", "path": "/spec/template/spec/containers/0/command/-", "value": "--insecure"}]' --type json
	$(call end_op)

.PHONY: argocd-noted
argocd-noted: # Configure ArgoCD to continuously deploy noted app ⚠️  make seed_secrets
	$(KUBECTL) apply -f $(CURDIR)/argocd-noted.yaml
