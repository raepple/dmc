package com.microsoft.samples;

import java.io.ByteArrayOutputStream;
import java.util.Optional;

import com.microsoft.azure.functions.ExecutionContext;
import com.microsoft.azure.functions.HttpMethod;
import com.microsoft.azure.functions.HttpRequestMessage;
import com.microsoft.azure.functions.HttpResponseMessage;
import com.microsoft.azure.functions.HttpStatus;
import com.microsoft.azure.functions.annotation.AuthorizationLevel;
import com.microsoft.azure.functions.annotation.FunctionName;
import com.microsoft.azure.functions.annotation.HttpTrigger;
import com.microsoft.azure.storage.CloudStorageAccount;
import com.microsoft.azure.storage.blob.BlobProperties;
import com.microsoft.azure.storage.blob.CloudBlob;
import com.microsoft.azure.storage.blob.CloudBlobClient;
import com.microsoft.azure.storage.blob.CloudBlobContainer;

/**
 * Azure Functions for the SAP DM Visual Inspection extension
 */
public class VisualInspectionExtension {
    @FunctionName("InspectionRequestReception")
    public HttpResponseMessage processRequest(
            @HttpTrigger(name = "req", methods = {
                    HttpMethod.POST }, authLevel = AuthorizationLevel.ANONYMOUS) HttpRequestMessage<Optional<String>> request,
            final ExecutionContext context) {
        context.getLogger().info("InspectionRequestReception processing a request");
        return request.createResponseBuilder(HttpStatus.OK).body("Received Inspection Request").build();
    }

    @FunctionName("TakePictureRequest")
    public HttpResponseMessage simulateCamera(
            @HttpTrigger(name = "req", methods = {
                    HttpMethod.GET }, authLevel = AuthorizationLevel.ANONYMOUS) HttpRequestMessage<Optional<String>> request,
            final ExecutionContext context) {
        context.getLogger().info("TakePictureRequest processing a request");    
        return request.createResponseBuilder(HttpStatus.OK)
            .header("Content-Type", "image/jpg")
            .body(readImageFromStorageAccount())
            .build();
        // return request.createResponseBuilder(HttpStatus.OK).body(readImageFromStorageAccount()).build();
    }

    private static byte[] readImageFromStorageAccount() {

        String accountKey = System.getenv("StorageAccountKey");

        String storageConnectionString = "DefaultEndpointsProtocol=https;"
                + "AccountName=dmcextsa;"
                + "AccountKey=" + accountKey;

        try {
            CloudStorageAccount storageAccount = CloudStorageAccount.parse(storageConnectionString);
            CloudBlobClient blobClient = storageAccount.createCloudBlobClient();
            CloudBlobContainer container = blobClient.getContainerReference("images");
            CloudBlob image = container.getBlockBlobReference("Ragul____Steuerkopf_oben_374.jpg");

            System.out.println("Image downloaded successfully.");
            BlobProperties blobProperties = image.getProperties();
            ByteArrayOutputStream baos = new ByteArrayOutputStream((int)blobProperties.getLength());
            image.download(baos);
            return baos.toByteArray();
        } catch (Exception e) {
            System.out.println("Exception occurred: " + e.getMessage());
            return null;
        }
    }
}
