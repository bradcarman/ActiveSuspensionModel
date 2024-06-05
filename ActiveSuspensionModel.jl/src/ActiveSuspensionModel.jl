module ActiveSuspensionModel
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using ModelingToolkitStandardLibrary.Mechanical.Translational
using ModelingToolkitStandardLibrary.Blocks


function MassSpringDamper(;name, mass, gravity, damping, stiffness, initial_position)

    pars = @parameters begin
        mass=mass
        gravity=gravity
        stiffness=stiffness
        damping=damping
        initial_position=initial_position
    end

    vars = []

    systems = @named begin
        d = Damper(; d=damping)
        m = Mass(;m=mass, g=gravity, s=initial_position)
        s = Spring(;k=stiffness)
        port_m = MechanicalPort()
        port_sd = MechanicalPort()
    end

    eqs = [
        connect(m.flange, s.flange_a, d.flange_a, port_m)
        connect(s.flange_b, d.flange_b, port_sd)
    ]

    return ODESystem(eqs, t, vars, pars; systems, name)
end

function System(; name)

    pars = @parameters begin
        gravity = 0
        
        wheel_mass = 25 #kg
        wheel_stiffness = 1e2
        wheel_damping = 1e4

        car_mass = 1000 #kg
        suspension_stiffness = 1e4
        suspension_damping = 10

        human_and_seat_mass = 100
        seat_stiffness = 1000
        seat_damping = 1

        Kp=1
        Kd=1
        Ki=1
    end

    vars = @variables begin
        err(t)=0
        derr(t)=0
        dderr(t)=0
        active_force(t)=0
        dactive_force(t)=0
    end

    sample_time = 1e-3 #TODO: why does this cause the model to fail if this is a parameter?

    systems = @named begin
        wheel = MassSpringDamper(; mass=4*wheel_mass, gravity, damping=wheel_damping, stiffness=wheel_stiffness, initial_position=0.5)
        car_and_suspension = MassSpringDamper(; mass=car_mass, gravity, damping=suspension_damping, stiffness=suspension_stiffness, initial_position=1)
        seat = MassSpringDamper(; mass=4*human_and_seat_mass, gravity, damping=seat_damping, stiffness=seat_stiffness, initial_position=1.5)
        road_data = SampledData(sample_time)
        road = Position()
        force = Force()
    end

    eqs = [

        connect(road.s, road_data.output)
        connect(road.flange, wheel.port_sd)
        connect(wheel.port_m, car_and_suspension.port_sd)
        connect(car_and_suspension.port_m, seat.port_sd)
        connect(seat.port_m, force.flange)

        # controller
        err ~ seat.m.s - 1.5
        D(err) ~ derr
        D(derr) ~ dderr
        D(active_force) ~ dactive_force
        dactive_force ~ Kp*derr + Kp*Ki*err + Kp*Kd*dderr

        force.f.u ~ -active_force
    ]


    return ODESystem(eqs, t, vars, pars; systems, name)
end





end # module ActiveSuspensionModel
