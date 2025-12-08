using ActiveSuspensionModel
using ModelingToolkitParameters
using Test
using ModelingToolkit
using ModelingToolkit: D_nounits as D, t_nounits as t

@mtkcompile model = ActiveSuspensionModel.Model()
model_p = ActiveSuspensionModel.ModelParams()

initialization_eqs = [
    model.wheel.body.s ~ 0.5
    model.car_and_suspension.body.s ~ 1.0
    model.seat.body.s ~ 1.5

    model.wheel.body.v ~ 0
    model.car_and_suspension.body.v ~ 0
    model.seat.body.v ~ 0

    model.wheel.body.a ~ 0
    model.car_and_suspension.body.a ~ 0
    model.seat.body.a ~ 0

    model.force.f.u ~ 0
]

prob = ODEProblem(model, model => model_p, (0, 10); initialization_eqs, fully_determined=true)
@test ModelingToolkit.SciMLBase.initialization_status(prob) == ModelingToolkit.SciMLBase.FULLY_DETERMINED