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
using DmcExtension.CvOrchestrator.Util;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Text.Json.Serialization;
using System.Collections.Generic;

using System.Linq;
using Azure;
using Azure.Identity;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;

using System.Net.Http;
using System.Security.Cryptography;

namespace DmcExtension.CvOrchestrator.Boundary
{
    public static class TakePictureRequestEndpoints
    {

        private static Lazy<BlobContainerClient> BlobContainerClient = new Lazy<BlobContainerClient>(InitializeBlobContainerClient());

        private static Lazy<IList<string>> BlobNames = new Lazy<IList<string>>(InitializeBlobNames());

        private static BlobContainerClient InitializeBlobContainerClient()
        {
            BlobServiceClient client = new(new Uri(Settings.PictureStorageAccountEndpoint), new DefaultAzureCredential());
            BlobContainerClient blobContainerClient = client.GetBlobContainerClient("pictures");
            return blobContainerClient;
        }

        private static IList<string> InitializeBlobNames()
        {
            var retVal = new List<string>();
            var resultSegment = BlobContainerClient.Value.GetBlobs();
            foreach (Page<BlobItem> blobPage in resultSegment.AsPages())
            {
                foreach (BlobItem blobItem in blobPage.Values)
                {
                    Console.WriteLine("Blob name: {0}", blobItem.Name);
                    retVal.Add(blobItem.Name);
                }
            }
            return retVal;
        }

        [FunctionName("TakePictureRequestBase64")]
        [OpenApiOperation]
        [OpenApiSecurity("function_key", SecuritySchemeType.ApiKey, Name = "code", In = OpenApiSecurityLocationType.Query)]
        [OpenApiParameter("plant", In = ParameterLocation.Query, Required = true, Type = typeof(string), Description = "The plant ID")]
        [OpenApiParameter("sfc", In = ParameterLocation.Query, Required = true, Type = typeof(string), Description = "The SFC ID")]
        [OpenApiResponseWithBody(System.Net.HttpStatusCode.OK, "text/plain", typeof(string))]
        public static async Task<IActionResult> TakePictureRequestBase64(
            [HttpTrigger(AuthorizationLevel.Function, "get", Route = null)] HttpRequest req,
            ILogger log)
        {
            log.LogInformation("C# HTTP trigger function (TakePictureRequestBase64) processed a request.");

            try
            {
                var (plantId, sfcId) = GetPlantAndSfcFromRequest(req);
                var demoImageBlobName = PickDemoPicture(plantId, sfcId);
                log.LogInformation($"Picture file name: {demoImageBlobName}");
                var (fileContent, mimeType) = await GetBlobContent(demoImageBlobName);

                return new OkObjectResult(Convert.ToBase64String(fileContent));
            }
            catch (Exception e)
            {
                log.LogError(e.InnerException.Message);
                return new BadRequestObjectResult(e.Message);
            }
        }

        private static Tuple<string, string> GetPlantAndSfcFromRequest(HttpRequest req)
        {
            string plantId = (string)req.Query["plant"];
            string sfcId = (string)req.Query["sfc"];

            if (plantId == null || sfcId == null)
                throw new Exception("Query parameters plant and sfc must be specified.");

            return new Tuple<string, string>(plantId, sfcId);
        }

        private static String PickDemoPicture(string plantId, string sfcId)
        {
            string concat = $"{plantId}_{sfcId}";
            MD5 md5Hasher = MD5.Create();
            var hashed = md5Hasher.ComputeHash(System.Text.Encoding.UTF8.GetBytes(concat));
            var intHash = BitConverter.ToUInt16(hashed, 0);

            int index = intHash % BlobNames.Value.Count;
            var demoImageBlobName = BlobNames.Value[index];
            return demoImageBlobName;
        }

        private static async Task<Tuple<byte[], string>> GetBlobContent(string blobName)
        {
            var blobClient = BlobContainerClient.Value.GetBlobClient(blobName);
            using (var readStream = await blobClient.OpenReadAsync())
            {
                var memoryStream = new MemoryStream();
                readStream.CopyTo(memoryStream);
                // TODO: Replace fixed mime type with actual mime type from blob metadata.
                return new Tuple<byte[], string>(memoryStream.ToArray(), "image/jpeg");
            }
        }
    }
}