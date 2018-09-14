# encoding: utf-8

class VideoUploader < CarrierWave::Uploader::Base

  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  include CarrierWave::MiniMagick
  include CarrierWave::Video
  include CarrierWave::Video::Thumbnailer
  include CarrierWave::Backgrounder::Delay

  # Choose what kind of storage to use for this uploader:

  # Path needs to be changed, to not mess up
  storage Idnet.config.game_center.uploadings.storage

  # storage :fog

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "videos/#{model.game_id || 'none'}/#{model.id}"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  # Process files as they are uploaded:
  # process :scale => [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  # using custom ffmpeg settings
  version :mp4 do
    process encode_video: [:mp4, { custom: '-codec:v libx264 -profile:v baseline -preset placebo -crf 32 -an -movflags faststart -vf scale=464:348 -r 24', force_custom: true }]
    def full_filename(for_file)
      "#{File.basename(for_file, File.extname(for_file))}.mp4"
    end
  end

  version :webm do
    process encode_video: [:webm, { custom: '-vcodec libvpx -threads 4 -deadline good -cpu-used 0 -vb 200000 -keyint_min 0 -g 360 -qmin 0 -qmax 50 -mb_threshold 0 -vf "scale=464:348, crop=464:348:0:0" -r 25', force_custom: true }]
    def full_filename(for_file)
      "#{File.basename(for_file, File.extname(for_file))}.webm"
    end
  end

  # this one uses different processing(ffmpeg2theora)
  version :ogv do
    process encode_video: [:ogv, { custom: '-codec:v libtheora -qscale:v 3 -vf scale=464:348 -r 24', force_custom: true }]
    def full_filename(for_file)
      "#{File.basename(for_file, File.extname(for_file))}.ogv"
    end
  end

  version :swf do
    process encode_video: [:swf, { callbacks: { after_transcode: :encode_success }, custom: '-qscale:v 12 -an -movflags faststart -vf scale=464:348 -r 24', force_custom: true }]
    def full_filename(for_file)
      "#{File.basename(for_file, File.extname(for_file))}.swf"
    end
  end

  # Create different versions of your uploaded files:
  # version :thumb do
  #   process :resize_to_fit => [50, 50]
  # end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  # def extension_white_list
  #   %w(jpg jpeg gif png)
  # end

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
