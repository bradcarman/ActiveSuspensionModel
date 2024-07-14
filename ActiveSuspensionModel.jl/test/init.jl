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
    # masses should start at rest...
    sys.seat.m.v ~ 0, 
    sys.seat.m.a ~ 0, 
    sys.car_and_suspension.m.v ~ 0, 
    sys.car_and_suspension.m.a ~ 0, 
    sys.wheel.m.v ~ 0,
    sys.wheel.m.a ~ 0,

    # controller output should start at zero
    sys.pid.y ~ 0,

    # sensor 
    sys.seat_pos.s ~ 1.5
    ]

@named initsys = ModelingToolkit.generate_initializesystem(sys; initialization_eqs, default_p = sys .=> params)
initsys = structural_simplify(initsys)
ModelingToolkit.defaults(initsys)[sys.gravity] # 0.0 <-- BUG why didn't defualt_p take??
iprob = NonlinearProblem(initsys, [t=>0], sys .=> params)
iprob.ps[sys.gravity] # -10 OK!!
isol = solve(iprob)


@test params.seat.mass*params.gravity/params.seat.stiffness == isol[sys.seat.s.delta_s]   # OK!!
isol[sys.car_and_suspension.s.delta_s] # -1.1 OK!!
isol[sys.wheel.s.delta_s] #-112.5 OK!!



prob = ODEProblem(sys, [], (0, 10), sys .=> params)
prob.ps[sys.gravity] # Confirm gravity is set

sol = solve(prob; dtmax=0.1)

sol(0.0; idxs=sys.seat.s.delta_s) # 0.0 <---  BUG
sol(0.0; idxs=sys.car_and_suspension.s.delta_s) # 0.0 <---  BUG
sol(0.0; idxs=sys.wheel.s.delta_s) # 0.0 <---  BUG

using Plots
plot(sol; idxs=sys.road.s.u)
plot!(sol; idxs=sys.wheel.m.s)
plot!(sol; idxs=sys.car_and_suspension.m.s)
plot!(sol; idxs=sys.seat.m.s)