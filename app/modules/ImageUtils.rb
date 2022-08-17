module ImageUtils

    # reduce the size of large images to a maximum width/height
    def optimize_images(params)

        if params[:images].present?
            
            params[:images].each do |image|
            
                mini_image = MiniMagick::Image.new(image.tempfile.path)

                if mini_image.width > 1200 || mini_image.height > 1200
                    mini_image.resize '1200x1200'
                end

            end
            
        end
                
    end  

    # purge images marked for removal
    def purge_marked_images(params)

        attachments = ActiveStorage::Attachment.where(id: params[:deleted_img_ids])
        attachments.map(&:purge)

    end

end