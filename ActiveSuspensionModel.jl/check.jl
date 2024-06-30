using ActiveSuspensionModel: SystemParams, prob, sys, run
using DifferentialEquations

@time "solve 1" sol = solve(prob; dtmax=0.1); #OK
@time "solve 2" sol = solve(prob; dtmax=0.1); #OK

params = SystemParams()
prob′ = remake(prob; p=sys .=> params)
sol = solve(prob′; dtmax=0.1) #OK

params = SystemParams();
@time "run1" run(params); # ERROR: MethodError: no method matching (::ActiveSuspensionModel.var"#23#24")(::Vector{Float64}, ::Vector{Float64}, ::Float64)
@time "run2" run(params); # OK

data = run(params);
time = data[:,1]
road = data[:,2]
wheel = data[:,3]
car = data[:,4]
seat = data[:,5]


using CairoMakie
fig = Figure()
ax = Axis(fig[1,1])
lines!(ax, time, road; label="road")
lines!(ax, time, wheel; label="wheel")
lines!(ax, time, car; label="car")
lines!(ax, time, seat; label="seat")
Legend(fig[1,2], ax)
fig