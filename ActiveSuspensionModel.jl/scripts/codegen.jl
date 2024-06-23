using ActiveSuspensionModel: RoadParams, ControllerParams, MassSpringDamperParams, SystemParams
using Julia2CSharp

# TODO: add in the Marshal update for direct values
RoadParams_code = Julia2CSharp.generate_csharp("ActiveSuspensionApp", RoadParams,          raw"C:\Work\Packages\ActiveSuspension\ActiveSuspensionApp\RoadParams.cs"); 
ControllerParams_code = Julia2CSharp.generate_csharp("ActiveSuspensionApp", ControllerParams,          raw"C:\Work\Packages\ActiveSuspension\ActiveSuspensionApp\ControllerParams.cs"); 
MassSpringDamperParams_code = Julia2CSharp.generate_csharp("ActiveSuspensionApp", MassSpringDamperParams,          raw"C:\Work\Packages\ActiveSuspension\ActiveSuspensionApp\MassSpringDamperParams.cs"); 
SystemParams_code = Julia2CSharp.generate_csharp("ActiveSuspensionApp", SystemParams,          raw"C:\Work\Packages\ActiveSuspension\ActiveSuspensionApp\SystemParams.cs"); 

funs = [

    Julia2CSharp.Func(:send_params, [(:pars,SystemParams)], nothing, false, false)
    Julia2CSharp.Func(:run, [(:pars,SystemParams)], Matrix{Float64}, false, false)

]

#TODO: sort out module and namespace
Julia2CSharp.generate_csharp_methods("ActiveSuspensionModel", funs, raw"C:\Work\Packages\ActiveSuspension\ActiveSuspensionApp\Classes\Methods.cs")