using System;
using System.Runtime.InteropServices;

namespace ActiveSuspensionApp
{
	public struct RoadParamsType
	{
		public double bump;
		public double freq;
		public double offset;
		public double loop;
	}
	
	public partial class RoadParams
	{
		IntPtr pointer = IntPtr.Zero;
		
		public IntPtr Pointer
		{
			get
			{
				if (pointer == IntPtr.Zero)
				{
					IntPtr ptr = Marshal.AllocHGlobal(Marshal.SizeOf<RoadParamsType>());
					Marshal.StructureToPtr(Data, ptr, true);
					IntPtr send = Marshal.AllocHGlobal(Marshal.SizeOf<IntPtr>());
					Marshal.WriteIntPtr(send, ptr);
					pointer = Julia.jl_eval_string(String.Format("p = Ptr{{Ptr{{ActiveSuspensionModel.RoadParams}}}}({0}); t = unsafe_load(unsafe_load(p)); t", send.ToInt64()));
					
					
					Julia.gc_push(pointer);
				}
				
				return pointer;
			}
			
		}
		
		public RoadParamsType Data;
		private bool IsProtected = false;
		
		public RoadParams(IntPtr ptr, bool protect = false)
		{
			pointer = ptr;
			if (protect)
			{
				IsProtected=true;
				Julia.gc_push(pointer);
			}
			
			Data = Marshal.PtrToStructure<RoadParamsType>(ptr);
			bump = Data.bump;
			freq = Data.freq;
			offset = Data.offset;
			loop = Data.loop;
		}
		
		public double bump { get { return Data.bump; } set { Data.bump = value; } }
		public double freq { get { return Data.freq; } set { Data.freq = value; } }
		public double offset { get { return Data.offset; } set { Data.offset = value; } }
		public double loop { get { return Data.loop; } set { Data.loop = value; } }
		
		~RoadParams() // finalizer
		{
			if (IsProtected & (pointer != IntPtr.Zero))
			{
				Console.WriteLine("Releasing RoadParams with pointer: " + pointer.ToString());
				Julia.gc_pop(pointer);
			}
		}
	}
	
}
