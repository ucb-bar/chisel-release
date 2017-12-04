SBT=sbt

default compile:
	$(SBT) compile

clean +clean:
	$(SBT) $@
	find . -depth -type d \( -name target -o -name test_run_dir \) -execdir echo rm -rf {}"/*" \;

coverage:
	$(SBT) clean coverage test
	$(SBT) coverageReport coverageAggregate

publishLocal publish-local:
	$(SBT) publishLocal

.DEFAULT:
	$(SBT) $@

.PHONY: clean +clean compile coverage default publish-local publishLocal
