# encoding: utf-8

class UserGamePictureUploader < CarrierWave::Uploader::Base

  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  include CarrierWave::MiniMagick

  # Choose what kind of storage to use for this uploader:
  storage Idnet.config.game_center.uploadings.storage

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "user_game_pictures/#{model.identity_id}"
  end

  def filename
    "#{model.id}.#{file.extension}"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end
  version :thumb do
    process :resize_to_fit => [180, 135]
  end

  version :big do
    process :resize_to_fit => [600, 400]
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(jpg jpeg gif png)
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end

  def fog_credentials
    Idnet.config.game_center.uploadings.cloud_credentials.to_hash.symbolize_keys
  end

  def fog_directory
    "game-center"
  end

end
