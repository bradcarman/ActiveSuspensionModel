using Test
using ActiveSuspensionModel
using ModelingToolkit
using DifferentialEquations

using ModelingToolkit: t_nounits as t
using ActiveSuspensionModel: SystemParams, System

@mtkbuild sys = System()
params = SystemParams()
params.gravity = -10

initialization_eqs = [

    sys.seat.body.s ~ 1.5
    sys.seat.body.v ~ 0.0
    sys.seat.body.a ~ 0.0

    sys.car_and_suspension.body.s ~ 1.0
    sys.car_and_suspension.body.v ~ 0.0
    sys.car_and_suspension.body.a ~ 0.0

    sys.wheel.body.s ~ 0.5
    sys.wheel.body.v ~ 0.0
    sys.wheel.body.a ~ 0.0

    sys.pid.y ~ 0.0
]

prob = ODEProblem(sys, [], (0, 10), sys .=> params; initialization_eqs);
sol = solve(prob; dtmax=0.1)

sol(0.0; idxs=sys.seat.spring.delta_s)
sol(0.0; idxs=sys.car_and_suspension.spring.delta_s)
sol(0.0; idxs=sys.wheel.spring.delta_s)

using Plots
plot(sol; idxs=sys.road.s.u)
plot!(sol; idxs=sys.wheel.body.s)
plot!(sol; idxs=sys.car_and_suspension.body.s)
plot!(sol; idxs=sys.seat.body.s)