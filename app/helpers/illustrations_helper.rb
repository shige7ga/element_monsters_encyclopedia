module IllustrationsHelper
  def og_image_url(image)
    if image.blob.service_name == "cloudinary"
      cloudinary_url(
        image.blob.key,
        width: 1200,
        height: 630,
        crop: "pad",
        background: "#020617"
      )
    else
      polymorphic_url(image)
    end
  end
end
