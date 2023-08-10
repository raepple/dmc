package com.microsoft.samples;

import org.apache.commons.io.IOUtils;
import org.apache.http.HttpResponse;
import org.apache.http.NameValuePair;
import org.apache.http.client.HttpClient;
import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.client.methods.HttpUriRequest;
import org.apache.http.message.BasicNameValuePair;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.sap.cloud.sdk.cloudplatform.connectivity.DestinationAccessor;
import com.sap.cloud.sdk.cloudplatform.connectivity.HttpClientAccessor;
import com.sap.cloud.sdk.cloudplatform.connectivity.HttpDestination;

import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;



@WebServlet("/dmcmock")
public class DMCMockServlet extends HttpServlet
{
    private static final long serialVersionUID = 1L;
    private static final Logger logger = LoggerFactory.getLogger(DMCMockServlet.class);

    @Override
    protected void doGet( final HttpServletRequest request, final HttpServletResponse response )
        throws IOException
    {
         logger.info("Trying to get the destination");
            HttpDestination azureAPIM = DestinationAccessor.getDestination("AzureAPIM").asHttp();
            logger.info("Successfully accessed the destination");
            HttpClient client = HttpClientAccessor.getHttpClient(azureAPIM);
            logger.info("Successfully created HTTP Client");
            String uri = azureAPIM.getUri().toString();
            HttpGet takeCameraPictureReq = new HttpGet(uri);
            // HttpPost azureAPIMRequest = new HttpPost(uri);

            // final List<NameValuePair> params = new ArrayList<NameValuePair>();
            // params.add(new BasicNameValuePair("name", "Martin"));
            // azureAPIMRequest.setEntity(new UrlEncodedFormEntity(params));
                      
            HttpResponse azureAPIMResponse = client.execute(takeCameraPictureReq);
            logger.info("Successfully sent the request (GET)");
            response.getWriter().println("Response code from APIM: " + azureAPIMResponse.getStatusLine().getStatusCode());
            logger.info("Response code from APIM " + uri + " : " + azureAPIMResponse.getStatusLine().getStatusCode());
            String body = IOUtils.toString(azureAPIMResponse.getEntity().getContent(), "UTF-8");
            response.getWriter().println("Body: " + body);
    }
}
