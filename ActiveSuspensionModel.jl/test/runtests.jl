using Test
using ActiveSuspensionModel
using ModelingToolkit
using DifferentialEquations
using CairoMakie

using ModelingToolkit: t_nounits as t
using ActiveSuspensionModel: sys, prob, SystemParams, run

#TODO: Currently the model has PID set written by hand, but this should
#      be done with blocks.  
#TODO: The PID from the standard library does not accept parameters, only constant values, therefore Kd and Ki are made
#      as constants.  Using Controller component instead which is made in this repo
@mtkbuild sys = ActiveSuspensionModel.System()


t_end = 10

#TODO: remake is not working because PID component does not suppor it
#      see explaination here: 

prob0 = ODEProblem(sys, [], (0, t_end))
sol0 = solve(prob0)
sol0[sys.wheel.m.s][1] #0.0

prob1 = ODEProblem(sys, [], (0, t_end),[sys.wheel.initial_position=>0.5])
sol1 = solve(prob1)
sol1[sys.wheel.m.s][1] #0.5 OK

prob2 = remake(prob0; p=[sys.wheel.initial_position=>0.5])
prob2.ps[sys.wheel.initial_position] #0.5 OK
sol2 = solve(prob2)
sol2[sys.wheel.m.s][1] #0.0 <--- BUG!

iprob = ModelingToolkit.InitializationProblem(sys, 0.0, [], [sys.wheel.initial_position=>0.5])
isol = solve(iprob)
isol[sys.wheel.m.s] #0.5 <--- OK!

iprob0 = ModelingToolkit.InitializationProblem(sys, 0.0, [], [])
isol0 = solve(iprob0)
isol0[sys.wheel.m.s] #0.0

iprob = remake(iprob0; p=[sys.wheel.initial_position=>0.5])
sol = solve(iprob)
sol[sys.wheel.m.s] #0.5



# -------------------------
params = SystemParams()
data = run(params)
time, road, wheel, car, seat = eachcol(data)

fig = Figure()
ax = Axis(fig[1,1])
lines!(ax, time, road; label="road")
lines!(ax, time, wheel; label="wheel")
lines!(ax, time, car; label="car")
lines!(ax, time, seat; label="seat")
Legend(fig[1,2], ax)
fig

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

