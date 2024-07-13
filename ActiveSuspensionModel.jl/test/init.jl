using Test
using ActiveSuspensionModel
using ModelingToolkit
using DifferentialEquations

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

@named initsys = ModelingToolkit.generate_initializesystem(sys; initialization_eqs, defaults = sys .=> params)

# First let's try without running structural_simplify, we have a balanced set of 104 equations and 104 unknowns...
iprob = NonlinearProblem(complete(initsys), [], [])

#=
ERROR: Initial condition underdefined. Some are missing from the variable map.
Please provide a default (`u0`), initialization equation, or guess
for the following variables:

Any[seat₊m₊s(t), seat₊m₊v(t), seat₊s₊delta_s(t), car_and_suspension₊m₊s(t), car_and_suspension₊m₊v(t), car_and_suspension₊s₊delta_s(t), wheel₊m₊s(t), wheel₊m₊v(t), wheel₊s₊delta_s(t), seat_pos₊s(t)  …  car_and_suspension₊m₊a(t), seat₊m₊flange₊f(t), seat₊m₊a(t), seat_pos₊sˍtt(t), err₊input1₊uˍtt(t), err₊output₊uˍtt(t), pid₊xˍtt(t), pid₊dxˍt(t), pid₊ddx(t), pid₊dy(t)]
=#

# Why am I getting a message that guesses are missing, when they clearly are not...
ModelingToolkit.get_guesses(sys)[sys.seat.m.s] #seat₊m₊initial_position
ModelingToolkit.get_guesses(sys)[sys.seat.m.v] #-seat₊m₊g*seat₊m₊m
ModelingToolkit.get_guesses(sys)[sys.seat.s.delta_s] #0


# OK, so let's try to run structural_simplify, maybe something is needed there to grab the guesses..
initsys = structural_simplify(initsys)

#=
ERROR: ExtraEquationsSystemException: The system is unbalanced. There are 101 highest order derivative variables and 104 equations.
More equations than variables, here are the potential extra equation(s):
 0 ~ -err₊output₊uˍt(t)
 0 ~ err₊output₊uˍtt(t)
 0 ~ -pid₊dy(t) - (-pid₊dx(t) - pid₊kd*pid₊ddx(t) - pid₊ki*pid₊x(t))*pid₊kp
=#
