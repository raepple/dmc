using System;

namespace DmcExtension.CvOrchestrator.Util
{
    public static class Settings
    {
        private static Lazy<string> lazyCustomVisionEndpoint = new Lazy<string>(InitializeFromEnvironmentVariable("COGNITIVE_SERVICES_CUSTOM_VISION_ENDPOINT"));
        public static string CustomVisionEndpoint => lazyCustomVisionEndpoint.Value;
        private static Lazy<string> lazyCustomVisionKey = new Lazy<string>(InitializeFromEnvironmentVariable("COGNITIVE_SERVICES_CUSTOM_VISION_SUBSCRIPTION_KEY"));
        public static string CustomVisionKey => lazyCustomVisionKey.Value;
        private static Lazy<string> lazyCustomVisionProjectGuid = new Lazy<string>(InitializeFromEnvironmentVariable("COGNITIVE_SERVICES_CUSTOM_VISION_PROJECT_GUID"));
        public static string CustomVisionProjectGuid => lazyCustomVisionProjectGuid.Value;
        private static Lazy<string> lazyCustomVisionModelName = new Lazy<string>(InitializeFromEnvironmentVariable("COGNITIVE_SERVICES_CUSTOM_VISION_MODEL_NAME"));
        public static string CustomVisionModelName => lazyCustomVisionModelName.Value;
        private static Lazy<string> lazyDmTokenEndpoint = new Lazy<string>(InitializeFromEnvironmentVariable("DM_TOKEN_ENDPOINT"));
        public static string DmTokenEndpoint => lazyDmTokenEndpoint.Value;
        private static Lazy<string> lazyDmOAuthClientId = new Lazy<string>(InitializeFromEnvironmentVariable("DM_OAUTH_CLIENT_ID"));
        public static string DmOAuthClientId => lazyDmOAuthClientId.Value;
        private static Lazy<string> lazyDmOAuthClientSecret = new Lazy<string>(InitializeFromEnvironmentVariable("DM_OAUTH_CLIENT_SECRET"));
        public static string DmOAuthClientSecret => lazyDmOAuthClientSecret.Value;
        #nullable enable

        private static Lazy<string> lazyDmInspectionLogEndpoint = new Lazy<string>(InitializeFromEnvironmentVariable("DM_INSPECTION_LOG_ENDPOINT"));
        public static string DmInspectionLogEndpoint => lazyDmInspectionLogEndpoint.Value;
        public static Lazy<string> lazyPictureStorageAccountEndpoint = new Lazy<string>(InitializeFromEnvironmentVariable("PICTURE_STORAGE_ACCOUNT_ENDPOINT"));
        public static string PictureStorageAccountEndpoint => lazyPictureStorageAccountEndpoint.Value;
        public static string VIPictureBlobContainerName = "raw-pictures";
        public static string MockedCameraPicturesContainerName = "pictures";

        private static string InitializeFromEnvironmentVariable(string variableName)
        {
            var retVal = Environment.GetEnvironmentVariable(variableName);
            if (retVal == null)
                Console.WriteLine($"Environment variable {variableName} must be specified.");
            return retVal;
        }
    }
}

