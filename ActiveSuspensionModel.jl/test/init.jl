using Test
using ActiveSuspensionModel
using ModelingToolkit
using DifferentialEquations

using ModelingToolkit: t_nounits as t
using ActiveSuspensionModel: SystemParams, System

@mtkbuild sys = System()
params = SystemParams()
params.gravity = -10

ps = sys .=> params

push!(ps, sys.seat.spring.initial_stretch => -1)
push!(ps, sys.car_and_suspension.spring.initial_stretch => -1.1)
push!(ps, sys.wheel.spring.initial_stretch => -112.5)

initialization_eqs = [

    sys.seat.body.v ~ 0
    sys.seat.body.a ~ 0.0

    sys.car_and_suspension.body.v ~ 0.0
    sys.car_and_suspension.body.a ~ 0.0

    sys.wheel.body.v ~ 0.0
    sys.wheel.body.a ~ 0.0

    sys.pid.y ~ 0.0
]

prob = ODEProblem(sys, [], (0, 10), ps; initialization_eqs);
sol = solve(prob; dtmax=0.1)

using Plots
plot(sol; idxs=sys.road.s.u)
plot!(sol; idxs=sys.wheel.body.s+0.5) #NOTE <-- I need to specify an offset!!!
plot!(sol; idxs=sys.car_and_suspension.body.s+1.0) #NOTE <-- I need to specify an offset!!!
plot!(sol; idxs=sys.seat.body.s+1.5) #NOTE <-- I need to specify an offset!!!