using MistyClosures, Test

using Core: OpaqueClosure

struct Foo
    x::Float64
end

# We wrap `Foo` inside `Tuple{Foo}` to satisfy opaque closure assumption 
# that its first argument has to be a `Tuple` storing captured variables
(f::Tuple{Foo})(y) = f[1].x * y

@testset "MistyClosures.jl" begin
    ir = Base.code_ircode_by_type(Tuple{typeof(sin), Float64}) |> only |> first
    ir.argtypes[1] = Tuple{}

    # Recommended constructor.
    mc = MistyClosure(ir; do_compile=true)
    @test @inferred(mc(5.0)) == sin(5.0)

    # Default constructor.
    mc_default = MistyClosure(OpaqueClosure(ir; do_compile=true), Ref(ir))
    @test @inferred(mc_default(5.0) == sin(5.0))

    # Recommended constructor with env.
    ir_foo = Base.code_ircode_by_type(Tuple{Tuple{Foo}, Float64}) |> only |> first
    mc_with_env = MistyClosure(ir_foo, Foo(5.0); do_compile=true)
    @test @inferred(mc_with_env(4.0)) == (Foo(5.0),)(4.0)

    # Default constructor with env.
    mc_env_default = MistyClosure(OpaqueClosure(ir_foo, Foo(5.0); do_compile=true), Ref(ir_foo))
    @test @inferred(mc_env_default(5.0) == (Foo(5.0),)(4.0))

    # deepcopy
    @test deepcopy(mc) isa typeof(mc)

    # printing -- we shouldn't see the IRCode, because it's often quite a lot.
    io = IOBuffer()
    show(io, mc)
    @test String(take!(io)) == "MistyClosure (::Float64)::Float64->◌"
end
