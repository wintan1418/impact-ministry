# Lazily load aws-sdk-s3 (declared with require: false in Gemfile) only when
# R2 is actually configured. This keeps boot fast in dev when we're using
# local disk storage as a fallback (R2_BUCKET blank per .env.example).
require "aws-sdk-s3" if ENV["R2_BUCKET"].present?
