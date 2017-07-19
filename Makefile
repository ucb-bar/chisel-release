SBT=sbt

# Until we integrate the deprepkg branch into master and sbt knows
#  the true project/submodule dependencies, we need to execute sbt commands
#  in a specific directory order and do a publish-local at the end
#  so the results are available to later submodules.
EXPLICIT_SUBMODULES=firrtl firrtl-interpreter chisel3 chisel-testers
define doSBT
	for c in $(EXPLICIT_SUBMODULES); do ( echo $$c && cd $$c && $(SBT) $(1) publish-local ) || exit 1; done
endef

default compile:
	$(call doSBT,compile)

clean:
	$(SBT) clean
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
