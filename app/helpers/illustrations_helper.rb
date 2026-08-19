module IllustrationsHelper
  def og_image_url(image)
    if image.blob.service_name == "cloudinary"
      image.blob.url
    else
      polymorphic_url(image)
    end
  end
end
