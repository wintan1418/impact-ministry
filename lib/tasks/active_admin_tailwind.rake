# Compiles ActiveAdmin's separate Tailwind bundle alongside the main app bundle.
# AA ships a Tailwind v4 config (`tailwind-active_admin.config.js`) that pulls
# in its own component CSS — we keep it isolated from the main design system.

namespace :tailwindcss do
  namespace :active_admin do
    def aa_input  = Rails.root.join("app/assets/tailwind/active_admin.css").to_s
    def aa_output = Rails.root.join("app/assets/builds/active_admin.css").to_s

    desc "Build the ActiveAdmin Tailwind bundle"
    task :build do
      require "tailwindcss/ruby"
      cmd = [
        Tailwindcss::Ruby.executable,
        "-i", aa_input,
        "-o", aa_output,
        "--minify"
      ]
      system(*cmd, exception: true)
    end

    desc "Watch the ActiveAdmin Tailwind bundle"
    task :watch do
      require "tailwindcss/ruby"
      cmd = [
        Tailwindcss::Ruby.executable,
        "-i", aa_input,
        "-o", aa_output,
        "-w"
      ]
      begin
        system(*cmd)
      rescue Interrupt
        # graceful stop
      end
    end
  end
end

# Run AA's build whenever the main one runs (e.g. during assets:precompile).
Rake::Task["tailwindcss:build"].enhance([ "tailwindcss:active_admin:build" ])
