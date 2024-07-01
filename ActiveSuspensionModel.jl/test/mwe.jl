using Test
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using DifferentialEquations

@parameters g x0
@variables x(t)=x0 y(t) [state_priority = 10] λ(t)
eqs = [D(D(x)) ~ λ * x
       D(D(y)) ~ λ * y - g
       x^2 + y^2 ~ 1]
@mtkbuild pend = ODESystem(eqs, t)
prb = ODEProblem(pend, [y => 0], (0.0, 1.5), [g => 1, x0 => 1], guesses = [λ => 1])
@test prb.u0[4] == prb.ps[x0]

prb = ODEProblem(pend, [y => 0], (0.0, 1.5), [g => 1, x0 => 2], guesses = [λ => 1])
@test prb.u0[4] == prb.ps[x0]

prb2 = remake(prb; p=[x0=>10])
@test prb2.u0[4] == prb2.ps[x0]  # ERROR!!