SBT=sbt

# Until we integrate the deprepkg branch into master and sbt knows
#  the true project/submodule dependencies, we need to execute sbt commands
#  in a specific directory order and do a publish-local at the end
#  so the results are available to later submodules.
EXPLICIT_SUBMODULES=firrtl firrtl-interpreter chisel3 chisel-testers
# The following targets need a publish-local so their results are available.
NEED_PUBLISHING = compile test

# The argument, $(1) is the list of sbt commands to execute.
# Set a Make variable with "publish-local" if we need add publish-local
#  to the sbt command list.
define doSBT
$(eval publishlocal=$(if $(filter $(NEED_PUBLISHING),$(1)),publish-local,))
	for c in $(EXPLICIT_SUBMODULES); do ( echo $$c && cd $$c && $(SBT) $(1) $(publishlocal) ) || exit 1; done
endef

default compile:
	$(call doSBT,compile)

clean:
	$(call doSBT,clean)
	find . -depth -type d \( -name target -o -name test_run_dir \) -execdir echo rm -rf {}"/*" \;

coverage:
	$(call doSBT,clean coverage test)
	$(call doSBT,coverageReport)

test:
	$(call doSBT,test)

publish-local:
	$(call doSBT,publish-local)

.DEFAULT:
	$(call doSBT,$@)

.PHONY: clean compile default test publish-local
