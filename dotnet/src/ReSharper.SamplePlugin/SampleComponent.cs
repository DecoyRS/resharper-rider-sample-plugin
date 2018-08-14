using System.Diagnostics;
using JetBrains.ProjectModel;

#if RIDER
using JetBrains.ReSharper.Host.Features;
using JetBrains.Rider.Model;
#endif

namespace ReSharper.SamplePlugin
{
    [SolutionComponent]
    public class SampleComponent
    {
        public SampleComponent(ISolution solution)
        {
            Debugger.Launch();
#if RESHARPER
#elif RIDER
            var myRiderModel = solution.GetProtocolSolution().GetSampleModel();
#endif
        }
    }
}