using System;
using System.Text.Json;
using Microsoft.Azure.Functions.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;

[assembly: FunctionsStartup(typeof(DmcExtension.CvOrchestrator.Startup))]

namespace DmcExtension.CvOrchestrator
{
    class Startup : FunctionsStartup
    {
        public override void ConfigureAppConfiguration(IFunctionsConfigurationBuilder builder)
        {
            Console.WriteLine("Starting up...");
        }
    
        public override void Configure(IFunctionsHostBuilder builder)
        {
        }
    }
}
