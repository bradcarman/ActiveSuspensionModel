using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Input;
using OxyPlot;
using OxyPlot.Axes;
using OxyPlot.Series;


namespace ActiveSuspensionApp
{
    

    public class MainWindowViewModel : INotifyPropertyChanged
    {

        public Visibility ParametersVisibility { get; set; } = Visibility.Hidden;

        SimulationView? mSelectedSimulation = null;
        public SimulationView? SelectedSimulation 
        {
            get { return mSelectedSimulation; }
            set 
            { 
                mSelectedSimulation = value;
                RunSimulationCommand.RaiseCanExecuteChanged();
                ShowParametersCommand.RaiseCanExecuteChanged();

                ParametersVisibility = mSelectedSimulation == null ? Visibility.Hidden : Visibility.Visible;
                OnPropertyChanged("ParametersVisibility");
                OnPropertyChanged("SelectedSimulation");
            } 
        }
        public ObservableCollection<SimulationView> Simulations { get; set; }

        public PlotModel PlotModel { get; private set; }

        public OperationCommand AddSimulationCommand { get; set; }
        public OperationCommand DuplicateSimulationCommand { get; set; }
        public OperationCommand RunSimulationCommand { get; set; }
        public OperationCommand ShowParametersCommand { get; set; }

        public string YLabel { get; set; } = "position [m]";

        public bool PlotState1 { get; set; } = true;
        public bool PlotState2 { get; set; } = true;
        public bool PlotState3 { get; set; } = true;
        public bool PlotState4 { get; set; } = true;

        public string State1 { get; set; } = "road.s.u";
        public string State2 { get; set; } = "wheel.m.s";
        public string State3 { get; set; } = "car_and_suspension.m.s";
        public string State4 { get; set; } = "seat.m.s";


        public MainWindowViewModel()
        {

            PlotModel = new PlotModel();
            PlotModel.Axes.Add(new LinearAxis { Position = AxisPosition.Bottom, Title = "time [s]", MajorGridlineStyle = LineStyle.Solid, MinorGridlineStyle = LineStyle.Dot });
            PlotModel.Axes.Add(new LinearAxis { Position = AxisPosition.Left, MajorGridlineStyle = LineStyle.Solid, MinorGridlineStyle = LineStyle.Dot });

            LineRoad = new LineSeries() { Color = OxyColors.Black };
            PlotModel.Series.Add(LineRoad);

            Simulations = new ObservableCollection<SimulationView>();

            AddSimulationCommand = new OperationCommand((o) => DoAddSimulation(), (o) => true);
            RunSimulationCommand = new OperationCommand((o) => DoRunSimulation(), (o) => IsSimulationSelected());
            ShowParametersCommand = new OperationCommand((o) => DoShowParameters(), (o) => IsSimulationSelected());
            DuplicateSimulationCommand = new OperationCommand((o) => DoDuplicateParameters(), (o) => IsSimulationSelected());

        }

        public void DoAddSimulation()
        {
            IntPtr pars_ptr = Julia.jl_eval_string("ActiveSuspensionModel.SystemParams()");
            SystemParams mSystemParams = new SystemParams(pars_ptr, true);

            DoAddSimulation(mSystemParams);
        }


        public void DoAddSimulation(SystemParams mSystemParams)
        {
            

            int id = Simulations.Count + 1;
            OxyColor color = PlotModel.DefaultColors[id];
            SimulationView simulation = new SimulationView(mSystemParams, id, color);
            simulation.VisibleChanged += Simulation_VisibleChanged;
            
            Simulations.Add(simulation);
            PlotModel.Series.Add(simulation.LineWheel);
            PlotModel.Series.Add(simulation.LineCar);
            PlotModel.Series.Add(simulation.LineSeat);

            SelectedSimulation = Simulations.Last();
            ParametersVisibility = Visibility.Visible;
            OnPropertyChanged("Simulations");
        }

        private void Simulation_VisibleChanged(object? sender, EventArgs e)
        {
            PlotModel.InvalidatePlot(false);
        }

        private LineSeries LineRoad { get; set; }

        public bool IsSimulationSelected()
        {
            return SelectedSimulation != null;
        }

        

        public void DoRunSimulation()
        {
            PlotModel.Axes[1].Title = YLabel;

            if (SelectedSimulation != null)
            {
                //Julia.jl_eval_string("revise()");
                //Julia.jl_eval_string("revise(ActiveSuspensionModel)");

                string[] combined_states = { State1, State2, State3, State4 };
                string states = String.Join(',', combined_states);
                double[,] data = Methods.run(SelectedSimulation.Parameters, states);

                LineRoad.Points.Clear();
                SelectedSimulation.LineWheel.Points.Clear();
                SelectedSimulation.LineCar.Points.Clear();
                SelectedSimulation.LineSeat.Points.Clear();

                int r = data.GetLength(0);

                for (int j = 0; j < r; j++)
                {
                    if (PlotState1)
                        LineRoad.Points.Add(new OxyPlot.DataPoint(data[j, 0], data[j, 1]));

                    if (PlotState2)
                        SelectedSimulation.LineWheel.Points.Add(new OxyPlot.DataPoint(data[j, 0], data[j, 2]));

                    if (PlotState3)
                        SelectedSimulation.LineCar.Points.Add(new OxyPlot.DataPoint(data[j, 0], data[j, 3]));

                    if (PlotState4)
                        SelectedSimulation.LineSeat.Points.Add(new OxyPlot.DataPoint(data[j, 0], data[j, 4]));
                }
                    
                PlotModel.InvalidatePlot(true);
            }
            
        }

        public void DoShowParameters()
        {
            if (SelectedSimulation != null)
                Methods.show_params(SelectedSimulation.Parameters);
        }

        public void DoDuplicateParameters()
        {
            if (SelectedSimulation != null)
            {
                SystemParams system_params = Methods.duplicate_params(SelectedSimulation.Parameters);
                DoAddSimulation(system_params);
            }
        }


        public event PropertyChangedEventHandler? PropertyChanged;

        protected void OnPropertyChanged([CallerMemberName] string name = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
        }

    }
}
