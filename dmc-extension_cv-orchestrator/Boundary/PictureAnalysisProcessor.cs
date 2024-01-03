using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.Azure.WebJobs;
using Azure.Messaging.EventHubs;
using Microsoft.Extensions.Logging;
using System.Text.Json;
using System.Text.Json.Nodes;
using Microsoft.Azure.CognitiveServices.Vision.CustomVision.Prediction;
using DmcExtension.CvOrchestrator.Util;
using System.Collections.Generic;

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
                
                // Read picture from blob storage
                string fileName = messageJson?["FileName"]?.ToString();
                Stream pictureBlob = Util.Storage.ReadPicture(binder, log, fileName).Result;

                // Call Custom Vision Service to get predictions
                var imagePrediction = CustomVisionPredictionClient.DetectImage(new System.Guid(Settings.CustomVisionProjectGuid), Settings.CustomVisionModelName, pictureBlob);
                log.LogInformation("Predictions received from Custom Vision Service");

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
                    log.LogInformation($"Non-conformance found with prediction value {p.Probability}");
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