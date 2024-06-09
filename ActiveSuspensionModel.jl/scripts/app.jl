using ActiveSuspensionModel
using ModelingToolkit
using DifferentialEquations
using GLMakie


@mtkbuild sys = ActiveSuspensionModel.System()


sample_time = 1e-3
t_end = 20

prob = ODEProblem(sys, [], (0, t_end), [sys.Kp=>50, sys.Ki=>0.2, sys.Kd=>20])


buffer_time = 10

Δt = 1e-3
n = round(Int,buffer_time/Δt) + 1
time = 0:Δt:(n-1)*Δt
road = Observable(zeros(n))
wheel = Observable(zeros(n))
car = Observable(zeros(n))
seat = Observable(zeros(n))
current_time = Observable(4.0)

fig = Figure()
ax = Axis(fig[1,1])
lines!(ax, time, road; label="road")
lines!(ax, time, wheel; label="wheel")
lines!(ax, time, car; label="car")
lines!(ax, time, seat; label="seat")
vlines!(ax, current_time; color=:gray, linestyle=:dash)
Legend(fig[1,2], ax)

loop = Ref(true)
𝕀 = init(prob)


@async while loop[]
    
    for j=1:100
        step!(𝕀, Δt, true)
        i = round(Int, mod(𝕀.t, buffer_time)/Δt)+1
        time = (i-1)*Δt
        road[][i] = 𝕀.sol(time; idxs=sys.road.s.u)
        wheel[][i] = 𝕀.sol(time; idxs=sys.wheel.m.s)
        car[][i] = 𝕀.sol(time; idxs=sys.car_and_suspension.m.s)
        seat[][i] = 𝕀.sol(time; idxs=sys.seat.m.s)
        current_time[] = time
    end

    notify(road)
    notify(wheel)
    notify(car)
    notify(seat)
    notify(current_time)

    sleep(Δt*10)
end



function plot_sol!(ax, sol, n; linestyle=:solid)
    lines!(ax, sol.t, sol[sys.road.s.u]; label="road $n", linestyle)
    lines!(ax, sol.t, sol[sys.wheel.m.s]; label="wheel $n", linestyle)
    lines!(ax, sol.t, sol[sys.car_and_suspension.m.s]; label="car $n", linestyle)
    lines!(ax, sol.t, sol[sys.seat.m.s]; label="seat $n", linestyle)
end

begin
    fig = Figure()
    ax = Axis(fig[1,1]; ylabel="position [m]", xlabel="time [s]")    
    plot_sol!(ax, sol, "")
        
    Legend(fig[1,2], ax)
    fig
end



using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using DifferentialEquations

vars = @variables x(t)=0

eqs = [
    D(x) ~ 0.1t
]

@mtkbuild sys = ODESystem(eqs, t, vars, [])

prob = ODEProblem(sys, [], (0, 10))
sol = solve(prob)
sol(0.0)[sys.x] # ERROR: ArgumentError: invalid index: x(t) of type SymbolicUtils.BasicSymbolic{Real}
sol(0.0:0.1:0.0)[sys.x] # OK
sol(0.0; idxs=sys.x)