module Anecdote
  class Engine < ::Rails::Engine
    isolate_namespace Anecdote

    config.to_prepare do
      Rails.application.config.assets.precompile += %w(anecdote/application.css)
    end
  end
end
