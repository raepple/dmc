using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Net.Http.Headers;
using System.Net.Http;
using DmcExtension.CvOrchestrator.Util;
using DmcExtension.CvOrchestrator.Model;

namespace DmcExtension.CvOrchestrator.Boundary
{
    public static class PictureAnalysisResultToDmcPublisher
    {
        [FunctionName("PictureAnalysisResultToDmcPublisher")]
        public async static Task PictureAnalysisResultToDmcPublisherFromEventHub(
            [EventHubTrigger("picture-analysis-results", Connection = "EventHubConnection", ConsumerGroup = "to-dmc-publisher")] string eventHubMessage,
            IBinder binder,
            ILogger log)
        {
            log.LogInformation("C# EventHub trigger function (PictureAnalysisResultToDmcPublisherFromEventHub) processed a request.");
            
            // TODO: Validate request
            var requestModel = JsonSerializer.Deserialize<PictureAnalysisRequestModel>(eventHubMessage, new JsonSerializerOptions(JsonSerializerDefaults.Web));
            log.LogInformation($"Raw message from EventHub: {requestModel}.");

            var plantId = requestModel.Context?.Plant ?? "unknown";
            var sfcId = requestModel.Context?.Sfc ?? "unknown";
            log.LogDebug($"Received message for plant {plantId} and SFC {sfcId}");

            requestModel.Context.Source = "DME";
            requestModel.Context.InspectionViewName = "default";

            // Read and conert picture from blob storage
            Stream pictureBlob = Util.Storage.ReadPicture(binder, log, requestModel.FileName).Result;
            MemoryStream stream = new MemoryStream();
            pictureBlob.CopyTo(stream);  
		    byte[] imageArray = stream.ToArray();  
		    string pictureBase64 = Convert.ToBase64String(imageArray);  

            // set base64 encoded picture in response message
            requestModel.FileContent = pictureBase64;

            var dmUri = GetDmUri(plantId, sfcId);
            using HttpClient dmClient = GetConfiguredHttpClient();
            log.LogDebug($"Successfully created DM client");

            var dmRequestBody = new StringContent(JsonSerializer.Serialize(requestModel, new JsonSerializerOptions {PropertyNamingPolicy = JsonNamingPolicy.CamelCase}), System.Text.Encoding.UTF8, "application/json");
            log.LogInformation($"Sending VI results {dmRequestBody.ReadAsStringAsync().Result} to URI {dmUri}");
            var dmResponse = await dmClient.PostAsync(dmUri, dmRequestBody);
            log.LogInformation($"Response code from DM: {dmResponse.StatusCode}.");
            log.LogDebug($"Response body from DM: {dmResponse.Content.ReadAsStringAsync().Result}.");

        }

        private static Uri GetDmUri(string plantId, string sfcId) {
            UriBuilder dmUriBuilder = new(Settings.DmInspectionLogEndpoint);
            dmUriBuilder.Query = $"plant={plantId}&sfc={sfcId}";
            return dmUriBuilder.Uri;
        }

        private static HttpClient GetConfiguredHttpClient() {
            string accessToken = GetAccessToken().Result;
            HttpClient dmClient = new();
            dmClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
            return dmClient;
        }

        private async static Task<String> GetAccessToken() {
            string tokenEndpointUrl = Settings.DmTokenEndpoint;
            string oauthClientid = Settings.DmOAuthClientId;
            string oauthClientsecret = Settings.DmOAuthClientSecret;

            using HttpClient tokenClient = new();
            tokenClient.DefaultRequestHeaders.Accept.Clear();

            string plainText = oauthClientid + ":" + oauthClientsecret;
            byte[] authHeader = System.Text.Encoding.UTF8.GetBytes(plainText);
            string authHeaderBase64 = System.Convert.ToBase64String(authHeader);

            tokenClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Basic", authHeaderBase64);
            var jsonContent = new StringContent("grant_type=client_credentials", System.Text.Encoding.UTF8, "application/x-www-form-urlencoded");

            var json = await tokenClient.PostAsync(tokenEndpointUrl, jsonContent);

            var jsonString = await json.Content.ReadAsStreamAsync();

            JsonNode token = JsonNode.Parse(jsonString)!;
            string accessToken = token["access_token"]!.ToString()!;
            return accessToken;
        }
    }
}
