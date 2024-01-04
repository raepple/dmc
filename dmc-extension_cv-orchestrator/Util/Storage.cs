using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;

namespace DmcExtension.CvOrchestrator.Util
{
    public static class Storage
    {        
        public static async Task<Stream> ReadPictureAsync(IBinder binder, ILogger log, String blobContainerName, String fileName)
        {
            var attribute = new BlobAttribute($"{blobContainerName}/{fileName}", FileAccess.Read);
            attribute.Connection = "StorageAccountExtension";

            Stream blob = await binder.BindAsync<Stream>(attribute);
            log.LogInformation($"Downloaded {fileName} from blob storage.");
	  
            return blob;
        }
    }
}