IVY_DIR ?= $(HOME)/.ivy2
COURSIER_CACHES ?= $(HOME)/.cache $(HOME)/.coursier
SBT=sbt -Dsbt.ivy.home=$(IVY_DIR) -DROCKET_USE_MAVEN

# Until we integrate the deprepkg branch into master and sbt knows
#  the true project/submodule dependencies, we need to execute sbt commands
#  in a specific directory order and do a publishLocal at the end
#  so the results are available to later submodules.
EXPLICIT_SUBMODULES=firrtl firrtl-interpreter treadle chisel3 chisel-testers2 chisel-testers diagrammer dsptools

# The following targets need a publishLocal so their results are available.
NEED_PUBLISHING = compile test +compile +test

# The argument, $(1) is the list of sbt commands to execute.
# Set a Make variable with "publishLocal" if we need to add publishLocal
#  to the sbt command list.
define doSBT
$(eval publishlocal=$(if $(filter $(NEED_PUBLISHING),$(1)),$(if $(findstring +,$(1)),+publishLocal,publishLocal)))
	for c in $(EXPLICIT_SUBMODULES); do ( echo $$c && cd $$c && $(SBT) $(1) $(publishlocal) ) || exit 1; done
	$(if $(and $(filter $(EXPLICIT_SUBMODULES),dsptools),$(filter $(EXPLICIT_SUBMODULES),rocket-chip)),echo rocket-dsptools && cd dsptools && $(SBT) "project rocket-dsptools" "$(1)" || exit 1)
endef

default compile:
	$(call doSBT,compile)

clean +clean:
	$(call doSBT,$@)
	find . -depth -type d \( -name target -o -name test_run_dir \) -execdir echo rm -rf {}"/*" \;

coverage:
	$(call doSBT, clean coverage test)
	$(SBT) coverageReport coverageAggregate

publishLocal:
	$(call doSBT,publishLocal)

publishLocalSigned:
	$(call doSBT,publishLocalSigned)

require_clean_work_tree:
	@git rev-parse --verify HEAD >/dev/null || exit 1
	@git update-index -q --refresh
	@if ! git diff-files --quiet --ignore-submodules=untracked; \
	then \
	    echo >&2 "tree not clean: You have unstaged changes."; \
	    exit 1; \
	fi
	@if ! git diff-index --cached --quiet --ignore-submodules=untracked HEAD --; \
	then \
	    if [ $$err = 0 ]; \
	    then \
	        echo >&2 "tree not claen: Your index contains uncommitted changes."; \
	    else \
	        echo >&2 "Additionally, your index contains uncommitted changes."; \
	    fi; \
	    exit 1; \
	fi
#	git ls-files --cached --deleted --modified
#	git status --porcelain --ignore-submodules=untracked -uno
#	git status --ignore-submodules=untracked
#	git diff --quiet --ignore-submodules=untracked

pull:	require_clean_work_tree
	git pull
	git submodule foreach 'xbranch=$$(git config -f $$toplevel/.gitmodules submodule.$$name.branch); git fetch origin $$xbranch && git checkout $$xbranch && git pull && git submodule update --init --recursive'

clean_artifacts:
	rm -rf $(IVY_DIR)/local/edu.berkeley.cs

clean_caches:
	rm -rf $(IVY_DIR)/cache/edu.berkeley.cs
	for cache in $(COURSIER_CACHES); do \
	  find $$cache -type d -path '*/edu/berkeley/cs' -exec rm -rf {} + ;\
	done

build:
	$(MAKE) NEED_PUBLISHING="" +clean +publishLocal

test-build:
	$(MAKE) NEED_PUBLISHING="" +test

.DEFAULT:
	$(call doSBT,$@)

.PHONY: build clean +clean  clean_caches clean_artifacts compile coverage default publishLocal publishLocalSigned pull require_clean_work_tree test-build
