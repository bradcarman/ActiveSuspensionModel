using Test
using ActiveSuspensionModel
using ModelingToolkit
using DifferentialEquations
using CairoMakie

using ModelingToolkit: t_nounits as t
using ActiveSuspensionModel: sys, prob, SystemParams, run


# -------------------------
params = SystemParams()
params.gravity = -9.807
params.wheel.stiffness = 10000
params.car_and_suspension.stiffness = 10000
params.seat.stiffness = 10000

data = run(params)
time, road, wheel, car, seat = eachcol(data)

begin
    fig = Figure()
    ax = Axis(fig[1,1])
    lines!(ax, time, road; label="road")
    lines!(ax, time, wheel; label="wheel")
    lines!(ax, time, car; label="car")
    lines!(ax, time, seat; label="seat")
    Legend(fig[1,2], ax)
    fig    
end


prob′ = remake(prob; p=sys .=> params)



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

