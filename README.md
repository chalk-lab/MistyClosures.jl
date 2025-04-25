# MistyClosures

[![Build Status](https://github.com/chalk-lab/MistyClosures.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/chalk-lab/MistyClosures.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)
[![ColPrac: Contributor's Guide on Collaborative Practices for Community Packages](https://img.shields.io/badge/ColPrac-Contributor's%20Guide-blueviolet)](https://github.com/SciML/ColPrac)

Marginally less opaque closures.

Specifically, a `MistyClosure` is comprises an `OpaqueClosure` paired with the `IRCode` that defines it.
This is useful if you generate an `OpaqueClosure`, and want to be able to retrieve the `IRCode` later on.

## Recommended Use

```julia
# Get the `IRCode` associated to `sin(5.0)`.
ir = Base.code_ircode_by_type(Tuple{typeof(sin), Float64})[1][1]

# Produce a `MistyClosure` using it. All kwargs are passed to the `OpaqueClosure`
# constructor.
mc = MistyClosure(ir; do_compile=true)

# Call it.
mc(5.0) == sin(5.0)
```

## Alterative Use

Sometimes you'll already have an `OpaqueClosure` lying around, and not want to produce a new one from an `IRCode` (as this often takes a surprisingly large amount of time).
If ths is the case, you can simply use the default constructor for `MistyClosure`.
That is, write
```julia
mc = MistyClosure(existing_opaque_closure, ir)
```
Of course, it is _your_ responsibility so ensure that `ir` and `existing_opaque_closure` are in agreement.
