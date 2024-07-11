using System;
using System.Runtime.InteropServices;

namespace ActiveSuspensionApp
{
	public struct MassSpringDamperParamsType
	{
		public double mass;
		public double stiffness;
		public double damping;
		public double initial_position;
	}
	
	public partial class MassSpringDamperParams
	{
		IntPtr pointer = IntPtr.Zero;
		
		public IntPtr Pointer
		{
			get
			{
				if (pointer == IntPtr.Zero)
				{
					IntPtr ptr = Marshal.AllocHGlobal(Marshal.SizeOf<MassSpringDamperParamsType>());
					Marshal.StructureToPtr(Data, ptr, true);
					IntPtr send = Marshal.AllocHGlobal(Marshal.SizeOf<IntPtr>());
					Marshal.WriteIntPtr(send, ptr);
					pointer = Julia.jl_eval_string(String.Format("p = Ptr{{Ptr{{ActiveSuspensionModel.MassSpringDamperParams}}}}({0}); t = unsafe_load(unsafe_load(p)); t", send.ToInt64()));
					
					
					Julia.gc_push(pointer);
				}
				
				return pointer;
			}
			
		}
		
		public MassSpringDamperParamsType Data;
		private bool IsProtected = false;
		
		public MassSpringDamperParams(IntPtr ptr, bool protect = false)
		{
			pointer = ptr;
			if (protect)
			{
				IsProtected=true;
				Julia.gc_push(pointer);
			}
			
			Data = Marshal.PtrToStructure<MassSpringDamperParamsType>(ptr);
			mass = Data.mass;
			stiffness = Data.stiffness;
			damping = Data.damping;
			initial_position = Data.initial_position;
		}
		
		public double mass {
			get { return Data.mass; }
			set
			{
				Data.mass = value;
				Julia.RunFunction(Julia.setproperty_fun, Pointer, Julia.jl_symbol("mass"), Julia.jl_box_float64(value) );
			}
		}
		
		public double stiffness {
			get { return Data.stiffness; }
			set
			{
				Data.stiffness = value;
				Julia.RunFunction(Julia.setproperty_fun, Pointer, Julia.jl_symbol("stiffness"), Julia.jl_box_float64(value) );
			}
		}
		
		public double damping {
			get { return Data.damping; }
			set
			{
				Data.damping = value;
				Julia.RunFunction(Julia.setproperty_fun, Pointer, Julia.jl_symbol("damping"), Julia.jl_box_float64(value) );
			}
		}
		
		public double initial_position {
			get { return Data.initial_position; }
			set
			{
				Data.initial_position = value;
				Julia.RunFunction(Julia.setproperty_fun, Pointer, Julia.jl_symbol("initial_position"), Julia.jl_box_float64(value) );
			}
		}
		
		
		~MassSpringDamperParams() // finalizer
		{
			if (IsProtected & (pointer != IntPtr.Zero))
			{
				Console.WriteLine("Releasing MassSpringDamperParams with pointer: " + pointer.ToString());
				Julia.gc_pop(pointer);
			}
		}
	}
	
}
