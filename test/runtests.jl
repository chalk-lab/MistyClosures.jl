using MistyClosures, Test

using Core: OpaqueClosure

struct Foo
    x::Float64
end

(f::Foo)(y) = f.x * y

function _fix_ir(ir)
    @static if VERSION ≥ v"1.12.0-"
        # replace `argtypes[1]` if it is not `Core.Const(sin)`, e.g., it is a callable object
        ir.argtypes[1] = ir.argtypes[1] isa Core.Const ? Tuple{} : Tuple{ir.argtypes[1]}
    end
    return ir
end

@testset "MistyClosures.jl" begin
    ir = Base.code_ircode_by_type(Tuple{typeof(sin), Float64}) |> only |> first

    # Recommended constructor.
    mc = MistyClosure(ir; do_compile=true)
    @test @inferred(mc(5.0)) == sin(5.0)

    # Default constructor.
    ir_fixed = _fix_ir(ir)
    mc_default = MistyClosure(OpaqueClosure(ir_fixed; do_compile=true), Ref(ir_fixed))
    @test @inferred(mc_default(5.0) == sin(5.0))

    # Recommended constructor with env.
    ir_foo = Base.code_ircode_by_type(Tuple{Foo, Float64}) |> only |> first
    mc_with_env = MistyClosure(ir_foo, 5.0; do_compile=true)
    @test @inferred(mc_with_env(4.0)) == Foo(5.0)(4.0)

    # Default constructor with env.
    ir_foo_fixed = _fix_ir(ir_foo)
    mc_env_default = MistyClosure(OpaqueClosure(ir_foo_fixed, 4.0; do_compile=true), Ref(ir_foo_fixed))
    @test @inferred(mc_env_default(5.0) == Foo(5.0)(4.0))

    # deepcopy
    @test deepcopy(mc) isa typeof(mc)

    # printing -- we shouldn't see the IRCode, because it's often quite a lot.
    io = IOBuffer()
    show(io, mc)
    @test String(take!(io)) == "MistyClosure (::Float64)::Float64->◌"
end
