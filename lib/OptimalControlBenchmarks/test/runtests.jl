using OptimalControlBenchmarks
using Test
using SafeTestsets

# Centralized sublibrary CI sets CORLEONE_TEST_GROUP to the bare package name
# (-> "Core") or "<pkg>_<grp>" (-> "<grp>"). Fall back to GROUP, then "All", so
# local `Pkg.test()` runs (which set neither) run everything. Map the value to
# the standard Core/QA section names this file dispatches on.
const _G = get(ENV, "CORLEONE_TEST_GROUP", get(ENV, "GROUP", "All"))
const _SUB = "OptimalControlBenchmarks"
const GROUP = _G == _SUB ? "Core" : (startswith(_G, _SUB * "_") ? _G[(length(_SUB) + 2):end] : _G)

if GROUP == "All" || GROUP == "Core"
    # No Core unit tests yet; running the benchmarks requires the full MTK +
    # Ipopt/MOI optimal-control stack and is too expensive for CI. Keep a
    # trivial assertion so the Core group still emits a Test Summary.
    @test 1 == 1
end

if GROUP == "All" || GROUP == "QA"
    @safetestset "Code quality (Aqua.jl)" begin
        using Aqua
        using OptimalControlBenchmarks
        Aqua.test_all(OptimalControlBenchmarks)
    end
end
