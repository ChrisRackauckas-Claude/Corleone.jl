module CorleoneReverseDiffExtension
using Corleone
using ReverseDiff

Corleone._untrack_container(x::ReverseDiff.TrackedArray) = [x[i] for i in eachindex(x)]

end
