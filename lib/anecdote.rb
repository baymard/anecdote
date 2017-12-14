require "raconteur"
require "kramdown"
require "nokogiri"
require "anecdote/engine"

module Anecdote

  def self.markdown_and_parse(content="", options={})
    markdown_only( raconteur.parse(content, options[:raconteur_options] || {}), options[:kramdown_options] )
  end

  def self.markdown_only(content="", options={})
    ::Kramdown::Document.new( content.presence, { input: :GFM }.merge(options || {}) ).to_html.html_safe
  end

  def self.raconteur
    @raconteur ||= ::Raconteur.new
  end

  def self.init_raconteur
    raconteur.settings.setting_quotes = '$'

    raconteur.processors.register!('graphic', {
      handler: lambda do |settings|
        klasses = (['anecdote-graphic-dn32ja'] + module_classes(settings))
        klasses << case settings[:border]
        when 'none' then 'v-border-none'
        when 'shadow' then 'v-border-shadow'
        when 'line' then 'v-border-line'
        end
        klasses << 'v-sidebar-caption' if [true, 'true', 'yes', 'left', 'right', 'first', 'last'].include?(settings[:sidebar_caption])
        klasses << 'v-sidebar-caption v-sidebar-caption-left' if ['left', 'first'].include?(settings[:sidebar_caption])
        klasses << 'v-sidebar-caption v-sidebar-caption-right' if ['right', 'last'].include?(settings[:sidebar_caption])

        contents = []
        contents << view_context.content_tag((settings[:href].present? ? :a : :div), (settings[:href].present? ? { href: settings[:href], title: settings[:href_title] } : {}).merge({ class: 'anecdote-intrinsic-embed-n42ha1' })) do
          if settings[:assets_path]
            content = view_context.image_tag(settings[:assets_path], alt: '')
            paperclip_geo = Paperclip::Geometry.from_file(Rails.root.join('app', 'assets', 'images', settings[:assets_path]))
            geo = { width: paperclip_geo.width, height: paperclip_geo.height }
          elsif settings[:image_url]
            content = view_context.image_tag(settings[:image_url], alt: '')
            dimensions = (settings[:dimensions] || settings[:image_dimensions]).split('x').map(&:to_f)
            geo = { width: dimensions.first, height: dimensions.last }
          elsif settings[:embed_code]
            content = settings[:embed_code].html_safe
            dimensions = settings[:dimensions].split('x').map(&:to_f)
            geo = { width: dimensions.first, height: dimensions.last }
          end
          if settings[:_scope_].present? && settings[:_scope_].key?(:processor) && settings[:_scope_][:processor].tag == 'gallery'
            settings[:_scope_][:settings][:_graphics_] ||= []
            settings[:_scope_][:settings][:_graphics_] << geo
          end
          view_context.content_tag(:div, content, class: 'inner', style: "padding-bottom: #{geo[:height] / geo[:width] * 100}%;")
        end
        if settings[:caption].present?
          contents << view_context.content_tag(:div, view_context.content_tag(:div, markdown_and_parse(settings[:caption]), class: 'inner anecdote-wysicontent-ndj4ab'), class: 'anecdote-caption-ajkd3b')
        end
        view_context.content_tag(:div, view_context.content_tag(:div, contents.join("\n").html_safe, class: 'inner'), module_wrapper_options(settings).merge(class: klasses.compact.flatten.join(' ')))
      end
      })

    raconteur.processors.register!('gallery', {
      handler: lambda do |settings|
        klasses = ['anecdote-gallery-dn2bak']
        klasses += module_classes(settings)
        graphics = settings[:_yield_].html_safe

        # handle scaling
        flexes = []
        if settings[:flexes]
          flexes = parse_custom_flexes(settings)
        else
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
              (view_context.content_tag(:div, '', class: 'anecdote-flex-offset-a4j2aj', style: "padding-top: #{flex[:top_offset] * 100}%;").html_safe + match.html_safe).html_safe
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
        end
        graphics = insert_flex_basis_styles(graphics, flexes)

        # build HTML output
        contents = []
        settings[:gutter_spacing] = 'small' if settings[:gutter_spacing].blank?
        contents << view_context.content_tag(:div, graphics.html_safe, class: (['content'] + flex_classes(settings)).flatten.join(' '))
        if settings[:caption].present?
          contents << view_context.content_tag(:div, view_context.content_tag(:div, markdown_and_parse(settings[:caption]), class: 'inner anecdote-wysicontent-ndj4ab'), class: 'anecdote-caption-ajkd3b')
        end
        view_context.content_tag(:div, view_context.content_tag(:div, contents.join("\n").html_safe, class: 'inner'), module_wrapper_options(settings).merge(class: klasses.flatten.join(' ')))
      end
      })

    raconteur.processors.register!('columns', {
      handler: lambda do |settings|
        klasses = ['anecdote-columns-nab3a2']
        klasses += module_classes(settings)
        columns = insert_flex_basis_styles(settings[:_yield_].html_safe, parse_custom_flexes(settings))
        view_context.content_tag(:div, view_context.content_tag(:div, columns.html_safe, class: (['inner'] + flex_classes(settings)).flatten.join(' ')), module_wrapper_options(settings).merge(class: klasses.flatten.join(' ')))
      end
      })

    raconteur.processors.register!('anecdote', {
      handler: lambda do |settings|
        klass = (['anecdote-inception-ab2a8j'] + module_classes(settings)).flatten.join(' ')
        inner_klass = ['anecdote-wysicontent-ndj4ab', 'inner']
        inner_klass << 'v-fit-content-to-fill-container' if settings[:fit_content_to_container].present? && ['true', 'yes', true].include?(settings[:fit_content_to_container])
        view_context.content_tag(:div, view_context.content_tag(:div, markdown_and_parse(settings[:_yield_]), class: inner_klass.join(' ')), module_wrapper_options(settings).merge(class: klass))
      end
      })

    raconteur.processors.register!('pull-quote', {
      handler: lambda do |settings|
        klass = (['anecdote-pull-quote-sba2ha'] + module_classes(settings)).flatten.join(' ')
        view_context.content_tag(:div, view_context.content_tag(:div, markdown_and_parse(settings[:text]), class: 'inner'), module_wrapper_options(settings).merge(class: klass))
      end
      })

    raconteur.processors.register!('horizontal-line', {
      handler: lambda do |settings|
        klasses = ['anecdote-horizontal-line-asj31a']
        klasses += module_classes(settings)
        klasses << case settings[:weight]
        when 'light' then 'v-light'
        when 'notable' then 'v-notable'
        when 'heavy' then 'v-heavy'
        end
        view_context.content_tag(:div, '<hr />'.html_safe, module_wrapper_options(settings).merge(class: klasses.flatten.join(' ')))
      end
      })

    raconteur.processors.register!('spacing', {
      handler: lambda do |settings|
        klasses = ['anecdote-spacing-an4a2q']
        klasses << case settings[:size]
        when 'tiny' then 'v-tiny'
        when 'small' then 'v-small'
        when 'standard' then 'v-standard'
        when 'big' then 'v-big'
        when 'mega' then 'v-mega'
        end
        view_context.content_tag(:div, nil, module_wrapper_options(settings).merge(class: klasses.flatten.join(' ')))
      end
      })

    raconteur.processors.register!('title', {
      handler: lambda do |settings|
        klasses = ['anecdote-title-an4a2q']
        klasses += spacing_classes(settings)
        klasses += text_classes(settings.merge(skip_font_size: true))
        supported_sizes = %w(h1 h2 h3 h4 h5 h6 p)
        # visual hierarchy, i.e. determines CSS / rendering
        if supported_sizes.include?(settings[:size])
          klasses << "v-size-#{settings[:size]}"
        else
          tag = 'v-size-h1'
        end
        # semantic hierarchy, i.e. determines HTML tag (if undefined, fall back on visual hierarchy)
        if settings[:tag].present?
          tag = settings[:tag]
        elsif supported_sizes.include?(settings[:size])
          tag = settings[:size]
        else
          tag = 'h1'
        end
        view_context.content_tag(tag, markdown_and_parse_without_wrapping_tags(settings[:text] || settings[:_yield_]), module_wrapper_options(settings).merge(id: settings[:anchor], class: klasses.flatten.join(' ')))
      end
      })


    raconteur.processors.register!('display-if', {
      handler: lambda do |settings|
        response = ''
        # grab the 'format' provided to Anecdote for this particular call, or the default setting (if neither has been provdided, nothing is rendered)
        if ( settings.key?([:_scope_]) && settings[:_scope_].key?(:format) ) || ( raconteur.settings.key?(:render_options) && raconteur.settings[:render_options].key?(:default_format) )
          current_format = ( settings[:_scope_][:format] || raconteur.settings[:render_options][:default_format] ).to_s
          sanctioned_formats = settings[:formats].split(',').map(&:to_s).select(&:present?)
          # if the current format matches one of the formats "sanctioned" by the tag, render the content (otherwise, nothing is rendered)
          if sanctioned_formats.include?(current_format)
            response = settings[:_yield_]
          end
        end
        response
      end
      })
    raconteur.processors.register!('display-unless', {
      handler: lambda do |settings|
        response = settings[:_yield_]
        # grab the 'format' provided to Anecdote for this particular call, or the default setting (if neither has been provided, the content is rendered)
        if ( settings.key?([:_scope_]) && settings[:_scope_].key?(:format) ) || ( raconteur.settings.key?(:render_options) && raconteur.settings[:render_options].key?(:default_format) )
          current_format = ( settings[:_scope_][:format] || raconteur.settings[:render_options][:default_format] ).to_s
          unsanctioned_formats = settings[:formats].split(',').map(&:to_s).select(&:present?)
          # if the current format matches one of the formats "unsanctioned" by the tag, nothing is rendered (otherwise, the content is rendered)
          if unsanctioned_formats.include?(current_format)
            response = ''
          end
        end
        response
      end
      })

  end


  def self.parse_custom_flexes(settings)
    ratios = settings[:flexes].split(':').map(&:to_i)
    sum = ratios.inject(&:+)
    flexes = ratios.map { |ratio| { width: ratio.to_f / sum } }
  end
  def self.insert_flex_basis_styles(html_content, flexes)
    index = 0
    doc = ::Nokogiri::HTML::DocumentFragment.parse(html_content)
    doc.elements.each do |element|
      if element.attributes['class'].present? && element.attributes['class'].value.split(' ').include?('anecdote-module-3ba83n')
        flex = flexes[index]
        index += 1
        styles = []
        if flex[:width].present?
          styles << "width:#{flex[:width] * 100}%"
          styles << "flex-basis:#{flex[:width] * 100}%"
        end
        element.set_attribute('style', styles.join(';'))
      end
    end
    doc.to_html
  end
  def self.flex_classes(settings)
    klasses = %w(anecdote-flex-module-a4j2aj)
    # custom gutter spacing
    klasses << case settings[:gutter_spacing]
    when 'small' then 'v-gutter-spacing-small'
    when 'medium' then 'v-gutter-spacing-medium'
    when 'large' then 'v-gutter-spacing-large'
    end
    # reverse order
    if settings.key?(:reverse_order_on_flow) && ['true', 'yes', true].include?(settings[:reverse_order_on_flow])
      klasses << 'v-reverse-order-on-flow'
    end
    # when to wrap
    klasses << case settings[:flow_from]
    when 'always' then 'v-flow-from-always'
    when 'medium-handheld' then 'v-flow-from-medium-handheld'
    when 'large-handheld' then 'v-flow-from-large-handheld'
    when 'tablet' then 'v-flow-from-tablet'
    when 'laptop' then 'v-flow-from-laptop'
    when 'large-monitor' then 'v-flow-from-large-monitor'
    else
      if settings[:size].present?
        case settings[:size]
        when 'small' then 'v-flow-from-medium-handheld'
        when 'medium' then 'v-flow-from-large-handheld'
        when 'big' then 'v-flow-from-tablet'
        when 'full-width' then 'v-flow-from-tablet'
        end
      else
        'v-flow-from-tablet' # default
      end
    end
    klasses
  end

  def self.spacing_classes(settings)
    klasses = []
    css_base = 'anecdote-adhoc-spacing-an4a2q'
    css = {
      none: 'an4a2q-v-none',
      tiny: 'an4a2q-v-tiny',
      small: 'an4a2q-v-small',
      standard: 'an4a2q-v-standard',
      big: 'an4a2q-v-big',
      mega: 'an4a2q-v-mega'
    }
    supported_sizes = css.keys.map(&:to_s)
    # both top and bottom
    if settings[:spacing].present? && supported_sizes.include?(settings[:spacing])
      klasses << css_base
      klasses << ["#{css[settings[:spacing].to_sym]}-top", "#{css[settings[:spacing].to_sym]}-bottom"]
    end
    # top only
    if settings[:spacing_before].present? && supported_sizes.include?(settings[:spacing_before])
      klasses << css_base
      klasses << "#{css[settings[:spacing_before].to_sym]}-top"
    end
    # bottom only
    if settings[:spacing_after].present? && supported_sizes.include?(settings[:spacing_after])
      klasses << css_base
      klasses << "#{css[settings[:spacing_after].to_sym]}-bottom"
    end
    # flatten (in case of generic setting, which produces a nested array)
    # uniq (in case of individual top and bottom settings)
    klasses.flatten.compact.uniq
  end

  def self.text_classes(settings)
    klasses = []
    klasses << case settings[:font_family]
    when 'primary' then 'anecdote-primary-font-a3a8fb'
    when 'secondary' then 'anecdote-secondary-font-a3a8fb'
    end
    klasses << case settings[:text_dimming]
    when 'none' then 'anecdote-no-text-dimming-lk8j2n'
    when 'mild' then 'anecdote-mild-text-dimming-lk8j2n'
    when 'medium' then 'anecdote-medium-text-dimming-lk8j2n'
    when 'aggressive' then 'anecdote-aggressive-text-dimming-lk8j2n'
    end
    unless settings[:skip_font_size]
      klasses << case settings[:font_size]
      when 'tiny' then 'anecdote-tiny-text-size-an43ja'
      when 'small' then 'anecdote-small-text-size-an43ja'
      when 'normal' then 'anecdote-normal-text-size-an43ja'
      when 'large' then 'anecdote-large-text-size-an43ja'
      end
    end
    klasses << case settings[:text_align]
    when 'left' then 'anecdote-left-aligned-text-vnd5b3'
    when 'right' then 'anecdote-right-aligned-text-vnd5b3'
    when 'center' then 'anecdote-center-aligned-text-vnd5b3'
    end
    klasses.flatten.compact.uniq
  end

  def self.module_wrapper_options(settings)
    options = {}
    options['data-anecdote-embeddable-image-url'] = settings[:embeddable_image_url] if settings[:embeddable_image_url].present?
    options
  end

  def self.module_classes(settings)
    klasses = %w(anecdote-module-3ba83n)
    klasses += settings[:css_class].split(' ') if settings[:css_class].present?
    klasses += spacing_classes(settings)
    klasses += text_classes(settings)
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
      klasses << case settings[:float_from]
      when 'always' then 'v-float-from-always'
      when 'medium-handheld' then 'v-float-from-medium-handheld'
      when 'large-handheld' then 'v-float-from-large-handheld'
      when 'tablet' then 'v-float-from-tablet'
      when 'laptop' then 'v-float-from-laptop'
      when 'large-monitor' then 'v-float-from-large-monitor'
      else
        if settings[:size].present?
          case settings[:size]
          when 'small' then 'v-float-from-large-handheld'
          when 'medium' then 'v-float-from-laptop'
          when 'big' then 'v-flow-from-large-monitor'
          end
        else
          'v-float-from-laptop' # default
        end
      end
    end
    if settings[:mood].present?
      klasses << case settings[:mood]
      when 'positive' then 'v-mood-positive'
      when 'negative' then 'v-mood-negative'
      end
    end
    klasses.flatten.compact.uniq
  end

  def self.markdown_and_parse_without_wrapping_tags(text="")
    markdown_and_parse(text).gsub(/^\<\/?\w+>|\<\/?\w+>$/i, '').gsub(/^\s*|\s*$/mi, '').html_safe
  end



  private

  def self.view_context
    Anecdote::ApplicationController.helpers
  end

end

Anecdote.init_raconteur
Anecdote.raconteur.settings[:render_options] = { default_format: :web }
