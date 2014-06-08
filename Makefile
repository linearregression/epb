.PHONY: all clean compile eunit test qc
REBAR ?= ./rebar

all: compile

deps:
	@${REBAR} get-deps

clean:
	rm -rf current_counterexample.eqc erl_crash.dump
	@${REBAR} clean

compile: deps
	@${REBAR} compile

qc: compile
	@${REBAR} qc skip_deps=true

eunit: compile
	@${REBAR} eunit skip_deps=true

test: eunit qc

dialyze: compile
	@dialyzer ebin/*.beam
