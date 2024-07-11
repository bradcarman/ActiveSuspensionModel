using System;
using System.Runtime.InteropServices;
using System.Threading.Tasks;


namespace ActiveSuspensionApp
{
	
	public static partial class Methods
	{
		
		public static void show_params(SystemParams pars)
		{
			IntPtr module = Julia.jl_eval_string("ActiveSuspensionModel");
			IntPtr show_params_sym = Julia.jl_symbol("show_params");
			IntPtr show_params_fun = Julia.jl_get_global(module, show_params_sym);
			
			IntPtr arg1 = pars.Pointer;
			
			Julia.RunFunction(show_params_fun , arg1);
		}
		
		public static SystemParams duplicate_params(SystemParams pars)
		{
			IntPtr module = Julia.jl_eval_string("ActiveSuspensionModel");
			IntPtr duplicate_params_sym = Julia.jl_symbol("duplicate_params");
			IntPtr duplicate_params_fun = Julia.jl_get_global(module, duplicate_params_sym);
			
			IntPtr arg1 = pars.Pointer;
			
			IntPtr ret = Julia.RunFunction(duplicate_params_fun , arg1);
			
			return new SystemParams(ret, true);
		}
		
		public static double[,] run(SystemParams pars,string vars)
		{
			IntPtr module = Julia.jl_eval_string("ActiveSuspensionModel");
			IntPtr run_sym = Julia.jl_symbol("run");
			IntPtr run_fun = Julia.jl_get_global(module, run_sym);
			
			IntPtr arg1 = pars.Pointer;
			IntPtr arg2 = Julia.jl_cstr_to_string(vars);
			
			IntPtr ret = Julia.RunFunction(run_fun , arg1, arg2);
			
			return Julia.GetFloat64Matrix(ret);
		}
		
		
	}
	
}
