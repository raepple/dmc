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
using DmcExtension.CvOrchestrator.Util;
using Azure.Storage.Blobs;
using Azure.Identity;
using System.Text;

namespace DmcExtension.CvOrchestrator.Boundary
{
    public static class RequestPictureAnalysisEndpoints
    {
        [OpenApiOperation]
        [OpenApiSecurity("function_key", SecuritySchemeType.ApiKey, Name = "code", In = OpenApiSecurityLocationType.Query)]
        [OpenApiRequestBody("application/json", typeof(PictureAnalysisRequestModel), Description = "The request body")]
        [OpenApiResponseWithBody(System.Net.HttpStatusCode.OK, "text/plain", typeof(string))]
        [FunctionName("RequestPictureAnalysis")]
        public static async Task<IActionResult> PostRequestPictureAnalysis(
            [HttpTrigger(AuthorizationLevel.Function, "post", Route = null)] HttpRequest req,
            [EventHub("picture-analysis-requests", Connection = "EventHubConnection")]IAsyncCollector<EventData> outputEvents,
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
                // TODO: Validate request
                
                var requestModel = JsonSerializer.Deserialize<PictureAnalysisRequestModel>(requestBody, new JsonSerializerOptions(JsonSerializerDefaults.Web));
                var plantId = requestModel.Context?.Plant ?? "unknown";
                var fileContent = Convert.FromBase64String(requestModel.FileContent);

                // Compile file name and path
                var timeStamp = DateTime.UtcNow.ToString("yyyyMMdd_HHmmss");
                var fileName = $"{plantId}_{timeStamp}.jpg";

                var attribute = new BlobAttribute($"{Settings.PictureBlobContainerName}/{fileName}", FileAccess.Write);
                attribute.Connection = "StorageAccountExtension";

                using(var blob = await binder.BindAsync<Stream>(attribute))
                {
                    blob.Write(fileContent);
                }

                // Add the file name to the request model
                requestModel.FileContent = null;
                requestModel.FileName = fileName;

                // Send JSON message with the filename to processing queue.
                var json = JsonSerializer.Serialize(requestModel);
                var eventData = new EventData(Encoding.UTF8.GetBytes(json));
                await outputEvents.AddAsync(eventData);

                // Return HTTP 202 (Accepted) to SAP DM
                return new AcceptedResult();
            } catch (Exception e) {
                log.LogError(e.StackTrace);
                return new BadRequestObjectResult(e.Message);
            }
        }
    }
}