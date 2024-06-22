using System;
using System.Runtime.InteropServices;
using System.Threading.Tasks;


namespace ActiveSuspensionApp
{
	
	public static partial class Methods
	{
		
		public static void send_params(SystemParams x)
		{
			IntPtr module = Julia.jl_eval_string("ActiveSuspensionModel");
			IntPtr send_params_sym = Julia.jl_symbol("send_params");
			IntPtr send_params_fun = Julia.jl_get_global(module, send_params_sym);

			IntPtr arg1 = x.Pointer;
			
			Julia.jl_call1(send_params_fun , arg1);
		}
		
		
	}
	
}
