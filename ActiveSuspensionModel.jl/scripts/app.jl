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