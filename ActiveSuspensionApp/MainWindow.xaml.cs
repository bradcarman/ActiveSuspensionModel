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

            Julia.StartJulia();

            //DEBUG
            Julia.jl_eval_string("using ActiveSuspensionModel");

            //RELEASE

            // --------------

            IntPtr pars_ptr = Julia.jl_eval_string("ActiveSuspensionModel.SystemParams()");
            SystemParams pars = new SystemParams(pars_ptr, true);

            pars.pid.kp = 50;

            Methods.send_params(pars);


            Julia.jl_eval_string("Base._start()");
        }
    }
}