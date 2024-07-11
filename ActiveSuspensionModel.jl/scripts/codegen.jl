using ActiveSuspensionModel: RoadParams, ControllerParams, MassSpringDamperParams, SystemParams
using Julia2CSharp

root = "C:\\Work\\Packages\\ActiveSuspension\\ActiveSuspensionApp\\Classes\\"

RoadParams_code = Julia2CSharp.generate_csharp("ActiveSuspensionApp", RoadParams, joinpath(root, "RoadParams.cs")); 
ControllerParams_code = Julia2CSharp.generate_csharp("ActiveSuspensionApp", ControllerParams, joinpath(root, "ControllerParams.cs")); 
MassSpringDamperParams_code = Julia2CSharp.generate_csharp("ActiveSuspensionApp", MassSpringDamperParams,  joinpath(root, "MassSpringDamperParams.cs")); 
SystemParams_code = Julia2CSharp.generate_csharp("ActiveSuspensionApp", SystemParams,  joinpath(root, "SystemParams.cs")); 

funs = [

    Julia2CSharp.Func(:show_params, [(:pars,SystemParams)], nothing, false, false)
    Julia2CSharp.Func(:duplicate_params, [(:pars,SystemParams)], SystemParams, false, true)
    Julia2CSharp.Func(:run, [(:pars,SystemParams), (:vars, String)], Matrix{Float64}, false, false)

]

Julia2CSharp.generate_csharp_methods("ActiveSuspensionApp", :ActiveSuspensionModel, funs, joinpath(root, "Methods.cs"))