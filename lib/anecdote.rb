require "raconteur"
require "anecdote/engine"

module Anecdote

  def self.markdown_and_parse(content="")
    Kramdown::Document.new( raconteur.parse(content), { input: :GFM } ).to_html.html_safe
  end

  def self.raconteur
    @raconteur ||= ::Raconteur.new
  end


  # <div class="guie-n765ns-intrinsic-embed">
  #   <div class="inner" style="padding-bottom: 64.92248062%;">
  #     <img src="/baymard-articles/category-specific-sorting-01-rei-mock-up-0f0ae156f355de764324aa6aa4b84d3f.jpg" alt="" />
  #   </div>
  # </div>

  def self.init_raconteur
    raconteur.settings.setting_quotes = '$'
    raconteur.processors.register!('graphic', {
      template: '<div class="{{ klass }}"><div class="inner"><div class="image">{{ image }}</div><div class="caption">{{ caption }}</div></div></div>',
      handler: lambda do |settings|
        klass = (['anecdote-graphic-dn32ja'] + module_classes(settings)).flatten.join(' ')
        image = view_context.content_tag(:div, class: 'anecdote-intrinsic-embed-n42ha1') do
          geo = Paperclip::Geometry.from_file(Rails.root.join('app', 'assets', 'images', settings[:assets_path]))
          view_context.content_tag(:div, view_context.image_tag(settings[:assets_path], alt: ''), class: 'inner', style: "padding-bottom: #{geo.height / geo.width * 100}%;")
        end
        caption = markdown_and_parse(settings[:caption] || "[No caption]")
        { klass: klass, image: image, caption: caption }
      end
      })
    raconteur.processors.register!('pull-quote', {
      handler: lambda do |settings|
        klass = (['anecdote-pull-quote-sba2ha'] + module_classes(settings)).flatten.join(' ')
        view_context.content_tag(:div, view_context.content_tag(:div, markdown_and_parse(settings[:_yield_]), class: 'inner'), class: klass)
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
    klasses
  end



  private

  def self.view_context
    Anecdote::ApplicationController.helpers
  end

end

Anecdote.init_raconteur
