using Test
using ActiveSuspensionModel
using ModelingToolkit
using DifferentialEquations
using CairoMakie


#TODO: Currently the model has PID set written by hand, but this should
#      be done with blocks.  
@mtkbuild sys = ActiveSuspensionModel.System()

#y data as a function of time (assuming car is traveling at constant speed of 15m/s)
sample_time = 1e-3

#TODO: this model uses the SampledData component.  
#      If JuliaSim GUI can't support SampledData then this need function
#      needs to be generated with Blocks
bump = 0.2
width = 200
road = [zeros(1000); bump .- bump*cos.((2π/width)*(0:width)); zeros(5000)]
n = length(road)

prob1 = ODEProblem(sys, [], (0, (n-1)*sample_time), [sys.road_data.buffer=> road, sys.Kp=>0, sys.Ki=>0.2, sys.Kd=>20])
prob2 = remake(prob1; p=[sys.Kp=>50])

#TODO: DifferentialEquations can't seem to detect that SampledData has a change at 1s and
#      therefore skips right over it.  I have to set adaptive=false to get this to solve
#      correctly.  If JuliaSim GUI doesn't support solver settings, we'll need to sort out
#      how to get this to solve with defaults
sol1 = solve(prob1; dt=1e-3, adaptive=false)
sol2 = solve(prob2; dt=1e-3, adaptive=false)

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


