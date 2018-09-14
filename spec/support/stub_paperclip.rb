# http://dev.mensfeld.pl/2013/11/paperclip-and-rspec-stubbing-paperclip-imagemagick-to-make-specs-run-faster-but-with-image-resolution-validation/
# We stub some Paperclip methods - so it won't call shell slow commands
# This allows us to speedup paperclip tests 3-5x times.
module Paperclip
  def self.run(cmd, arguments = "", interpolation_values = {}, local_options = {})
    cmd == 'convert' ? nil : super
  end
end
