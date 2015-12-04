class PagesController < ApplicationController
  def show
    page = params[:id] || 'article'
    file = File.read Rails.root.join('app', 'views', 'pages', "#{page}.markdown")
    render text: Anecdote.markdown_and_parse(file), layout: 'application'
  end
end
