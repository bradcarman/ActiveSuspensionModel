
# Model Parts -------------------------------------------
@connector RealInput begin
    u(t), [input=true, guess=0]
end

@connector RealOutput begin
    u(t), [output=true, guess=0]
end

@connector MechanicalPort begin
    x(t), [guess=0]
    f(t), [connect = Flow, guess=0]
end

# -------------------------------------------------------------------

@mtkmodel Add begin
    @components begin
        input1 = RealInput()
        input2 = RealInput()
        output = RealOutput()
    end
    @parameters begin
        k1 = 1.0, [description = "Gain of Add input1"]
        k2 = 1.0, [description = "Gain of Add input2"]
    end
    @equations begin
        output.u ~ k1 * input1.u + k2 * input2.u
    end
end

@mtkmodel Constant begin
    @components begin
        output = RealOutput()
    end
    @parameters begin
        k = 0.0, [description = "Constant output value of block"]
    end
    @equations begin
        output.u ~ k
    end
end

@mtkmodel Gain begin
    @parameters begin
        k, [description = "Gain"]
    end
    @components begin
        input = RealInput()
        output = RealOutput()        
    end
    @equations begin
        output.u ~ k * input.u
    end
end

@mtkmodel Force begin
    @components begin
        flange = MechanicalPort()
        f = RealInput()
    end

    @equations begin
        flange.f ~ -f.u
    end
end

@component function Position(;name)
    vars = []

    systems = @named begin
        flange = MechanicalPort()
        s = RealInput()
    end

    eqs = [
        flange.x ~ s.u
    ]

    ODESystem(eqs, t, vars, []; name, systems)
end


@mtkmodel PositionSensor begin
    @components begin
        flange = MechanicalPort()
        output = RealOutput()
    end
    @equations begin
        output.u ~ flange.x
        flange.f ~ 0.0
    end
end

#TODO: a bug exists that parameters can't have the same name as variables, this "hides" the stored guesses of the variables

# INIT NOTE: no API offered here for initial conditions, parent component must implement initial equatoins (or equations that relate to the variables)
@component function Mass(; name, m, g=0)
    pars = @parameters begin
        m=m
        g=g
    end
    vars = @variables begin
        s(t), [guess=0]
        v(t), [guess=0]
        f(t), [guess=0]
        a(t), [guess=0]
    end

    systems = @named begin
        flange = MechanicalPort()
    end 
    
    eqs = [
        s ~ flange.x
        f ~ flange.f

        D(s) ~ v
        D(v) ~ a
        m*a ~ f + m*g
    ]
    return ODESystem(eqs, t, vars, pars; name, systems)
end

@component function Spring(; name, k)
    pars = @parameters begin
        k = k
    end
    
    vars = @variables begin
        delta_s(t), [guess=0]
        f(t), [guess=0]
        initial_stretch(t), [guess= 0]
    end

    systems = @named begin
        flange_a = MechanicalPort()
        flange_b = MechanicalPort()
    end 
    
    eqs = [
        D(initial_stretch) ~ 0.0
        delta_s ~ (flange_a.x - flange_b.x) + initial_stretch
        f ~ k * delta_s
        flange_a.f ~ +f
        flange_b.f ~ -f
    ]
    return ODESystem(eqs, t, vars, pars; name, systems)
end

@mtkmodel Damper begin
    @parameters begin
        d
    end
    @variables begin
        delta_s(t), [guess=0]
        f(t), [guess=0]
    end

    @components begin
        flange_a = MechanicalPort()
        flange_b = MechanicalPort()
    end

    @equations begin
        delta_s ~ flange_a.x - flange_b.x
        f ~ D(delta_s) * d
        flange_a.f ~ +f
        flange_b.f ~ -f
    end
end


# ----------------------------------