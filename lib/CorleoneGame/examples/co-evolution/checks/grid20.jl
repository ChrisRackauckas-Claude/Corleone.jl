# Check on the 20-interval grid only, fresh start (0.3,0), damping 0.2, max 300 rounds.
# Run from lib/CorleoneGame: julia --project=. examples/co-evolution/checks/grid20.jl 2.0 0.5 0.25
include(joinpath(@__DIR__, "..", "simple.jl"))
using CorleoneGame
using .CoEvolutionSimple
C = CoEvolutionSimple
for mu in parse.(Float64, ARGS)
    a = C.Parameters(; mu)
    g = C.game(a)
    o = C.algorithm_options(; refined_intervals=20, damping=0.2, max_rounds=300)
    r = solve_game(g; options=o, workspace=Workspace())
    run = last(r.runs); d = C.designer(run.trajectory.x[:, end], a)
    println("CHECK μ=$mu converged=$(r.converged) rounds=$(length(run.history)) Φ=$(round(d.Phi;digits=4)) ∫u_B=$(round(d.body_adaptation;digits=3)) b(T)=$(round(run.trajectory.x[1,end];digits=3)) p(T)=$(round(run.trajectory.x[2,end];digits=3))")
    println("  u_P=", round.(run.controls[2,:];digits=2))
    flush(stdout)
end
