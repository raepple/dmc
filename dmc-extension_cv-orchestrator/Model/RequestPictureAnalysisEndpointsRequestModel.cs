namespace DmcExtension.CvOrchestrator.Model
{
    public class RequestPictureAnalysisEndpointsRequestModel {
        public RequestPictureAnalysisEndpointsRequestContextModel Context { get; set; }
        public string FileContent { get; set; }
        public string FileContentType { get; set; }
        public string Callback { get; set; }
    }

    public class RequestPictureAnalysisEndpointsRequestContextModel {
        public string Plant { get; set; }
        public string Sfc { get; set; }
        public string Source { get; set; }
        public string InspectionViewName { get; set; }
    }
}
