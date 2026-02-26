using ActiveSuspensionModel
using ModelingToolkitParameters
using Test
using ModelingToolkit
using ModelingToolkit: D_nounits as D, t_nounits as t

@mtkcompile model = ActiveSuspensionModel.Model()
model_p = ActiveSuspensionModel.ModelParams()

prob = ODEProblem(model, model => model_p, (0, 10))
@test ModelingToolkit.SciMLBase.initialization_status(prob) == ModelingToolkit.SciMLBase.FULLY_DETERMINED


@mtkcompile model = ActiveSuspensionModel.InverseModel()
model_p = ActiveSuspensionModel.InverseModelParams()

prob = ODEProblem(model, model => model_p, (0, 10))
@test ModelingToolkit.SciMLBase.initialization_status(prob) == ModelingToolkit.SciMLBase.FULLY_DETERMINED