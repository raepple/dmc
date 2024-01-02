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
using Azure.Storage.Blobs;
using Microsoft.Azure.CognitiveServices.Vision.CustomVision.Prediction;
using DmcExtension.CvOrchestrator.Util;
using System.Collections.Generic;
using Azure.Identity;
using Azure.Storage.Blobs.Models;

namespace DmcExtension.CvOrchestrator.Boundary
{
    public static class PictureAnalysisProcessor
    {
        private static Lazy<CustomVisionPredictionClient> lazyCustomVisionClient = new Lazy<CustomVisionPredictionClient>(InitializeClient);
        private static CustomVisionPredictionClient CustomVisionPredictionClient => lazyCustomVisionClient.Value;

        private static CustomVisionPredictionClient InitializeClient()
        {
            CustomVisionPredictionClient client =
              new CustomVisionPredictionClient(new ApiKeyServiceClientCredentials(Settings.CustomVisionKey))
              { Endpoint = Settings.CustomVisionEndpoint };
            return client;
        }

        [FunctionName("PictureAnalysisProcessor")]
        public static async Task PictureAnalysisProcessorFromEventHub(
            [EventHubTrigger("picture-analysis-requests", Connection = "EventHubConnection")] string eventHubMessage,
            [EventHub("picture-analysis-results", Connection = "EventHubConnection")] IAsyncCollector<EventData> outputEvents,
            IBinder binder,
            ILogger log)
        {
            try
            {
                log.LogInformation("C# EventHub trigger function (PictureAnalysisProcessorFromEventHub) processed a request.");

                // TODO: Validate request body, invalid requests should be dropped.
                var messageJson = JsonNode.Parse(eventHubMessage)!.AsObject();
                var fileName = messageJson["FileName"];

                var attribute = new BlobAttribute($"{Settings.PictureBlobContainerName}/{fileName}", FileAccess.Read);
                attribute.Connection = "StorageAccountExtension";

                var blob = await binder.BindAsync<Stream>(attribute);
                log.LogInformation($"Downloaded {fileName} from blob storage.");
                              
                // Call Custom Vision Service to get predictions
                var imagePrediction = CustomVisionPredictionClient.DetectImage(new System.Guid(Settings.CustomVisionProjectGuid), Settings.CustomVisionModelName, blob);
                log.LogInformation($"Predictions received from Custom Vision Service for {fileName}");
                
                // Map predictions to DMC data structure.
                //TODO: What happens if we have no predictions?
                //TODO: Do we want to filter out predictions with low probability?
                List<object> predictions = new List<object>();
                foreach (var p in imagePrediction.Predictions)
                {
                    predictions.Add(new
                    {
                        predictionClass = GetDmcPredictionClass(p.TagName),
                        ncCode = GetDmcNcCode(p.TagName),
                        predictionScore = p.Probability,
                        predictionBoundingBoxCoords = GetPredictionBoundingBoxCoordsAsJsonString(p)                        
                    });
                    log.LogInformation("Non-conformance in " + fileName + " found with prediction value " + p.Probability);
                }
                messageJson.Add("predictions", JsonValue.Parse(JsonSerializer.Serialize(predictions)));

                // Forward message (with predictions) to Event Hub.
                var withPrediction = JsonSerializer.Serialize(messageJson, new JsonSerializerOptions
                {
                    WriteIndented = true,
                    Encoder = System.Text.Encodings.Web.JavaScriptEncoder.UnsafeRelaxedJsonEscaping
                });
                await outputEvents.AddAsync(new EventData(withPrediction));
            }
            catch (Exception e)
            {
                log.LogError(e.StackTrace);
            }
        }

        private static string GetPredictionBoundingBoxCoordsAsJsonString(Microsoft.Azure.CognitiveServices.Vision.CustomVision.Prediction.Models.PredictionModel p)
        {
            object predictions = new
            {
                type = "rect",
                x = p.BoundingBox.Left,
                y = p.BoundingBox.Top,
                w = p.BoundingBox.Width,
                h = p.BoundingBox.Height,
                score = p.Probability
            };
            return JsonSerializer.Serialize(new object[] { predictions });
        }

        //TODO: Avoid hardcoding prediction classes
        private static string GetDmcPredictionClass(string cvPredictionTagName)
        {
            switch (cvPredictionTagName)
            {
                case "missing screw":
                    return "MissingScrew";
                default:
                    return "UNKNOWN";
            }
        }


        //TODO: Avoid hardcoding NC codes
        private static string GetDmcNcCode(string cvPredictionTagName)
        {
            switch (cvPredictionTagName)
            {
                case "missing screw":
                    return "MISSING_SCREW";
                default:
                    return "Unknown";
            }
        }
    }
}