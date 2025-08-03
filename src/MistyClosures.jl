module MistyClosures

using Core: OpaqueClosure
using Core.Compiler: IRCode

import Base: show

# As of 2.0, MistyClosure contains a reference to its IR. This is because `IRCode` is
# a surprisingly bulky type (136B in 1.11.1 -- the same as 17 Float64s). Since especially
# fast access to `ir` is never needed, it is fine to store it out-of-place, thus reducing
# the size of a `MistyClosure` from 176B to 48B. This can have a substantial impact on the
# performance of calling many `OpaqueClosure`s of the same type.
struct MistyClosure{Toc<:OpaqueClosure}
    oc::Toc
    ir::Base.RefValue{IRCode}
end

function MistyClosure(ir::IRCode, env...; kwargs...)
    return MistyClosure(OpaqueClosure(ir, env...; kwargs...), Ref(ir))
end

(mc::MistyClosure)(x::Vararg{Any, N}) where {N} = mc.oc(x...)

# You can't deepcopy an `IRCode` because it contains a module.
function Base.deepcopy_internal(x::T, dict::IdDict) where {T<:MistyClosure}
    return T(Base.deepcopy_internal(x.oc, dict), x.ir)
end

# Don't print out the IRCode object, because this tends to pollute the REPL. Just make it
# clear that this is a MistyClosure, which contains an OpaqueClosure.
show(io::IO, mime::MIME"text/plain", mc::MistyClosure) = _show_misty_closure(io, mime, mc)
show(io::IO, mc::MistyClosure) = _show_misty_closure(io, MIME"text/plain"(), mc)

function _show_misty_closure(io::IO, mime::MIME"text/plain", mc::MistyClosure)
    print(io, "MistyClosure ")
    show(io, mime, mc.oc)
end

export MistyClosure

end
