using OxyPlot.Series;
using System.Collections.ObjectModel;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

namespace ActiveSuspensionApp
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();

            string mBinPath = @"C:\Programs\julia-1.10.4\bin";
            string mSysImg = "./../lib/julia/sys.dll";
            string mLoadPath = @"C:\Work\Packages\ActiveSuspension\ActiveSuspensionModel.jl";
            string mDepotPath = @"C:\Work\Packages\ActiveSuspension\ActiveSuspensionModel.jl\bin";


            Julia.StartJulia(mBinPath, mSysImg, mLoadPath, mDepotPath);


            //DEBUG
            Julia.jl_eval_string("using Revise");
            Julia.jl_eval_string("using ActiveSuspensionModel");
            //Julia.jl_eval_string("shedule(Task(()->Base._start()))");

            //RELEASE



            Data = new MainWindowViewModel();
            this.DataContext = Data;
        }

        
        private MainWindowViewModel Data { get; set; }


    }
}