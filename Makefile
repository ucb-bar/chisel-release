IVY_DIR ?= $(HOME)/.ivy2
SBT=sbt -Dsbt.ivy.home=$(IVY_DIR) -DROCKET_USE_MAVEN

# Until we integrate the deprepkg branch into master and sbt knows
#  the true project/submodule dependencies, we need to execute sbt commands
#  in a specific directory order and do a publishLocal at the end
#  so the results are available to later submodules.
EXPLICIT_SUBMODULES=firrtl firrtl-interpreter treadle chisel3 diagrammer chisel-testers dsptools rocket-chip testchipip

# The following targets need a publishLocal so their results are available.
NEED_PUBLISHING = compile test +compile +test

# The argument, $(1) is the list of sbt commands to execute.
# Set a Make variable with "publishLocal" if we need to add publishLocal
#  to the sbt command list.
define doSBT
$(eval publishlocal=$(if $(filter $(NEED_PUBLISHING),$(1)),$(if $(findstring +,$(1)),+publishLocal,publishLocal)))
	for c in $(EXPLICIT_SUBMODULES); do ( echo $$c && cd $$c && $(SBT) $(1) $(publishlocal) ) || exit 1; done
	echo rocket-dsptools && cd dsptools && $(SBT) "project rocket-dsptools" "$(1)" || exit 1
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

.DEFAULT:
	$(call doSBT,$@)

.PHONY: clean +clean compile coverage default publishLocal publishLocalSigned
