using Test
using ActiveSuspensionModel
using ModelingToolkit
using DifferentialEquations

using ModelingToolkit: t_nounits as t
using ActiveSuspensionModel: SystemParams, System


@mtkbuild sys = System()
params = SystemParams()
params.gravity = -10

prob = ODEProblem(sys, [], (0, 10), sys .=> params);
sol = solve(prob; dtmax=0.1)


using Plots
plot(sol; idxs=sys.road.s.u)
plot!(sol; idxs=sys.wheel.body.s)
plot!(sol; idxs=sys.car_and_suspension.body.s)
plot!(sol; idxs=sys.seat.body.s)

params′ = copy(params)
params′.pid.kp = 100
# params′.seat.mass = -25


prob′ = remake(prob; p=sys .=> params′)
sol′ = solve(prob′; dtmax=0.1)

plot!(sol′; idxs=sys.seat.body.s)

@test sol′[sys.seat.body.s][end] ≈ 1.5 atol=0.01