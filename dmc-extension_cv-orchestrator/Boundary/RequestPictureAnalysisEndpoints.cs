using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Azure.Messaging.EventHubs;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Attributes;
using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Enums;
using Microsoft.OpenApi.Models;
using DmcExtension.CvOrchestrator.Model;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Text.Json.Serialization;
using DmcExtension.CvOrchestrator.Util;

namespace DmcExtension.CvOrchestrator.Boundary
{
    public static class RequestPictureAnalysisEndpoints
    {
        [OpenApiOperation]
        [OpenApiSecurity("function_key", SecuritySchemeType.ApiKey, Name = "code", In = OpenApiSecurityLocationType.Query)]
        [OpenApiRequestBody("application/json", typeof(RequestPictureAnalysisEndpointsRequestModel), Description = "The request body")]
        [OpenApiResponseWithBody(System.Net.HttpStatusCode.OK, "text/plain", typeof(string))]
        [FunctionName("RequestPictureAnalysis")]
        public static async Task<IActionResult> PostRequestPictureAnalysis(
            [HttpTrigger(AuthorizationLevel.Function, "post", Route = null)] HttpRequest req,
            [EventHub("picture-analysis-requests", Connection = "EventHubConnectionAppSetting")]IAsyncCollector<EventData> outputEvents,
            IBinder binder,
            ILogger log)
        {
            log.LogInformation("C# HTTP trigger function (PostRequestPictureAnalysis) processed a request.");

            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            return await RequestPictureAnalysisDelegate(requestBody, outputEvents, binder, log);
        }

        public static async Task<IActionResult> RequestPictureAnalysisDelegate(
            string requestBody,
            IAsyncCollector<EventData> outputEvents,
            IBinder binder,
            ILogger log)
        {
            try {
                var containerName = "raw-picutres";

                // TODO: Validate request

                var requestModel = JsonSerializer.Deserialize<RequestPictureAnalysisEndpointsRequestModel>(requestBody, new JsonSerializerOptions(JsonSerializerDefaults.Web));
                var plantId = requestModel.Context?.Plant ?? "unknown";
                var fileContent = Convert.FromBase64String(requestModel.FileContent);

                // Compile file name and path; create BlobAttribute to connect to Blob Storage.
                var timeStamp = DateTime.UtcNow.ToString("yyyyMMdd_HHmmss");
                var fileName = $"{plantId}_{timeStamp}.jpg";
                var attribute = new BlobAttribute($"{containerName}/{fileName}", FileAccess.Write);
                attribute.Connection = "PICTURE_STORAGE_ACCOUNT_ENDPOINT";

                using(var blob = await binder.BindAsync<Stream>(attribute))
                {
                    blob.Write(fileContent);
                }

                // Forward message (unchanged) to Event Hub.
                await outputEvents.AddAsync(new EventData(requestBody));

                string responseMessage = "Successfully received picture for analysis.";

                return new OkObjectResult(responseMessage);
            } catch (Exception e) {
                log.LogError(e.StackTrace);
                return new BadRequestObjectResult(e.Message);
            }
        }
    }
}