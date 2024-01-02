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
using System.Net.Http.Headers;
using System.Net.Http;
using DmcExtension.CvOrchestrator.Util;

namespace DmcExtension.CvOrchestrator.Boundary
{
    public static class PictureAnalysisResultToDmcPublisher
    {
        [FunctionName("PictureAnalysisResultToDmcPublisher")]
        public async static Task PictureAnalysisResultToDmcPublisherFromEventHub(
            [EventHubTrigger("picture-analysis-results", Connection = "EventHubConnection", ConsumerGroup = "to-dmc-publisher")] string eventHubMessage,
            ILogger log)
        {
            log.LogInformation("C# EventHub trigger function (PictureAnalysisResultToDmcPublisherFromEventHub) processed a request.");

            var plantId = "unknown";
            var sfcId = "unknown";

            // TODO: Validate request
            var messageJson = JsonNode.Parse(eventHubMessage)!.AsObject();
            log.LogInformation($"Raw message from EventHub: {messageJson}.");

            plantId = messageJson?["Context"]?["Plant"]?.ToString() ?? plantId;
            sfcId = messageJson?["Context"]?["Sfc"]?.ToString() ?? sfcId;
            
            log.LogInformation($"Received message for plant {plantId} and SFC {sfcId}");

            var dmUri = GetDmUri(plantId, sfcId);
            using HttpClient dmClient = GetConfiguredHttpClient();
            log.LogInformation($"Successfully created DM client");

            var dmRequestBody = new StringContent(eventHubMessage, System.Text.Encoding.UTF8, "application/json");
            log.LogInformation($"Sending response to DM via URI {dmUri}.");
            var dmResponse = await dmClient.PostAsync(dmUri, dmRequestBody);
            log.LogInformation($"Response code from DM: {dmResponse.StatusCode}.");
            log.LogInformation($"Response body from DM: {dmResponse.Content.ReadAsStringAsync().Result}.");

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
