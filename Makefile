SBT=sbt

# Until we integrate the deprepkg branch into master and sbt knows
#  the true project/submodule dependencies, we need to execute sbt commands
#  in a specific directory order and do a publishLocal at the end
#  so the results are available to later submodules.
EXPLICIT_SUBMODULES=firrtl firrtl-interpreter chisel3 chisel-testers dsptools
# The following targets need a publishLocal so their results are available.
NEED_PUBLISHING = compile test +compile +test

# The argument, $(1) is the list of sbt commands to execute.
# Set a Make variable with "publishLocal" if we need add publishLocal
#  to the sbt command list.
define doSBT
$(eval publishlocal=$(if $(filter $(NEED_PUBLISHING),$(1)),$(if $(findstring +,$(1)),+publishLocal,publishLocal)))
	for c in $(EXPLICIT_SUBMODULES); do ( echo $$c && cd $$c && $(SBT) $(1) $(publishlocal) ) || exit 1; done
endef

default compile:
	$(call doSBT,compile)

clean +clean:
	$(SBT) $@
	find . -depth -type d \( -name target -o -name test_run_dir \) -execdir echo rm -rf {}"/*" \;

coverage:
	$(call doSBT, clean coverage test)
	$(SBT) coverageReport coverageAggregate

publish-local:
	$(call doSBT,publishLocal)

.DEFAULT:
	$(call doSBT,$@)

.PHONY: clean +clean compile coverage default publish-local
