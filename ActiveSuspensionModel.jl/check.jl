using ActiveSuspensionModel: SystemParams, prob
using DifferentialEquations

sys = prob.f.sys;
@time sol = solve(prob; dtmax=0.1); #OK

params = SystemParams()
prob′ = remake(prob; p=sys .=> params)
sol = solve(prob′; dtmax=0.1) #OK

function run(params::SystemParams)
    prob′ = remake(prob; p=sys .=> params)
    sol = solve(prob′; dtmax=0.1)

    return [sol.t sol[sys.road.s.u] sol[sys.wheel.m.s] sol[sys.car_and_suspension.m.s] sol[sys.seat.m.s]]
end

params = SystemParams();
@time "run1" run(params); # ERROR: MethodError: no method matching (::ActiveSuspensionModel.var"#23#24")(::Vector{Float64}, ::Vector{Float64}, ::Float64)
@time "run2" run(params); # OK
