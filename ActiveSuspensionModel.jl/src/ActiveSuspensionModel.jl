module ActiveSuspensionModel
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using ModelingToolkitStandardLibrary.Mechanical.Translational
using ModelingToolkitStandardLibrary.Blocks
using PrecompileTools, OrdinaryDiffEq

#y data as a function of time (assuming car is traveling at constant speed of 15m/s)
@component function Road(; name)
    
    systems = @named begin
        output = RealOutput()
    end

    pars = @parameters begin
        bump = 0.2
        freq = 0.5
        offset = 1.0
        loop = 10
    end

    𝕓 = bump*(1 - cos(2π*(t-offset)/freq))
    τ = mod(t, loop)

    eqs = [
        output.u ~ ifelse( τ < offset, 
            0.0, 
                ifelse( τ - offset > freq, 
                    0.0, 
                        𝕓)
        )
    ]

    return ODESystem(eqs, t, [], pars; name, systems)
end

@component function Controller(;kp, ki, kd, name)
    
    pars = @parameters begin
        kp = kp
        ki = ki
        kd = kd
    end

    vars = @variables begin
        x(t) = 0
        dx(t) = 0
        ddx(t) = 0
        y(t) = 0
        dy(t) = 0
    end
    
    systems = @named begin
        err_input = RealInput()
        ctr_output = RealOutput()
    end


    # equations ---------------------------
    eqs = [

        D(x) ~ dx
        D(dx) ~ ddx
        D(y) ~ dy
        

        err_input.u ~ x
        ctr_output.u ~ y 

        dy ~ kp*(dx + ki*x + kd*ddx)

    ]

    return ODESystem(eqs, t, vars, pars; systems, name)
end


@component function MassSpringDamper(;name, mass, gravity, damping, stiffness, initial_position)

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

    # vars = @variables begin
        
    # end
    vars = []

    sample_time = 1e-3 #TODO: why does this cause the model to fail if this is a parameter?

    systems = @named begin
        wheel = MassSpringDamper(; mass=4*wheel_mass, gravity, damping=wheel_damping, stiffness=wheel_stiffness, initial_position=0.5)
        car_and_suspension = MassSpringDamper(; mass=car_mass, gravity, damping=suspension_damping, stiffness=suspension_stiffness, initial_position=1)
        seat = MassSpringDamper(; mass=4*human_and_seat_mass, gravity, damping=seat_damping, stiffness=seat_stiffness, initial_position=1.5)
        #road_data = SampledData(sample_time)
        road_data = Road()
        road = Position()
        force = Force()
        pid = Controller(; kp=Kp, ki=Ki, kd=Kd)
        err = Add(; k1=1, k2=-1) #makes a subtract
        set_point = Constant() #parameter_dependencies --> k=seat.initial_position 
        seat_pos = PositionSensor() #parameter_dependencies --> s=seat.initial_position
        flip = Gain(; k=-1)
    end

    eqs = [
        
        # mechanical model
        connect(road.s, road_data.output)
        connect(road.flange, wheel.port_sd)
        connect(wheel.port_m, car_and_suspension.port_sd)
        connect(car_and_suspension.port_m, seat.port_sd)
        connect(seat.port_m, force.flange)

        
        # controller        
        connect(seat.m.flange, seat_pos.flange)
        connect(err.input1, seat_pos.output)
        connect(err.input2, set_point.output)
        connect(pid.err_input, err.output)
        connect(pid.ctr_output, flip.input)
        connect(flip.output, force.f)

        
    ]


    return ODESystem(eqs, t, vars, pars; systems, name, parameter_dependencies=[set_point.k=>seat.initial_position, seat_pos.s => seat.initial_position])
end

@mtkbuild sys = System()
prob = ODEProblem(sys, [], (0, 10); eval_expression = true, eval_module = @__MODULE__)

@setup_workload begin   
    @compile_workload begin
        solve(prob)
        prob′ = remake(prob)
        solve(prob′; dtmax=0.1)
    end
end

end # module ActiveSuspensionModel
