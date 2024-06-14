using System;
using System.Runtime.InteropServices;

namespace ActiveSuspensionApp
{
	public struct ControllerParamsType
	{
		public double kp;
		public double ki;
		public double kd;
	}
	
	public partial class ControllerParams
	{
		IntPtr pointer = IntPtr.Zero;
		
		public IntPtr Pointer
		{
			get
			{
				if (pointer == IntPtr.Zero)
				{
					IntPtr ptr = Marshal.AllocHGlobal(Marshal.SizeOf<ControllerParamsType>());
					Marshal.StructureToPtr(Data, ptr, true);
					IntPtr send = Marshal.AllocHGlobal(Marshal.SizeOf<IntPtr>());
					Marshal.WriteIntPtr(send, ptr);
					pointer = Julia.jl_eval_string(String.Format("p = Ptr{{Ptr{{ActiveSuspensionModel.ControllerParams}}}}({0}); t = unsafe_load(unsafe_load(p)); t", send.ToInt64()));
					
					
					Julia.gc_push(pointer);
				}
				
				return pointer;
			}
			
		}
		
		public ControllerParamsType Data;
		private bool IsProtected = false;
		
		public ControllerParams(IntPtr ptr, bool protect = false)
		{
			pointer = ptr;
			if (protect)
			{
				IsProtected=true;
				Julia.gc_push(pointer);
			}
			
			Data = Marshal.PtrToStructure<ControllerParamsType>(ptr);
			kp = Data.kp;
			ki = Data.ki;
			kd = Data.kd;
		}
		
		public double kp { get { return Data.kp; } set { Data.kp = value; Marshal.StructureToPtr(Data, Pointer, true); } }
		public double ki { get { return Data.ki; } set { Data.ki = value; Marshal.StructureToPtr(Data, Pointer, true); } }
		public double kd { get { return Data.kd; } set { Data.kd = value; Marshal.StructureToPtr(Data, Pointer, true); } }
		
		~ControllerParams() // finalizer
		{
			if (IsProtected & (pointer != IntPtr.Zero))
			{
				Console.WriteLine("Releasing ControllerParams with pointer: " + pointer.ToString());
				Julia.gc_pop(pointer);
			}
		}
	}
	
}
