using System.Collections.Generic;

namespace DmcExtension.CvOrchestrator.Model
{
    public class PictureAnalysisRequestModel {
        public PictureAnalysisContextModel Context { get; set; }
        public string FileContent { get; set; }
        public string FileName { get; set; }
        public string FileContentType { get; set; }
        public string Callback { get; set; }
        public IList<PictureAnalysisPredictionModel>? Predictions { get; set; }
    }
    public class PictureAnalysisContextModel {
        public string Plant { get; set; }
        public string Sfc { get; set; }
        public string Source { get; set; }
        public string InspectionViewName { get; set; }
    }

    public class PictureAnalysisPredictionModel {
        public string PredictionClass { get; set; }
        public string NcCode { get; set; }
        public double PredictionScore { get; set; }
        public IList<PictureAnalysisPredictionBoundingBoxCoordinatesModel>? PredictionBoundingBoxCoordsObj { get; set; }
        public string PredictionBoundingBoxCoords { get; set; }
    }

    public class PictureAnalysisPredictionBoundingBoxCoordinatesModel {
        public string Type { get; set; }
        public double X { get; set; }
        public double Y { get; set; }
        public double W { get; set; }
        public double H { get; set; }
        public double Score { get; set; }
    }
}
