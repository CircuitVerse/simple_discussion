module SimpleDiscussion
  class Engine < ::Rails::Engine
    engine_name "simple_discussion"

    # Grab the Rails default url options and use them for sending notifications
    config.after_initialize do
      SimpleDiscussion::Engine.routes.default_url_options = ActionMailer::Base.default_url_options
    end

    # javascripts assets precompiled for dropdown and markdown text editor
    @@javascripts = []

    initializer "simple_discussion.assets.precompile" do |app|
      app.config.assets.precompile += [
        "simple_discussion/application.js"
      ]
    end

    def self.add_javascript(script)
      @@javascripts << script
    end

    def self.javascripts
      @@javascripts
    end

    add_javascript "simple_discussion/application.js"
  end
end
