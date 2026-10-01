using Pkg

# These packages are bundled in this repository. Develop the local sources so that
# the manual always documents the same Corleone and sublibrary revisions.
Pkg.develop(
    [
        PackageSpec(path = joinpath(@__DIR__, "..")),
        PackageSpec(path = joinpath(@__DIR__, "..", "lib", "CorleoneOED")),
        PackageSpec(path = joinpath(@__DIR__, "..", "lib", "OptimalControlBenchmarks")),
    ]
)

using Documenter, Corleone, CorleoneOED, OptimalControlBenchmarks, SymbolicUtils
using DocumenterInterLinks
using DocumenterCitations
using Literate
using Dates
using YAML, JSON

# Include the interlinks
include("interlinks.jl")
# Process the tutorials
include("process_tutorials.jl")
# Include the bibliography
bib = CitationBibliography(joinpath(@__DIR__, "src", "assets", "bibliography.bib"))

# Documenter walks every docstring in `modules` for doctests. Keep only the four
# SymbolicUtils bindings we surface in api.md so Corleone's docs do not run the
# rest of SymbolicUtils's doctest suite.
const _SYMBOLICUTILS_DOC_NAMES = (:Unknown, :shape, :scalarize, :unwrap)
let meta = Docs.meta(SymbolicUtils)
    for binding in collect(keys(meta))
        binding.var in _SYMBOLICUTILS_DOC_NAMES || delete!(meta, binding)
    end
end

# checkdocs_ignored_modules only skips these modules when discovered as
# submodules; SymbolicUtils itself stays in `modules` so `@docs` can resolve
# the four bindings above. Ignore SymbolicUtils's own submodules so checkdocs
# does not demand their docstrings in this manual.
const _SYMBOLICUTILS_CHECKDOCS_IGNORE = Module[
    getfield(SymbolicUtils, name)
        for name in names(SymbolicUtils; all = true)
        if Base.isidentifier(name) &&
        isdefined(SymbolicUtils, name) &&
        getfield(SymbolicUtils, name) isa Module &&
        parentmodule(getfield(SymbolicUtils, name)) === SymbolicUtils
]

makedocs(
    sitename = "Corleone.jl",
    authors = "Carl Julius Martensen, Christoph Plate, et al.",
    modules = [Corleone, CorleoneOED, OptimalControlBenchmarks, SymbolicUtils],
    format = Documenter.HTML(
        assets = ["assets/favicon.ico"],
        canonical = "https://docs.sciml.ai/Corleone/stable/",
        size_threshold = 1_500_000,  # bytes
    ),
    doctest = true,
    checkdocs = :exports,
    checkdocs_ignored_modules = _SYMBOLICUTILS_CHECKDOCS_IGNORE,
    linkcheck = true,
    #DocumenterVitepress.MarkdownVitepress(
    #    repo = "github.com/SciML/Corleone.jl",
    #    devbranch = "main", # or master, trunk, ...
    #    devurl = "dev",
    # if you use something else than yourname.github.io/YourPackage.jl
    #),
    pages = [
        "Home" => "index.md",
        "Getting Started" => "examples/the_linear_quadratic_regulator.md",
        "Tutorials" => [
            "Linear Quadratic Regulator" => "examples/the_linear_quadratic_regulator.md",
            "Lotka Volterra Fishing" => "examples/the_lotka_volterra_fishing_problem.md",
            "Optimal Experimental Design" => "examples/the_lotka_volterra_optimal_experimental_design_problem.md",
            "Discrete measurements" => "examples/compartmental_oed_problem.md",
            "Multiexperiments" => "examples/the_lotka_volterra_multiexperiment_problem.md",
            "ModelingToolkit Integration" => "examples/modelingtoolkit_integration.md",
        ], #"tutorials.md",
        "References" => "references.md",
        "API" => "api.md",
        #tutorials,
        #"Examples" => [#"Optimal Control" => "./examples/lotka.md",
        #"Multiple Shooting" => "./examples/multiple_shooting.md",
        # "Optimal Experimental Design" => "./examples/lotka_oed.md",
        #"Multiexperiments" => "./examples/multiexperiments.md"
        #],
        # "API Reference" => "api.md",
    ],
    remotes = nothing,
    plugins = [links, bib],
)

deploydocs(
    repo = "github.com/SciML/Corleone.jl";
    push_preview = true
)
#DocumenterVitepress.deploydocs(;
#    repo="github.com/SciML/Corleone.jl",
#    target=joinpath(@__DIR__, "build"),
#    branch="gh-pages",
#    devbranch="main", # or master, trunk, ...
#    push_preview=true,
#)
