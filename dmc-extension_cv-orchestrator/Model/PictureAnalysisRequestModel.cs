namespace DmcExtension.CvOrchestrator.Model
{
    public class PictureAnalysisRequestModel {
        public PictureAnalysisContextModel Context { get; set; }
        public string FileContent { get; set; }
        public string FileName { get; set; }
        public string FileContentType { get; set; }
        public string Callback { get; set; }
    }
    public class PictureAnalysisContextModel {
        public string Plant { get; set; }
        public string Sfc { get; set; }
        public string Source { get; set; }
        public string InspectionViewName { get; set; }
    }
}
