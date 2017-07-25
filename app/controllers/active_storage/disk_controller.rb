# Serves files stored with the disk service in the same way that the cloud services do.
# This means using expiring, signed URLs that are meant for immediate access, not permanent linking.
# Always go through the BlobsController, or your own authenticated controller, rather than directly
# to the service url.
class ActiveStorage::DiskController < ActionController::Base
  def show
    if key = decode_verified_key
      send_data disk_service.download(key),
        filename: params[:filename], disposition: disposition_param, content_type: params[:content_type]
    else
      head :not_found
    end
  end

  def update
    if metadata = decode_verified_metadata
      disk_service.upload metadata[:key], request.body, checksum: metadata[:checksum]
    else
      head :not_found
    end
  rescue ActiveStorage::IntegrityError
    head :unprocessable_entity
  end

  private
    def disk_service
      ActiveStorage::Blob.service
    end

    def decode_verified_key
      ActiveStorage.verifier.verified(params[:encoded_key], purpose: :blob_key)
    end

    def decode_verified_metadata
      ActiveStorage.verifier.verified(params[:encoded_metadata], purpose: :blob_metadata)
    end

    def disposition_param
      params[:disposition].presence_in(%w( inline attachment )) || "inline"
    end
end
