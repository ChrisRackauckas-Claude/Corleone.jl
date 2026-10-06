# Co-evolution of an adaptive body and a designed adaptive implant: the simplest case.
# Independent of the benchmark library; it only uses the CorleoneGame.jl solver.
# Run from lib/CorleoneGame: julia --project=. examples/co-evolution/simple.jl
#
# Inner game (open-loop Nash equilibrium, computed by CorleoneGame):
#   body    B: b' = u_B (p - b),  u_B in [0,1]   rate at which the body adapts to the implant
#   implant P: p' = u_P (b - p),  u_P in [-1,1]  u_P > 0 yields to the body, u_P < 0 leads away
#   J_B = ∫ (p-b)^2 + w_s (b-s)^2 + c_B u_B^2 dt      mismatch, homeostatic attachment, plasticity cost
#   J_P = ∫ μ (p-b)^2 + (b-h)^2 + c_P u_P^2 dt        designed adaptation goal of the implant
# Outer design problem (control of adaptation): choose the implant's mismatch weight μ
# such that the co-evolved equilibrium minimizes the designer's criterion
#   Φ = ∫ (p-b)^2 + (b-h)^2 + c_P u_P^2 dt,
# i.e., the designer values integration and health equally. The sincere design μ = 1
# gives the implant exactly the designer's objective.
using CorleoneGame
module CoEvolutionSimple
using CorleoneGame
using CairoMakie, Printf

Base.@kwdef struct Parameters
    T::Float64 = 10.0
    b0::Float64 = 0.0     # body starts in its diseased state ...
    s::Float64 = 0.0      # ... which is also its homeostatic set point
    h::Float64 = 1.0      # healthy state, known to the designer
    p0::Float64 = 1.0     # implant is set to the healthy state at implantation
    w_s::Float64 = 0.2    # body's attachment to its set point
    c_B::Float64 = 0.1    # body's cost of plasticity
    c_P::Float64 = 0.1    # implant's cost of adaptation
    mu::Float64 = 1.0     # designed weight of mismatch in the implant's objective
    uB_max::Float64 = 1.0
    uP_max::Float64 = 1.0
end

# States: b, p, then quadratures ∫(p-b)^2, ∫(b-h)^2, ∫(b-s)^2, ∫u_B^2, ∫u_P^2, ∫u_B.
function dynamics!(dx, x, u, t, a)
    b, p = x[1], x[2]
    uB, uP = u[1], u[2]
    dx[1] = uB * (p - b)
    dx[2] = uP * (b - p)
    dx[3] = (p - b)^2
    dx[4] = (b - a.h)^2
    dx[5] = (b - a.s)^2
    dx[6] = uB^2
    dx[7] = uP^2
    dx[8] = uB
    return nothing
end

objective(x, player, a) = player == 1 ? x[3] + a.w_s * x[5] + a.c_B * x[6] :
                                        a.mu * x[3] + x[4] + a.c_P * x[7]

"Designer criterion and its parts, evaluated on the final state with quadratures."
designer(x, a) = (; Phi = x[3] + x[4] + a.c_P * x[7], mismatch = x[3], health = x[4],
    effort = a.c_P * x[7], body_adaptation = x[8])

function game(a=Parameters())
    a.mu >= 0 && a.w_s >= 0 && min(a.c_B, a.c_P, a.T, a.uB_max, a.uP_max) > 0 ||
        error("Invalid parameters")
    return Game(; name="Co-evolution (simple), μ=$(a.mu)",
        state_labels=["b: body", "p: implant"],
        control_labels=["u_B: body adaptation rate", "u_P: implant adaptation rate"], owners=[1, 2],
        dynamics! = (dx, x, u, t) -> dynamics!(dx, x, u, t, a),
        objective=(x, i) -> objective(x, i, a),
        x0=[a.b0, a.p0, 0, 0, 0, 0, 0, 0], T=a.T, quadratures=collect(3:8),
        lower=[0.0, -a.uP_max], upper=[a.uB_max, a.uP_max], initial=[0.3a.uB_max, 0.0],
        metadata=a)
end

# Damping 0.2: with 0.5 the sweeps cycle for intermediate μ.
algorithm_options(; kwargs...) = Options(; merge((; shooting=:single, intervals=20,
    refined_intervals=40, damping=0.2, max_rounds=300), (; kwargs...))...)

# Two initial policies on the coarse grid; the game may have several equilibria
# (who yields to whom), and the starting policy can select among them.
const STARTS = (default=[0.3, 0.0], yielding=[0.1, 1.0])
initial_policy(start, n) = repeat(STARTS[start], 1, n)

"Solve the inner game for each design μ and start; returns one record per pair."
function scan(mus; base=Parameters(), options=algorithm_options(), starts=keys(STARTS))
    records = NamedTuple[]
    for mu in mus, start in starts
        fields = (; (f => getfield(base, f) for f in fieldnames(Parameters))...)
        a = Parameters(; merge(fields, (; mu))...)
        g = game(a)
        # A fresh workspace per solve: no warm start carries over between designs.
        result = solve_game(g; options, workspace=Workspace(), initial=initial_policy(start, options.intervals))
        run = last(result.runs)
        tr = run.trajectory
        d = designer(tr.x[:, end], a)
        @printf("μ=%.3f start=%s converged=%s Φ=%.4f mismatch=%.4f health=%.4f effort=%.4f ∫u_B=%.3f b(T)=%.3f p(T)=%.3f\n",
            mu, start, result.converged, d.Phi, d.mismatch, d.health, d.effort, d.body_adaptation,
            tr.x[1, end], tr.x[2, end])
        flush(stdout)
        push!(records, (; mu, start, a, converged=result.converged,
            rounds=[length(r.history) for r in result.runs], trajectory=tr, controls=run.controls, d...))
    end
    return records
end

function write_csv(records, folder)
    open(joinpath(folder, "design_scan.csv"), "w") do io
        println(io, "mu,start,converged,rounds_coarse,rounds_refined,Phi,mismatch,health,effort,body_adaptation,b_T,p_T")
        for r in records
            println(io, join((r.mu, r.start, r.converged, r.rounds..., r.Phi, r.mismatch, r.health, r.effort,
                r.body_adaptation, r.trajectory.x[1, end], r.trajectory.x[2, end]), ","))
        end
    end
    for r in records
        tag = replace(@sprintf("%.3f", r.mu), "." => "p") * "_" * string(r.start)
        open(joinpath(folder, "trajectory_mu$(tag).csv"), "w") do io
            println(io, "time,b,p")
            for k in eachindex(r.trajectory.t)
                println(io, r.trajectory.t[k], ",", r.trajectory.x[1, k], ",", r.trajectory.x[2, k])
            end
        end
        open(joinpath(folder, "controls_mu$(tag).csv"), "w") do io
            n = size(r.controls, 2)
            println(io, "t_start,t_end,u_B,u_P")
            for k in 1:n
                println(io, (k - 1) * r.a.T / n, ",", k * r.a.T / n, ",", r.controls[1, k], ",", r.controls[2, k])
            end
        end
    end
end

"Piecewise-constant profile as step coordinates."
steps(T, u) = (vcat(range(0, T; length=length(u) + 1)...), vcat(u, u[end]))

function plot_summary(records, path; shown=(0.0, 1.0))
    a = first(records).a
    colors = Makie.wong_colors()
    f = Figure(size=(1300, 820), fontsize=17)
    ax1 = Axis(f[1, 1]; xlabel="t", ylabel="state", title="(a) Co-evolution of body and implant")
    ax2 = Axis(f[1, 2]; xlabel="t", ylabel="adaptation rate", title="(b) Equilibrium adaptation rates")
    hlines!(ax1, [a.h]; color=:gray60, linestyle=:dash)
    text!(ax1, 0.2, a.h; text="healthy h", align=(:left, :bottom), color=:gray40, fontsize=14)
    hlines!(ax2, [0.0]; color=:gray80)
    for (k, mu) in enumerate(shown)
        r = records[findfirst(r -> r.mu == mu && r.start == :default, records)]
        name = mu == 1 ? "sincere implant μ=1" : "designed implant μ=$(mu)"
        style = k == 1 ? :solid : :dash
        lines!(ax1, r.trajectory.t, r.trajectory.x[1, :]; color=colors[1], linestyle=style, linewidth=3,
            label="body b, $(name)")
        lines!(ax1, r.trajectory.t, r.trajectory.x[2, :]; color=colors[2], linestyle=style, linewidth=3,
            label="implant p, $(name)")
        stairs!(ax2, steps(a.T, r.controls[1, :])...; step=:post, color=colors[1], linestyle=style,
            linewidth=3, label="u_B, $(name)")
        stairs!(ax2, steps(a.T, r.controls[2, :])...; step=:post, color=colors[2], linestyle=style,
            linewidth=3, label="u_P, $(name)")
    end
    axislegend(ax1; position=:rb, labelsize=13)
    axislegend(ax2; position=:rt, labelsize=13)
    ax3 = Axis(f[2, 1]; xlabel="designed mismatch weight μ of the implant",
        ylabel="designer criterion", title="(c) Outcome of the co-evolution per design")
    # Lines: default start; markers: all solves (filled converged, open not converged).
    default = filter(r -> r.start == :default, records)
    for (field, label, c) in ((:Phi, "Φ (total)", :black), (:health, "∫(b-h)² health", colors[3]),
        (:mismatch, "∫(p-b)² mismatch", colors[4]), (:effort, "c_P∫u_P² effort", colors[5]))
        lines!(ax3, [r.mu for r in default], [getfield(r, field) for r in default]; color=c, label, linewidth=2.5)
        for r in records
            scatter!(ax3, [r.mu], [getfield(r, field)]; color=r.converged ? c : :white, strokecolor=c,
                strokewidth=1.5, marker=r.start == :default ? :circle : :utriangle, markersize=11)
        end
    end
    vlines!(ax3, [1.0]; color=:gray60, linestyle=:dot)
    axislegend(ax3; position=:lt, labelsize=13)
    ax4 = Axis(f[2, 2]; xlabel="designed mismatch weight μ of the implant", ylabel="∫u_B dt",
        title="(d) Total adaptation of the body")
    lines!(ax4, [r.mu for r in default], [r.body_adaptation for r in default]; color=colors[1], linewidth=2.5)
    for r in records
        scatter!(ax4, [r.mu], [r.body_adaptation]; color=r.converged ? colors[1] : :white, strokecolor=colors[1],
            strokewidth=1.5, marker=r.start == :default ? :circle : :utriangle, markersize=11)
    end
    Label(f[3, 1:2], "Markers: ● start (u_B,u_P)=(0.3,0), ▲ start (0.1,1); open markers: round limit reached (not certified)";
        fontsize=14, color=:gray30)
    vlines!(ax4, [1.0]; color=:gray60, linestyle=:dot)
    save(path, f)
    return path
end

function main(; mus=[0.0, 0.1, 0.25, 0.5, 1.0, 2.0], base=Parameters(), options=algorithm_options(),
        folder=joinpath(@__DIR__, "output"))
    mkpath(folder)
    records = scan(mus; base, options)
    write_csv(records, folder)
    plot_summary(records, joinpath(folder, "simple.png"))
    println("Wrote ", folder)
    return records
end
end

if abspath(PROGRAM_FILE) == @__FILE__
    CoEvolutionSimple.main()
end
