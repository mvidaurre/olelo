require 'hpricot'
depends_on 'engine/filter'
depends_on 'filter/tag'

class Toc < Filter
  def filter(content)
    return content if !context['__TOC__']
    @toc = []
    @level = 0
    @doc = Hpricot(content)
    @count = [0]

    elem = (@doc/'h1,h2,h3,h4,h5,h6').first
    @offset = elem ? elem.name[1..1].to_i - 1 : 0

    walk(@doc)
    while @level > 0
      @toc << indent + '</ul>'
      @level -= 1
    end

    "<p class=\"toc\">\n#{@toc.join("\n")}\n</p>" + @doc.to_html
  end

  private

  def walk(elem)
    elem.each_child do |child|
      next if !child.elem?
      if child.name =~ /^h(\d)$/
        nr = $1.to_i - @offset
        while nr > @level
          @toc << indent + '<ul>'
          @count[@level] = 0
          @level += 1
        end
        while nr < @level
          @level -= 1
          @toc << indent + '</ul>'
        end
        @count[@level-1] += 1
        headline = child.children.first ? child.children.first.inner_text : ''
        section = @count[0..@level-1].join('_') + '_' + headline.strip.gsub(/[^\w]/, '_')
        @toc << indent + "<li class=\"toc#{@level-@offset+1}\"><a href=\"##{section}\">" +
          "<span class=\"counter\">#{@count[@level-1]}</span> #{headline}</a></li>"
        child.inner_html = "<span class=\"counter\" id=\"#{section}\">#{@count[0..@level-1].join('.')}</span> " + child.inner_html
      else
        walk(child)
      end
    end
  end

  def indent
    ('  ' * @level)
  end
end

Tag.define(:toc, :immediate => true) do |context, attrs, content|
  context['__TOC__'] = true
end

Filter.register Toc.new(:toc)
