using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Text;
using System.Threading.Tasks;

namespace ActiveSuspensionApp
{
    public class SimulationView : INotifyPropertyChanged
    {
        public int Id { get; set; }
        public string Name { get { return $"simulation {Id}"; }  }
        public SystemParams Parameters { get; set; }
        public MassSpringDamperView Wheel { get; set; }
        public MassSpringDamperView Car { get; set; }
        public MassSpringDamperView Seat { get; set; }
        public SimulationView(SystemParams data, int id) 
        {
            Parameters = data;
            Wheel = new MassSpringDamperView(data.wheel);
            Car = new MassSpringDamperView(data.car_and_suspension);
            Seat = new MassSpringDamperView(data.seat);
            Id = id;
        }

        public double Gravity
        {
            get
            {
                return Parameters.gravity;
            }
            set
            {
                Parameters.gravity = value;
                OnPropertyChanged();
            }
        }
        public double Bump
        {
            get
            {
                return Parameters.road_data.bump;
            }
            set
            {
                Parameters.road_data.bump = value;
                OnPropertyChanged();
            }
        }

        public double Freq
        {
            get
            {
                return Parameters.road_data.freq;
            }
            set
            {
                Parameters.road_data.freq = value;
                OnPropertyChanged();
            }
        }

        public double Offset
        {
            get
            {
                return Parameters.road_data.offset;
            }
            set
            {
                Parameters.road_data.offset = value;
                OnPropertyChanged();
            }
        }

        public double Loop
        {
            get
            {
                return Parameters.road_data.loop;
            }
            set
            {
                Parameters.road_data.loop = value;
                OnPropertyChanged();
            }
        }

        public double Kp
        {
            get
            {
                return Parameters.pid.kp;
            }
            set
            {
                Parameters.pid.kp = value;
                OnPropertyChanged();
            }
        }

        public double Ki
        {
            get
            {
                return Parameters.pid.ki;
            }
            set
            {
                Parameters.pid.ki = value;
                OnPropertyChanged();
            }
        }

        public double Kd
        {
            get
            {
                return Parameters.pid.kd;
            }
            set
            {
                Parameters.pid.kd = value;
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
