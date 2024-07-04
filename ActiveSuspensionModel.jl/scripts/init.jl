using ModelingToolkit: t_nounits as t, D_nounits as D
using ModelingToolkit
using DifferentialEquations

@connector MechanicalPort begin
    v(t)
    f(t), [connect = Flow]
end

@mtkmodel Fixed begin
    @components begin
        flange = MechanicalPort()
    end
    @equations begin
        flange.v ~ 0
    end
end

@component function Mass(; name, m, g=0, x_0=0)
    pars = @parameters begin
        x_0=x_0
        m=m
        g=g
    end
    vars = @variables begin
        x(t)=x_0
        v(t)=0
        f(t), [guess=0]
        a(t)=0
    end

    systems = @named begin
        flange = MechanicalPort()
    end 
    
    eqs = [
        v ~ flange.v
        f ~ flange.f

        D(x) ~ v
        D(v) ~ a
        m*a ~ f + m*g
    ]
    return ODESystem(eqs, t, vars, pars; name, systems)
end

@component function Spring(; name, k)
    pars = @parameters begin
        k = k
    end
    vars = @variables begin
        delta_s(t), [guess=0]
        f(t), [guess=0]
        ds(t) = 0
    end

    systems = @named begin
        flange_a = MechanicalPort()
        flange_b = MechanicalPort()
    end 
    
    eqs = [
        D(delta_s) ~ flange_a.v - flange_b.v
        f ~ k * delta_s
        flange_a.f ~ +f
        flange_b.f ~ -f
    ]
    return ODESystem(eqs, t, vars, pars; name, systems)
end

@mtkmodel System begin
    @components begin
        mass2 = Mass(;m=100, g=-9.807)
        spring2 = Spring(;k=100)
        mass1 = Mass(;m=100, g=-9.807)
        spring1 = Spring(;k=100)
        ref = Fixed()
    end
    @equations begin
        connect(spring1.flange_a, mass1.flange)
        connect(spring1.flange_b, spring2.flange_a, mass2.flange)
        connect(spring2.flange_b, ref.flange)
    end
end

@mtkbuild model = System()
prb = ODEProblem(model, [], (0,1))
isys = ModelingToolkit.generate_initializesystem(model)

sol = solve(prb)

sol(0.0; idxs=model.spring1.delta_s)
sol(0.0; idxs=model.spring2.delta_s)
sol(0.0; idxs=model.spring1.f)
sol(0.0; idxs=model.spring2.f)
sol(0.0; idxs=model.mass.f)
sol(0.0; idxs=model.mass.a)


using CairoMakie
lines(sol.t, sol[model.mass1.x])
lines(sol.t, sol[model.mass2.x])