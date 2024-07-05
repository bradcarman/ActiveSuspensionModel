using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Text;
using System.Threading.Tasks;
using System.Windows;

namespace ActiveSuspensionApp
{
    public class MassSpringDamperView : INotifyPropertyChanged
    {
        private MassSpringDamperParams Data { get; set; }
        public MassSpringDamperView(MassSpringDamperParams data)
        {
            Data = data;    
            
        }

        

public double Mass
{
    get { return Data.mass; }
    set
    {
        try
        {
            Data.mass = value;
            OnPropertyChanged();
        }
        catch (Exception ex)
        {
            MessageBox.Show(ex.Message);
        }
    }
}

        public double Stiffness
        {
            get
            {
                return Data.stiffness;
            }
            set
            {
                Data.stiffness = value;
                OnPropertyChanged();
            }
        }

        public double InitialPosition
        {
            get
            {
                return Data.initial_position;
            }
            set
            {
                Data.initial_position = value;
                OnPropertyChanged();
            }
        }

        public double Damping
        {
            get
            {
                return Data.damping;
            }
            set
            {
                Data.damping = value;
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
