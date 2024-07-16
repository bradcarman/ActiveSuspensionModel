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

@test sol(0.0; idxs=sys.seat.spring.delta_s) == -1
@test sol(0.0; idxs=sys.car_and_suspension.spring.delta_s) == -1.1
@test sol(0.0; idxs=sys.wheel.spring.delta_s)  == -112.5

using Plots
plot(sol; idxs=sys.road.s.u)
plot!(sol; idxs=sys.wheel.body.s)
plot!(sol; idxs=sys.car_and_suspension.body.s)
plot!(sol; idxs=sys.seat.body.s)


# initialization under the hood 
# -------------------------------------------------
@named initsys = ModelingToolkit.generate_initializesystem(sys; default_p = sys .=> params)
initsys = structural_simplify(initsys)
iprob = NonlinearProblem(initsys, [t=>0], sys .=> params)
isol = solve(iprob)

@test params.seat.mass*params.gravity/params.seat.stiffness == isol[sys.seat.spring.delta_s]   # OK!!
@test isol[sys.car_and_suspension.spring.delta_s] == -1.1 # -1.1 OK!!
@test isol[sys.wheel.spring.delta_s] == -112.5 #-112.5 OK!!