set dotenv-load := false

[private]
default:
    @just --list

test:
    julia --project -e 'using Pkg; Pkg.test()'

docs:
    julia --project=docs -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate()'
    julia --project=docs docs/make.jl

docs-llms:
    julia --project=docs docs/build_llms.jl
