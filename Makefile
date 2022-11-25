HOSTNAME   = vulcan
CACHE      = vulcan
BUILDER    = vulcan
REMOTES	   = hermes
GIT_REMOTE = jwiegley
MAX_AGE	   = 14

# Lazily evaluated variables; expensive to compute, but we only want it do it
# when first necessary.
GIT_DATE   = git --git-dir=nixpkgs/.git show -s --format=%cd --date=format:%Y%m%d_%H%M%S
LKG_DATE   = $(eval LKG_DATE := $(shell $(GIT_DATE) last-known-good))$(LKG_DATE)

ifeq ($(CACHE),)
NIXOPTS	   = --option build-use-substitutes false	\
	     --option substituters ''
else
ifeq ($(HOSTNAME),$(CACHE))
NIXOPTS	   =
else
NIXOPTS	   = --option build-use-substitutes true	\
	     --option require-sigs false		\
	     --option substituters 'ssh://$(CACHE)'
endif
endif

ifeq ($(BUILDER),)
NIXOPTS	  := $(NIXOPTS) --option builders ''
else
ifneq ($(HOSTNAME),$(BUILDER))
NIXOPTS	  := $(NIXOPTS) --option builders 'ssh://$(BUILDER)'
endif
endif

NIX_CONF  := $(HOME)/src/nix

# When building with the Makefile, rather than calling darwin-rebuild
# directly, we set the NIX_PATH to point at whatever is the latest pull of the
# various projects used to build this Nix configuration. See nix.nixPath in
# darwin.nix for the system definition of the NIX_PATH, which relies on
# whichever versions of the below were used to build that generation.
NIX_PATH   = $(HOME)/.nix-defexpr/channels
NIX_PATH  := $(NIX_PATH):darwin=$(HOME)/src/nix/darwin
NIX_PATH  := $(NIX_PATH):darwin-config=$(HOME)/src/nix/config/darwin.nix
NIX_PATH  := $(NIX_PATH):hm-config=$(HOME)/src/nix/config/home.nix
NIX_PATH  := $(NIX_PATH):home-manager=$(HOME)/src/nix/home-manager
NIX_PATH  := $(NIX_PATH):localconfig=$(NIX_CONF)/config/$(HOSTNAME).nix
NIX_PATH  := $(NIX_PATH):nixpkgs=$(HOME)/src/nix/nixpkgs
NIX_PATH  := $(NIX_PATH):ssh-auth-sock=$(HOME)/.config/gnupg/S.gpg-agent.ssh
NIX_PATH  := $(NIX_PATH):ssh-config-file=$(HOME)/.ssh/config

NIX	   = $(PRENIX) nix
NIX_BUILD  = $(PRENIX) nix-build
NIX_ENV	   = $(PRENIX) nix-env
NIX_STORE  = $(PRENIX) nix-store
NIX_GC	   = $(PRENIX) nix-collect-garbage

BUILD_ARGS = $(NIXOPTS) --keep-going

PRENIX	  := NIX_PATH=$(NIX_PATH)

all: rebuild

%-all: %
	@for host in $(REMOTES); do						\
	    ssh $$host "CACHE=$(HOSTNAME) NIX_CONF=$(NIX_CONF) u $$host $<";	\
	done

define announce
	@echo
	@echo '┌────────────────────────────────────────────────────────────────────────────┐'
	@echo -n '│ >>> $(1)'
	@printf "%$$((72 - $(shell echo '$(1)' | wc -c)))s│\n"
	@echo '└────────────────────────────────────────────────────────────────────────────┘'
endef

test:
	$(call announce,this is a test)

tools:
	@echo HOSTNAME=$(HOSTNAME)
	@echo CACHE=$(CACHE)
	@echo BUILDER=$(BUILDER)

	@echo export PATH=$(PATH)
	@echo export NIXOPTS=$(NIXOPTS)
	@echo export NIX_PATH=$(NIX_PATH)
	@echo export BUILD_ARGS=$(BUILD_ARGS)

	which   field				\
		find				\
		git				\
		head				\
		make				\
		nix				\
		nix-build			\
		nix-env				\
		sort				\
		sudo				\
		uniq

build:
	$(call announce,nix build -f "<darwin>" system)
	@$(NIX) build $(BUILD_ARGS) -f "<darwin>" system --keep-going
	@rm -f result*

switch:
	$(call announce,darwin-rebuild switch)
	@$(PRENIX) darwin-rebuild switch --cores 1 -j1
	@echo "Darwin generation: $$($(PRENIX) darwin-rebuild --list-generations | tail -1)"

rebuild: build switch

tag-before:
	$(call announce,git tag before-update)
	git --git-dir=nixpkgs/.git branch -f before-update HEAD

pull: tag-before
	$(call announce,git pull)
	(cd nixpkgs	 && git pull --rebase)
	(cd darwin	 && git pull --rebase)
	(cd home-manager && git pull --rebase)

tag-working:
	$(call announce,git tag last-known-good)
	git --git-dir=nixpkgs/.git branch -f last-known-good before-update
	git --git-dir=nixpkgs/.git branch -D before-update
	git --git-dir=nixpkgs/.git tag -f known-good-$(LKG_DATE) \
	    -m "known-good-$(LKG_DATE)" last-known-good

mirror: tag-working
	$(call announce,git push)
	@for name in master unstable last-known-good; do	\
	    git --git-dir=nixpkgs/.git push $(GIT_REMOTE)	\
	        -f $${name}:$${name};				\
	done
	git --git-dir=nixpkgs/.git push -f --tags $(GIT_REMOTE)
	git --git-dir=darwin/.git push --mirror $(GIT_REMOTE)
	git --git-dir=home-manager/.git push --mirror $(GIT_REMOTE)

update: pull rebuild mirror travel-ready check

update-sync: pull build copy rebuild-all mirror travel-ready-all check-all

########################################################################

copy-src:
	$(call announce,pushme)
	@for host in $(REMOTES); do				\
	    push -f home,src,kadena $$host;			\
	done

copy: copy-src

########################################################################

define delete-generations
	$(NIX_ENV) $(1) --delete-generations			\
	    $(shell $(NIX_ENV) $(1)				\
		--list-generations | field 1 | head -n -$(2))
endef

define delete-generations-all
	$(call delete-generations,,$(1))
	$(call delete-generations,-p /nix/var/nix/profiles/system,$(1))
endef

clean: gc check

fullclean: gc-old check

gc:
	$(call delete-generations-all,$(MAX_AGE))
	$(NIX_GC) --delete-older-than $(MAX_AGE)d

gc-old:
	$(call delete-generations-all,1)
	$(NIX_GC) --delete-old

fullclean:
	$(call fullclean,clean)
	(cd $(HOME) && clean)

purge: fullclean gc-old

check:
	$(call announce,nix-store --check-contents)
	$(NIX_STORE) --verify --repair --check-contents

sizes:
	df -H /nix 2>&1 | grep /dev

PROJECTS = $(HOME)/.config/projects

travel-ready:
	$(call announce,travel-ready)
	@readarray -t projects < <(egrep -v '^(#.+)?$$' "$(PROJECTS)")
	@for dir in "$${projects[@]}"; do		\
	    echo "Updating direnv for ~/$$dir";		\
	    (cd ~/$$dir;				\
             if [[ $(HOSTNAME) == athena ]]; then	\
                 unset BUILDER CACHE;			\
	         $(NIX_CONF)/bin/de --no-cache;		\
             elif [[ $(HOSTNAME) != hermes ]]; then	\
                 unset BUILDER;				\
		 CACHE=$(CACHE);			\
	         $(NIX_CONF)/bin/de;			\
             else					\
	         BUILDER=$(BUILDER);			\
		 CACHE=$(CACHE);			\
	         $(NIX_CONF)/bin/de;			\
	     fi);					\
	done

.ONESHELL:
