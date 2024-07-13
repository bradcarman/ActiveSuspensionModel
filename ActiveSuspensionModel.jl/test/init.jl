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

    # controller integrator and output should start at zero
    sys.pid.dx ~ 0,
    sys.pid.ddx ~ 0,
    sys.pid.dy ~ 0,
    sys.pid.y ~ 0,

    # sensor 
    sys.seat_pos.s ~ 1.5
    ]

@named initsys = ModelingToolkit.generate_initializesystem(sys; initialization_eqs, default_p = sys .=> params)

# First let's try without running structural_simplify, we have a balanced set of 104 equations and 104 unknowns...
iprob = NonlinearProblem(complete(initsys), [t=>0], []) #Why do I need to set t to 0?
isol = solve(iprob) # ConvergenceFailure


# OK, so let's try to run structural_simplify, maybe something is needed there to grab the guesses..
initsys = structural_simplify(initsys)

#=
ERROR: ExtraEquationsSystemException: The system is unbalanced. There are 101 highest order derivative variables and 104 equations.
More equations than variables, here are the potential extra equation(s):
 0 ~ -err₊output₊uˍt(t)
 0 ~ err₊output₊uˍtt(t)
 0 ~ -pid₊dy(t) - (-pid₊dx(t) - pid₊kd*pid₊ddx(t) - pid₊ki*pid₊x(t))*pid₊kp
=#
