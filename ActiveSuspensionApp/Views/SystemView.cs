using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Text;
using System.Threading.Tasks;

namespace ActiveSuspensionApp
{
    public class SystemView : INotifyPropertyChanged
    {
        public SystemParams Data { get; set; }
        public MassSpringDamperView Wheel { get; set; }
        public MassSpringDamperView Car { get; set; }
        public MassSpringDamperView Seat { get; set; }
        public SystemView(SystemParams data) 
        {
            Data = data;
            Wheel = new MassSpringDamperView(data.wheel);
            Car = new MassSpringDamperView(data.car_and_suspension);
            Seat = new MassSpringDamperView(data.seat);
        }

        public double Gravity
        {
            get
            {
                return Data.gravity;
            }
            set
            {
                Data.gravity = value;
                OnPropertyChanged();
            }
        }
        public double Bump
        {
            get
            {
                return Data.road_data.bump;
            }
            set
            {
                Data.road_data.bump = value;
                OnPropertyChanged();
            }
        }

        public double Freq
        {
            get
            {
                return Data.road_data.freq;
            }
            set
            {
                Data.road_data.freq = value;
                OnPropertyChanged();
            }
        }

        public double Offset
        {
            get
            {
                return Data.road_data.offset;
            }
            set
            {
                Data.road_data.offset = value;
                OnPropertyChanged();
            }
        }

        public double Loop
        {
            get
            {
                return Data.road_data.loop;
            }
            set
            {
                Data.road_data.loop = value;
                OnPropertyChanged();
            }
        }

        public double Kp
        {
            get
            {
                return Data.pid.kp;
            }
            set
            {
                Data.pid.kp = value;
                OnPropertyChanged();
            }
        }

        public double Ki
        {
            get
            {
                return Data.pid.ki;
            }
            set
            {
                Data.pid.ki = value;
                OnPropertyChanged();
            }
        }

        public double Kd
        {
            get
            {
                return Data.pid.kd;
            }
            set
            {
                Data.pid.kd = value;
                OnPropertyChanged();
            }
        }

        public event PropertyChangedEventHandler? PropertyChanged;

        protected void OnPropertyChanged([CallerMemberName] string name = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
        }
    }
}
