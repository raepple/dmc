using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;

namespace DmcExtension.CvOrchestrator.Util
{
    public static class Storage
    {        
        public static async Task<Stream> ReadPicture(IBinder binder, ILogger log, String fileName)
        {
            var attribute = new BlobAttribute($"{Settings.PictureBlobContainerName}/{fileName}", FileAccess.Read);
            attribute.Connection = "StorageAccountExtension";

            Stream blob = await binder.BindAsync<Stream>(attribute);
            log.LogInformation($"Downloaded {fileName} from blob storage.");

            return blob;
        }
    }
}