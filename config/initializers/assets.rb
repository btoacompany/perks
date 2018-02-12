# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )
Rails.application.config.assets.precompile += %w( default2.css jquery.easytabs.js introjs.css
intro.js canvasjs.min.js jquery.canvas.min.js pnotify.custom.min.css pnotify.custom.min.js
jquery.leanModal.min.js jquery.balloon.min.js jquery-ui.min.js jquery.ui.datepicker-ja.min.js 
jquery-ui.css tracking.js)
