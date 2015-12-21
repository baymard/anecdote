require "raconteur"
require "kramdown"
require "anecdote/engine"

module Anecdote

  def self.markdown_and_parse(content="")
    ::Kramdown::Document.new( raconteur.parse(content), { input: :GFM } ).to_html.html_safe
  end

  def self.raconteur
    @raconteur ||= ::Raconteur.new
  end

  def self.init_raconteur
    raconteur.settings.setting_quotes = '$'
    raconteur.processors.register!('graphic', {
      handler: lambda do |settings|
        klass = (['anecdote-graphic-dn32ja'] + module_classes(settings)).flatten.join(' ')
        contents = []
        contents << view_context.content_tag(:div, class: 'anecdote-intrinsic-embed-n42ha1') do
          geo = Paperclip::Geometry.from_file(Rails.root.join('app', 'assets', 'images', settings[:assets_path]))
          if settings[:_scope_].present? && settings[:_scope_][:processor].tag == 'gallery'
            settings[:_scope_][:settings][:_graphics_] ||= []
            settings[:_scope_][:settings][:_graphics_] << geo
          end
          view_context.content_tag(:div, view_context.image_tag(settings[:assets_path], alt: ''), class: 'inner', style: "padding-bottom: #{geo.height / geo.width * 100}%;")
        end
        if settings[:caption].present?
          contents << view_context.content_tag(:div, view_context.content_tag(:div, markdown_and_parse(settings[:caption]), class: 'inner anecdote-wysicontent-ndj4ab'), class: 'anecdote-caption-ajkd3b')
        end
        view_context.content_tag(:div, view_context.content_tag(:div, contents.join("\n").html_safe, class: 'inner'), class: klass)
      end
      })
    raconteur.processors.register!('gallery', {
      handler: lambda do |settings|
        klass = (['anecdote-gallery-dn2bak'] + module_classes(settings)).flatten.join(' ')
        contents = []
        graphics = settings[:_yield_].html_safe
        index = 0
        total_width = settings[:_graphics_].sum { |geo| geo.width / geo.height }
        graphics.gsub!(/class="[^"]*?anecdote-graphic-dn32ja[\s|"]/mi) do |match|
          width = (settings[:_graphics_][index].width / settings[:_graphics_][index].height) / total_width
          index += 1
          "style=\"-webkit-flex-basis:#{width * 100}%;-moz-flex-basis:#{width * 100}%;flex-basis:#{width * 100}%;\" #{match}".html_safe
        end
        contents << view_context.content_tag(:div, graphics.html_safe, class: 'content')
        if settings[:caption].present?
          contents << view_context.content_tag(:div, view_context.content_tag(:div, markdown_and_parse(settings[:caption]), class: 'inner anecdote-wysicontent-ndj4ab'), class: 'anecdote-caption-ajkd3b')
        end
        view_context.content_tag(:div, view_context.content_tag(:div, contents.join("\n").html_safe, class: 'inner'), class: klass)
      end
      })
    raconteur.processors.register!('pull-quote', {
      handler: lambda do |settings|
        klass = (['anecdote-pull-quote-sba2ha'] + module_classes(settings)).flatten.join(' ')
        view_context.content_tag(:div, view_context.content_tag(:div, markdown_and_parse(settings[:text]), class: 'inner'), class: klass)
      end
      })
  end

  def self.module_classes(settings)
    klasses = %w(anecdote-module-3ba83n)
    if settings[:size].present?
      klasses << case settings[:size]
      when 'small' then 'v-size-small'
      when 'medium' then 'v-size-medium'
      when 'big' then 'v-size-big'
      when 'full-width' then 'v-size-full-width'
      end
    end
    if settings[:float].present?
      klasses << case settings[:float]
      when 'right' then 'v-float-right'
      when 'left' then 'v-float-left'
      end
    end
    if settings[:mood].present?
      klasses << case settings[:mood]
      when 'positive' then 'v-mood-positive'
      when 'negative' then 'v-mood-negative'
      end
    end
    klasses
  end



  private

  def self.view_context
    Anecdote::ApplicationController.helpers
  end

end

Anecdote.init_raconteur
