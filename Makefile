JULIA ?= julia
export JULIA_DEPOT_PATH := $(CURDIR)/.julia-depot
export JULIA_NUM_THREADS := 1
export JULIA_NUM_PRECOMPILE_TASKS := 1
export OPENBLAS_NUM_THREADS := 1
export OMP_NUM_THREADS := 1
export VECLIB_MAXIMUM_THREADS := 1
.PHONY: setup test smoke pilot crosscheck
setup:
	$(JULIA) --startup-file=no --project=. -e 'using Pkg; Pkg.instantiate()'
test:
	$(JULIA) --startup-file=no --project=. -e 'using Pkg; Pkg.test()'
smoke:
	$(JULIA) --startup-file=no --project=. scripts/run.jl smoke
pilot:
	$(JULIA) --startup-file=no --project=. scripts/run.jl pilot
crosscheck:
	$(JULIA) --startup-file=no --project=. scripts/run.jl crosscheck
