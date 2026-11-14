# install.sh のラッパー
INSTALL := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))/install.sh

.DEFAULT_GOAL := help
.PHONY: help install update deploy clean list vscode vscode-pull

install: ## Set up everything except VS Code (packages, links, mise tools, zsh plugins)
	@$(INSTALL) install

update: ## Update repo, mise, CLI tools and zsh plugins
	@$(INSTALL) update

deploy: ## Create symlinks (existing real files are backed up as *.bak.<timestamp>)
	@$(INSTALL) link

clean: ## Remove only the symlinks that point into this repo
	@$(INSTALL) unlink

list: ## Show files managed by this repo
	@$(INSTALL) list

vscode: ## Deploy VS Code settings/snippets/extensions (existing files are backed up)
	@$(INSTALL) vscode

vscode-pull: ## Import current VS Code settings and extension list into this repo (except machine-local keys)
	@$(INSTALL) vscode-pull

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-12s\033[0m %s\n", $$1, $$2}'
