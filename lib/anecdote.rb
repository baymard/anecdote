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

  def self.inline_js
    view_context.content_tag(:script, Rails.application.assets.find_asset('anecdote/application.js').to_s.html_safe)
  end

  def self.init_raconteur
    raconteur.settings.setting_quotes = '$'

    raconteur.processors.register!('graphic', {
      handler: lambda do |settings|
        klass = (['anecdote-graphic-dn32ja'] + module_classes(settings)).flatten.join(' ')
        contents = []
        contents << view_context.content_tag(:div, class: 'anecdote-intrinsic-embed-n42ha1') do
          if settings[:assets_path]
            image_url = settings[:assets_path]
            paperclip_geo = Paperclip::Geometry.from_file(Rails.root.join('app', 'assets', 'images', settings[:assets_path]))
            geo = { width: paperclip_geo.width, height: paperclip_geo.height }
          elsif settings[:image_url]
            image_url = settings[:image_url]
            dimensions = settings[:image_dimensions].split('x').map(&:to_f)
            geo = { width: dimensions.first, height: dimensions.last }
          end
          if settings[:_scope_].present? && settings[:_scope_][:processor].tag == 'gallery'
            settings[:_scope_][:settings][:_graphics_] ||= []
            settings[:_scope_][:settings][:_graphics_] << geo
          end
          view_context.content_tag(:div, view_context.image_tag(image_url, alt: ''), class: 'inner', style: "padding-bottom: #{geo[:height] / geo[:width] * 100}%;")
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
        graphics = settings[:_yield_].html_safe

        # handle scaling
        flexes = []
        if settings[:scale_by] == 'relative-width-bottom-alignment'
          # images scaled based on their relative width with bottom alignment
          total_width = settings[:_graphics_].sum { |hsh| hsh[:width]}
          settings[:_graphics_].each do |graphic|
            flex = {
              width: graphic[:width] / total_width,
              graphic: graphic,
              ratio: graphic[:width] / graphic[:height],
              gfx_height_pad: graphic[:height] / graphic[:width]
            }
            flex[:width_ratio_balance] = flex[:width] / flex[:ratio]
            flexes << flex
          end
          tallest = flexes.sort_by { |k| k[:width_ratio_balance] }.last
          flexes.map do |flex|
            flex[:faux] = flex[:width_ratio_balance] / tallest[:width_ratio_balance]
            flex[:gfx_height_pad_faux] = flex[:gfx_height_pad] / flex[:faux]
            flex[:top_offset] = flex[:gfx_height_pad_faux] - flex[:gfx_height_pad]
          end
          index = 0
          graphics.gsub!('<div class="anecdote-intrinsic-embed-n42ha1">') do |match|
            flex = flexes[index]
            index += 1
            (view_context.content_tag(:div, '', class: 'anecdote-gallery-offset-dn2bak', style: "padding-top: #{flex[:top_offset] * 100}%;").html_safe + match.html_safe).html_safe
          end
          # graphics.gsub!(/anecdote-intrinsic-embed-n42ha1.*?padding-bottom:\s*([\d|\.]*)/mi) do |match|
          #   flex = flexes[index]
          #   index += 1
          #   match.sub(/[\d|\.]*$/, (flex[:gfx_height_pad_faux] * 100).to_s).html_safe
          # end
        elsif settings[:scale_by] == 'relative-width'
          # images scaled based on their relative width
          total_width = settings[:_graphics_].sum { |hsh| hsh[:width]}
          settings[:_graphics_].each do |graphic|
            flexes << { width: graphic[:width] / total_width, graphic: graphic }
          end
        else
          # images scaled to equal height
          total_ratio = settings[:_graphics_].sum { |geo| geo[:width] / geo[:height] }
          settings[:_graphics_].each do |graphic|
            flexes << { width: (graphic[:width] / graphic[:height]) / total_ratio, graphic: graphic }
          end
        end
        index = 0
        graphics.gsub!(/class="[^"]*?anecdote-graphic-dn32ja[\s|"]/mi) do |match|
          flex = flexes[index]
          index += 1
          styles = []
          if flex[:width].present?
            styles << "-webkit-flex-basis:#{flex[:width] * 100}%"
            styles << "-moz-flex-basis:#{flex[:width] * 100}%"
            styles << "flex-basis:#{flex[:width] * 100}%"
          end
          "style=\"#{styles.join(';')}\" #{match}".html_safe
        end

        # build HTML output
        contents = []
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
