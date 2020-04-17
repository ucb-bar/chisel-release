IVY_DIR ?= $(HOME)/.ivy2
COURSIER_CACHES ?= $(HOME)/.cache $(HOME)/.coursier
SBT=sbt -Dsbt.ivy.home=$(IVY_DIR) -DROCKET_USE_MAVEN
PYTHON ?= python3
MKDIR ?= mkdir
VERSIONING ?= versioning.py

# We need to execute sbt commands in a specific directory order and possibly
# do a publishLocal at the end so the results are available to later
# submodules.
EXPLICIT_SUBMODULES=firrtl firrtl-interpreter treadle chisel3 chisel-testers2 chisel-testers diagrammer dsptools

# The following targets need a publishLocal so their results are available.
NEED_PUBLISHING = compile test +compile +test

default: install

# The argument, $(1) is the list of sbt commands to execute.
# Set a Make variable with "publishLocal" if we need to add publishLocal
#  to the sbt command list.
define doSBT
$(eval publishlocal=$(if $(filter $(NEED_PUBLISHING),$(1)),$(if $(findstring +,$(1)),+publishLocal,publishLocal)))
	for c in $(EXPLICIT_SUBMODULES); do ( echo $$c && cd $$c && $(SBT) $(1) $(publishlocal) ) || exit 1; done
	$(if $(and $(filter $(EXPLICIT_SUBMODULES),dsptools),$(filter $(EXPLICIT_SUBMODULES),rocket-chip)),echo rocket-dsptools && cd dsptools && $(SBT) "project rocket-dsptools" "$(1)" || exit 1)
endef

# We want to introduce ordering dependencies if we're dealing with multiple targets.
NEED_CLEAN=$(if $(findstring clean,$(MAKECMDGOALS)),clean)
NEED_INSTALL=$(if $(findstring install,$(MAKECMDGOALS)),install)

# Generate the rules and dependencies for each sub-project's collection of tasks.
# The first argument is the sub-project (firrtl, treadle, chisel3) and
# the second argument is the sbt task (+clean, +publishLocal, +test).
# Ensure that +test targets are dependent on +publishLocal targets if we see
# a "install" in the command line goals,
# and the +publishLocal targets are dependent on the +clean targets if we see
# a "clean" in the command line goals.
define makeSubProjectTarget
dep+test=$(if $(NEED_INSTALL),$1.sbt+publishLocal)
dep+publishLocal=$(if $(NEED_CLEAN),$1.sbt+clean)

$1.sbt$2:	stamps $(dep$2)
	date > stamps/$1.sbt$2.begin
	cd $1 && $(SBT) $2
	pwd
	$(if $(findstring clean,$2),find $1 -depth -type d \( -name target -o -name test_run_dir \) -execdir rm -r {} \;)
	date > stamps/$1.sbt$2.end
endef

TEST_PROJECTS=$(foreach PROJ,$(EXPLICIT_SUBMODULES),$(PROJ).sbt+test)
CLEAN_PROJECTS=$(foreach PROJ,$(EXPLICIT_SUBMODULES),$(PROJ).sbt+clean)
INSTALL_PROJECTS=$(foreach PROJ,$(EXPLICIT_SUBMODULES),$(PROJ).sbt+publishLocal)

SBT_TASKS=+clean +publishLocal +test

$(foreach project,$(EXPLICIT_SUBMODULES),$(foreach task,$(SBT_TASKS),$(eval $(call makeSubProjectTarget,$(project),$(task)))))

test_projects:	$(TEST_PROJECTS)
	date > stamps/$@.end

clean_projects:	$(CLEAN_PROJECTS)
	date > stamps/$@.end

install_projects: $(INSTALL_PROJECTS)
	date > stamps/$@.end

clean +clean:	clean_projects clean_artifacts clean_caches
	date > stamps/$@.end

clean_build:	clean_projects
	date > stamps/$@.end

coverage:
	date > stamps/$@.begin
	$(call doSBT, clean coverage test)
	$(SBT) coverageReport coverageAggregate
	date > stamps/$@.end

publishLocal:
	date > stamps/$@.begin
	$(call doSBT,publishLocal)
	date > stamps/$@.end

publishLocalSigned:
	date > stamps/$@.begin
	$(call doSBT,publishLocalSigned)
	date > stamps/$@.end

# Copied (and slightly modified) from git internal code.
# Return true (pass) if the work tree is "clean" (unmodified).
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

# Pull any changes to root and submodules. This requires a clean work tree.
pull:	require_clean_work_tree
	date > stamps/$@.begin
	git pull
	git submodule foreach 'xbranch=$$(git config -f $$toplevel/.gitmodules submodule.$$name.branch); git fetch origin $$xbranch && git checkout $$xbranch && git pull && git submodule update --init --recursive'
	date > stamps/$@.end

# Remove generated (Berkeley) artifacts (jars).
clean_artifacts:
	date > stamps/$@.begin
	rm -rf $(IVY_DIR)/local/edu.berkeley.cs
	date > stamps/$@.end

# Remove Berkeley code from ivy and coursier caches.
clean_caches:
	date > stamps/$@.begin
	rm -rf $(IVY_DIR)/cache/edu.berkeley.cs
	for cache in $(COURSIER_CACHES); do \
	  if [[ -d $$cache ]]; then \
	    find $$cache -type d -path '*/edu/berkeley/cs' -exec rm -rf {} + ;\
	  fi; \
	done
	date > stamps/$@.end

# Build and install (publishLocal) sub-projects
install:	install_build $(NEED_CLEAN)
	date > stamps/$@.end

install_build:	install_projects
	date > stamps/$@.end

test check:	test_build $(NEED_INSTALL)
	date > stamps/$@.end

test_build:	test_projects
	date > stamps/$@.end

.DEFAULT:
	date > stamps/$@.begin
	$(call doSBT,$@)
	date > stamps/$@.end

.PHONY: build check clean +clean clean_build clean_projects $(CLEAN_PROJECTS) clean_caches clean_artifacts compile coverage default publishLocal +publishLocal publishLocalSigned +publishLocalSigned pull install install_projects $(INSTALL_PROJECTS) require_clean_work_tree test test_build test_projects $(TEST_PROJECTS)

FORCE:

BUILD_SBTs=chisel-testers/build.sbt chisel-testers2/build.sbt chisel3/build.sbt diagrammer/build.sbt dsptools/build.sbt firrtl/build.sbt firrtl-interpreter/build.sbt treadle/build.sbt

stamps:
	$(MKDIR) -p $@

# Generate the array of transitive dependencies if we have access to
# the $(VERSIONING) program
VERSION_DEP=$(if $(shell test -f $(VERSIONING) && echo yes),$(VERSIONING))

ifneq "$(VERSION_DEP)" ""
deps.bare:	Makefile $(BUILD_SBTs) $(VERSION_DEP) stamps
	date > stamps/$@.begin
	$(PYTHON) $(VERSIONING) -o $@ dependency-array
	date > stamps/$@.end
else
$(info No $(VERSIONING) program. Using existing deps.mk)
endif

# Convert the bare transitive dependencies into specific publishLocal dependencies
deps.mk:	deps.bare stamps
	date > stamps/$@.begin
	gawk -v suffix=sbt+publishLocal -e '{ gsub(/"/,""); gsub(/\S+/,"&." suffix ); printf "%s:\t",$$1; sep = ""; for (i = 2; i <= NF; i++) { printf "%s%s", sep, $$i; sep = " "} print ""}' deps.bare > deps.mk
	date > stamps/$@.end

-include deps.mk
