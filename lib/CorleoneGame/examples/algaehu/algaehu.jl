# Category: seasonal
# A finite bloom changes abundance and storage; no within-model seasonal reset.
# Genus-level synthetic nutrient-storage game.
using CorleoneGame
module AlgaeHu
using CorleoneGame

const GENERA = (:Rhodomonas,:Cryptomonas,:Ceratium,:Peridinium,:Fragilaria,:Tabellaria)
# Synthetic contrasts, NOT fitted traits or inferred SHAP coefficients.
function trait(genera,values)
    all(g->g in GENERA,genera) || error("Unknown genus; choose from $GENERA")
    return Float64[values[findfirst(==(g),GENERA)] for g in genera]
end

Base.@kwdef struct Parameters
    genera::Vector{Symbol} = collect(GENERA[1:5])
    T::Float64 = 14.0
    D::Float64 = 0.05
    B0::Float64 = 1.0
    mu_max::Vector{Float64} = trait(genera,(1.0,.9,.65,.70,.85,.75))
    rho_max::Vector{Float64} = trait(genera,(.025,.022,.018,.020,.024,.020))
    K_P::Vector{Float64} = trait(genera,(.010,.008,.006,.009,.012,.008))
    K_N::Vector{Float64} = trait(genera,(.15,.12,.10,.14,.18,.12))
    K_I::Vector{Float64} = trait(genera,(45,35,30,40,50,30))
    kappa::Vector{Float64} = trait(genera,(1.0,1.1,1.3,1.2,.9,.8))
    temperature_opt::Vector{Float64} = trait(genera,(16,16,18,18,14,12))
    temperature_width::Vector{Float64} = trait(genera,(12,12,10,10,10,8))
    conductivity_opt::Vector{Float64} = trait(genera,(800,800,1000,1000,600,300))
    conductivity_width::Vector{Float64} = trait(genera,(1500,1500,1200,1200,1000,500))
    mortality::Vector{Float64} = fill(.03,length(genera))
    qmin::Vector{Float64} = fill(.005,length(genera))
    qmax::Vector{Float64} = fill(.04,length(genera))
    nu_N::Vector{Float64} = fill(.10,length(genera))
    nu_Si::Vector{Float64} = trait(genera,(0,0,0,0,.20,.20))
    K_Si::Vector{Float64} = fill(.15,length(genera))
    eta::Float64 = .10
    depth::Float64 = 1.0
    k_background::Float64 = .20
    light_mean::Float64 = 150.0
    # Daily-mean light: 20-40 control intervals per 14-day season cannot resolve a
    # diurnal cycle, and sampling it produces aliased, chattering allocations.
    light_amplitude::Float64 = 0.0
    light_period::Float64 = 1.0
    temperature::Float64 = 16.0
    conductivity::Float64 = 800.0
    inflow::NTuple{3,Float64} = (1.0,.06,.5) # dissolved N, P, Si; mg element/L
    resources0::NTuple{3,Float64} = inflow
    biomass0::Vector{Float64} = fill(.2,length(genera)) # mg dry biomass/L
    quota0::Vector{Float64} = fill(.02,length(genera)) # mg P / mg dry biomass
    initial::Vector{Float64} = fill(.5,length(genera))
    weights::Matrix{Float64} = repeat([.6 .3 .1],length(genera),1)
    # Seasonal cap on squared phosphorus-acquisition effort (uptake machinery).
    budgets::Vector{Union{Nothing,Float64}} = fill(0.8,length(genera))
    floors::Vector{Union{Nothing,Float64}} = fill(nothing,length(genera))
end

function algorithm_options(;kwargs...)
    return Options(;kwargs...)
end

function validate_parameters(a)
    n=length(a.genera)
    n>=2 && length(unique(a.genera))==n && all(g->g in GENERA,a.genera) || error("Choose at least two distinct supported genera")
    for f in fieldnames(Parameters)
        f in (:genera,:budgets,:floors) && continue
        v=getfield(a,f)
        all(isfinite,v isa Number ? (v,) : v) || error("Nonfinite $f")
        v isa Vector && length(v)!=n && error("Wrong length for $f")
    end
    for f in (:K_P,:K_N,:K_I,:K_Si,:qmin,:temperature_width,:conductivity_width,:biomass0,:nu_N)
        all(>(0),getfield(a,f)) || error("$f must be positive")
    end
    for f in (:mu_max,:rho_max,:mortality,:kappa,:nu_Si,:conductivity_opt)
        all(>=(0),getfield(a,f)) || error("$f must be nonnegative")
    end
    all(a.qmin .< a.qmax) && all(a.qmin .<= a.quota0 .<= a.qmax) || error("Invalid quotas")
    all(x->x>0,(a.T,a.B0,a.depth,a.k_background,a.light_period)) || error("Invalid positive scale")
    min(a.D,a.light_mean,a.conductivity,a.inflow...,a.resources0...)>=0 || error("Invalid environment")
    0<a.eta<1 && 0<=a.light_amplitude<=1 && all(0 .<= a.initial .<= 1) || error("Invalid allocation/light setting")
    size(a.weights)==(n,3) && all(a.weights .>= 0) && all(abs.(sum(a.weights;dims=2).-1).<=1e-12) || error("Invalid weights")
    length(a.budgets)==length(a.floors)==n || error("Wrong constraint dimensions")
    for i in 1:n
        b,f=a.budgets[i],a.floors[i]
        b===nothing || isfinite(b)&&b>=0 || error("Invalid effort budget")
        f===nothing || isfinite(f)&&0<f<=a.biomass0[i] || error("Invalid density floor")
    end
    return nothing
end

habitat(a,i) = exp(-((a.temperature-a.temperature_opt[i])/a.temperature_width[i])^2-
    ((a.conductivity-a.conductivity_opt[i])/a.conductivity_width[i])^2)

"Physical rates, with a bounded extension for infeasible multiple-shooting trials."
function rates(x,u,t,a)
    n=length(a.genera)
    X=exp.(x[1:n])
    q=clamp.(x[n+1:2n],a.qmin,a.qmax)
    N,P,Si=max.(x[2n+1:2n+3],0)
    antenna=a.eta .+(1-a.eta).*(1 .-u)
    acquisition=a.eta .+(1-a.eta).*u
    z=a.depth*(a.k_background+sum(a.kappa.*antenna.*X))
    incident=a.light_mean*(1+a.light_amplitude*cos(2pi*t/a.light_period))
    light=incident*(-expm1(-z))/z
    mu=similar(X,promote_type(eltype(X),eltype(u))); rho=similar(mu)
    for i in 1:n
        si=a.nu_Si[i]>0 ? Si/(a.K_Si[i]+Si) : one(Si)
        ell=antenna[i]*light/(a.K_I[i]+antenna[i]*light)
        mu[i]=a.mu_max[i]*habitat(a,i)*ell*(1-a.qmin[i]/q[i])*N/(a.K_N[i]+N)*si
        rho[i]=a.rho_max[i]*acquisition[i]*P/(a.K_P[i]+P)*(a.qmax[i]-q[i])/(a.qmax[i]-a.qmin[i])
    end
    return (;X,q,N,P,Si,mu,rho,light)
end

# Numerical states: log X (n), P quotas (n), N/P/Si (3), costs (n), efforts (n).
function dynamics!(dx,x,u,t,a)
    n=length(a.genera); k=2n+3
    r=rates(x,u,t,a)
    for i in 1:n
        dx[i]=r.mu[i]-a.D-a.mortality[i]
        dx[n+i]=r.rho[i]-r.mu[i]*r.q[i]
        dx[k+i]=(-a.weights[i,2]*r.X[i]/a.B0+a.weights[i,3]*u[i]^2)/a.T
        dx[k+n+i]=u[i]^2
    end
    dx[2n+1]=a.D*(a.inflow[1]-r.N)-sum(a.nu_N.*r.mu.*r.X)
    dx[2n+2]=a.D*(a.inflow[2]-r.P)-sum(r.rho.*r.X)
    dx[2n+3]=a.D*(a.inflow[3]-r.Si)-sum(a.nu_Si.*r.mu.*r.X)
    return nothing
end

function constraints(a)
    n=length(a.genera); result=StateConstraint[]
    for i in 1:n
        a.budgets[i]===nothing || push!(result,StateConstraint(player=i,index=3n+3+i,
            label="squared budget u$(subscript(i))",upper=a.budgets[i]))
        a.floors[i]===nothing || push!(result,StateConstraint(player=i,index=i,label="floor x$(subscript(i))",lower=log(a.floors[i]),path=true))
    end
    # Number visible bounds in plot order; shared copies retain one label.
    numbers=Dict{Tuple{Int,Float64,Float64,Bool},Int}()
    return map(result) do c
        startswith(c.label,"!") && return c
        key=(c.index,c.lower,c.upper,c.path)
        i=get!(numbers,key,length(numbers)+1)
        StateConstraint(;player=c.player,index=c.index,label="g$(subscript(i)): $(c.label)",
            lower=c.lower,upper=c.upper,path=c.path)
    end
end

function validate_trajectory(x,a)
    n=length(a.genera)
    minimum(x[1:n,:])>0 || error("Nonpositive biomass")
    all(a.qmin.-1e-8 .<= x[n+1:2n,:] .<= a.qmax.+1e-8) || error("Quota bounds violated")
    minimum(x[2n+1:2n+3,:])>=-1e-8 || error("Negative dissolved nutrient")
    return nothing
end

function game(a=Parameters())
    validate_parameters(a); n=length(a.genera); k=2n+3
    return Game(;name="AlgaeHu N=$n",
        state_labels=vcat(["X$(subscript(i)): $g" for (i,g) in enumerate(a.genera)],["qₚ$(subscript(i)): $g" for (i,g) in enumerate(a.genera)],["N","P","Si"]),
        control_labels=["u$(subscript(i)): phosphorus acquisition" for i in 1:n],owners=collect(1:n),
        dynamics! = (dx,x,u,t)->dynamics!(dx,x,u,t,a),
        objective=(x,i)->x[k+i]-a.weights[i,1]*(x[i]-log(a.biomass0[i])),
        constraints=constraints(a),
        x0=vcat(log.(a.biomass0),a.quota0,collect(a.resources0),zeros(2n)),T=a.T,quadratures=collect(k+1:k+2n),
        lower=zeros(n),upper=ones(n),initial=copy(a.initial),
        state_lower=vcat(fill(-Inf,n),a.qmin,zeros(3),fill(-Inf,2n)),
        state_upper=vcat(fill(Inf,n),a.qmax,fill(Inf,3+2n)),
        running_objectives=collect(k+1:k+n),
        decode=x->vcat(exp.(x[1:n]),x[n+1:end]),
        validate=x->validate_trajectory(x,a),
        metadata=a)
end

function main(;shooting=:single,parameters=Parameters(),options=algorithm_options(;shooting),
        folder=joinpath(@__DIR__,options.shooting==:single ? "output" : "output_multiple"),synthetic=false)
    g=game(parameters)
    synthetic && return create_synthetic_data(g,folder)
    return run_game(g;options,folder)
end
end

if abspath(PROGRAM_FILE)==@__FILE__
    CorleoneGame.run_logged(AlgaeHu.main,@__DIR__)
end
