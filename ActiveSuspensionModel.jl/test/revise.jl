using Revise
using ActiveSuspensionModel
using ActiveSuspensionModel: sys, prob, SystemParams, run
using CairoMakie

params = SystemParams()
params.gravity = -9.807

revise(ActiveSuspensionModel)
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