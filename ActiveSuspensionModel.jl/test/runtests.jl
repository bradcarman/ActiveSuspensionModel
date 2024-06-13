using Test
using ActiveSuspensionModel
using ModelingToolkit
using DifferentialEquations
using CairoMakie


#TODO: Currently the model has PID set written by hand, but this should
#      be done with blocks.  
#TODO: The PID from the standard library does not accept parameters, only constant values, therefore Kd and Ki are made
#      as constants.  Using Controller component instead which is made in this repo
@mtkbuild sys = ActiveSuspensionModel.System()


t_end = 10

#TODO: remake is not working because PID component does not suppor it
#      see explaination here: 
prob1 = ODEProblem(sys, [], (0, t_end), [sys.Kp=>0, sys.Ki=>0.2, sys.Kd=>20])
prob2 = remake(prob1; p=[sys.Kp=>50])

# -----------------------------
# parameter_dependencies check
# -----------------------------
prob′ = remake(prob1; p=[sys.seat.initial_position=>2.0])
prob′.ps[sys.set_point.k]
prob′.ps[sys.seat_pos.s]


#TODO: DifferentialEquations can't seem to detect that SampledData has a change at 1s and
#      therefore skips right over it.  I have to set adaptive=false to get this to solve
#      correctly.  If JuliaSim GUI doesn't support solver settings, we'll need to sort out
#      how to get this to solve with defaults
sol1 = solve(prob1; dtmax=0.1)
sol2 = solve(prob2; dtmax=0.1) 

function plot_sol!(ax, sol, n; linestyle=:solid)
    lines!(ax, sol.t, sol[sys.road.s.u]; label="road $n", linestyle)
    lines!(ax, sol.t, sol[sys.wheel.m.s]; label="wheel $n", linestyle)
    lines!(ax, sol.t, sol[sys.car_and_suspension.m.s]; label="car $n", linestyle)
    lines!(ax, sol.t, sol[sys.seat.m.s]; label="seat $n", linestyle)
end

begin
    fig = Figure()
    ax = Axis(fig[1,1]; ylabel="position [m]", xlabel="time [s]")    
    plot_sol!(ax, sol1, 1)
    plot_sol!(ax, sol2, 2; linestyle=:dash)
    
    Legend(fig[1,2], ax)
    fig
end

