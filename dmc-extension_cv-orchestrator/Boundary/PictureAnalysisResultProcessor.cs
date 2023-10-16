using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Azure.Messaging.EventHubs;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Text.Json.Serialization;


namespace DmcExtension.CvOrchestrator.Boundary
{
    public static class PictureAnalysisResultProcessor
    {
        [FunctionName("PictureAnalysisResultProcessor")]
        public static void PictureAnalysisResultProcessorFromEventHub(
            [EventHubTrigger("picture-analysis-results", Connection = "EventHubConnectionAppSetting", ConsumerGroup = "to-console-logger")] string eventHubMessage,
            ILogger log)
        {
            log.LogInformation("C# EventHub trigger function (PictureAnalysisResultProcessorFromEventHub) processed a request.");
            log.LogInformation(eventHubMessage.Substring(0, 500) + "...");
        }
    }
}