using ActiveSuspensionModel
using ModelingToolkit
using DifferentialEquations
using CairoMakie

using ActiveSuspensionModel: System
using ActiveSuspensionModel: SystemParams, MassSpringDamperParams, RoadParams, ControllerParams

@mtkbuild sys = System()

pars = SystemParams(;
    gravity = 0.0,
    wheel = MassSpringDamperParams(;
        mass = 4*25,
        stiffness = 1e2,
        damping = 1e4,
        initial_position = 0.5
    ),
    car_and_suspension = MassSpringDamperParams(;
        mass = 1000.0,
        stiffness=1e4,
        damping = 10,
        initial_position = 1.0
    ),
    seat = MassSpringDamperParams(;
        mass = 4*100.0,
        stiffness=1e3,
        damping = 1,
        initial_position = 1.5
    ),
    road_data = RoadParams(;
        bump = 0.2,
        freq = 0.5,
        offset = 1.0,
        loop = 10.0
    ),
    pid = ControllerParams(;
        kp=50,
        ki=0.2,
        kd=20
    )
)


pars.pid.kp = 0
parset1 = sys .=> pars

pars.pid.kp = 50
parset2 = sys .=> pars

sample_time = 1e-3
t_end = 20

prob1 = ODEProblem(sys, [], (0, t_end), parset1)
prob2 = remake(prob1; p = parset2)

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
axislegend(ax)
ylims!(ax, 0, 2)

ax = Axis(fig[1,2], aspect=DataAspect())
wheel_obj_y = Observable(zeros(100))
wheel_obj_x = Observable(zeros(100))
suspension_y = Observable(zeros(2))
seat_y = Observable(zeros(2))
car_obj_x = Float64[0, 0.1, 0.2, 0.3, 0.3, 0.2, 0, -0.2, -0.3, -0.3, -0.2, -0.1, 0] .*2
car_obj_y_offset = Float64[0, 0, -0.1, -0.1, 0, 0.1, 0.1, 0.1, 0, -0.1, -0.1, 0, 0] .*2
car_obj_y = Observable(car_obj_y_offset)

seat_obj_x = Float64[0, 0.1, 0.1, 0, -0.1, -0.2, -0.25, -0.2, 0]*2 .+ 0.1
seat_obj_y_offset = Float64[0, 0, 0.1, 0.1, 0.1, 0.4, 0.4,0,0]*2 .- 0.1
seat_obj_y = Observable(seat_obj_y_offset)

lines!(ax, wheel_obj_x, wheel_obj_y)
scatterlines!(ax, [0,0], suspension_y)
scatterlines!(ax, [0,0], seat_y)
lines!(ax, car_obj_x, car_obj_y)
lines!(ax, seat_obj_x, seat_obj_y)
ylims!(ax, 0, 2)

function get_wheel_obj(center, radius)

    
    for i=0:99
        wheel_obj_y[][i+1] = center + radius*sin(2π*i/99)
        wheel_obj_x[][i+1] = radius*cos(2π*i/99)
    end

    notify(wheel_obj_x)
    notify(wheel_obj_y)

end

function get_car_obj(y)

    car_obj_y[] = y .+ car_obj_y_offset


end

function get_seat_obj(y)

    seat_obj_y[] = y .+ seat_obj_y_offset


end



loop = Ref(true)
𝕀 = init(prob)


@async while loop[]
    
    @sync begin
        @async begin
            local i
            for j=1:50
                step!(𝕀, Δt, true)
                i = round(Int, mod(𝕀.t, buffer_time)/Δt)+1
                time = (i-1)*Δt
                road[][i] = 𝕀.sol(time; idxs=sys.road.s.u)
                wheel[][i] = 𝕀.sol(time; idxs=sys.wheel.m.s)
                car[][i] = 𝕀.sol(time; idxs=sys.car_and_suspension.m.s)
                seat[][i] = 𝕀.sol(time; idxs=sys.seat.m.s)
                current_time[] = time
            end

            get_wheel_obj(wheel[][i], wheel[][i] - road[][i])
            get_car_obj(car[][i])
            get_seat_obj(seat[][i])
            suspension_y[] = [wheel[][i], car[][i]]
            seat_y[] = [car[][i], seat[][i]]
        
            notify(road)
            notify(wheel)
            notify(car)
            notify(seat)
            notify(current_time)        
        end

        @async sleep(Δt*1)
    end
end

fig