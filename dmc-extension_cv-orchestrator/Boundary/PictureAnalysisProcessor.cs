using System;
using System.Threading.Tasks;
using Microsoft.Azure.WebJobs;
using Azure.Messaging.EventHubs;
using Microsoft.Extensions.Logging;
using System.Text.Json;
using Microsoft.Azure.CognitiveServices.Vision.CustomVision.Prediction;
using DmcExtension.CvOrchestrator.Util;
using System.Collections.Generic;
using System.IO;
using DmcExtension.CvOrchestrator.Model;
using System.Text;

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
                log.LogInformation($"Raw message from EventHub: {eventHubMessage}.");
                var requestModel = JsonSerializer.Deserialize<PictureAnalysisRequestModel>(eventHubMessage, new JsonSerializerOptions(JsonSerializerDefaults.Web));
                
                // Download picture from blob storage
                Stream fileStream = Util.Storage.ReadPictureAsync(binder, log, Settings.VIPictureBlobContainerName, requestModel.FileName).Result;

                // Call Custom Vision Service to get predictions
                var imagePrediction = CustomVisionPredictionClient.DetectImage(new System.Guid(Settings.CustomVisionProjectGuid), Settings.CustomVisionModelName, fileStream);
                log.LogInformation("Predictions received from Custom Vision Service");

                // Map predictions to DMC data structure.
                // TODO: What happens if we have no predictions?
                // TODO: Do we want to filter out predictions with low probability?
                List<PictureAnalysisPredictionModel> predictions = new List<PictureAnalysisPredictionModel>();
                foreach (var p in imagePrediction.Predictions)
                {
                    predictions.Add(new PictureAnalysisPredictionModel
                    {
                        PredictionClass = GetDmcPredictionClass(p.TagName),
                        NcCode = GetDmcNcCode(p.TagName),
                        PredictionScore = p.Probability,
                        PredictionBoundingBoxCoordsObj = GetPredictionBoundingBoxCoordinates(p)
                    });
                    log.LogInformation($"Non-conformance found with prediction value {p.Probability}");
                }
                requestModel.Predictions = predictions;

                // Forward message (with predictions) to Event Hub.
                var json = JsonSerializer.Serialize(requestModel);
                var eventData = new EventData(Encoding.UTF8.GetBytes(json));
                await outputEvents.AddAsync(eventData);
            }
            catch (Exception e)
            {
                log.LogError(e.StackTrace);
            }
        }

        private static List<PictureAnalysisPredictionBoundingBoxCoordinatesModel> GetPredictionBoundingBoxCoordinates(Microsoft.Azure.CognitiveServices.Vision.CustomVision.Prediction.Models.PredictionModel p)
        {
           var boundingBox = new PictureAnalysisPredictionBoundingBoxCoordinatesModel { 
                Type = "rect",
                X = p.BoundingBox.Left,
                Y = p.BoundingBox.Top,
                W = p.BoundingBox.Width,
                H = p.BoundingBox.Height,
                Score = p.Probability
            };
            return new List<PictureAnalysisPredictionBoundingBoxCoordinatesModel> { boundingBox };
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