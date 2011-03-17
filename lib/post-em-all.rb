module ActionDispatch
  module Routing
    class RouteSet
      def draw(&block)
        clear! unless @disable_clear_and_finalize

        mapper = Mapper.new(self)
        if block.arity == 1
          mapper.instance_exec(DeprecatedMapper.new(self), &block)
        else
          scoped = Proc.new {
            scope "get" do
              mapper.instance_exec(&block)
            end
          }
          mapper.instance_exec(&scoped)
          mapper.instance_exec(&block)
        end

        finalize! unless @disable_clear_and_finalize

        nil
      end
    end
  end
end


module ActionDispatch
  module Routing
    class Mapper
      module HttpHelpers
        private
          def map_method(method, *args, &block)
            options = args.extract_options!
            options[:via] = method
            if method == :get and @scope[:path] =~ /^\/get/
              options[:via] = :post 
            end
            args.push(options)
            match(*args, &block)
            self
          end
      end
      include HttpHelpers
    end
  end
end


module PostEmAll
  class Post
    def self.when(&block)
      @condition = block
    end
    def self.post?
      @condition
    end
  end
end


module PostEmAll
  module ViewHelpers
    
    def link_to(*args, &block)
      if block_given?
        options      = args.first || {}
        html_options = args.second
        link_to(capture(&block), options, html_options)
      else
        name         = args[0]
        options      = args[1] || {}
        html_options = args[2] || {}
        prevent_post = html_options.delete(:post)===false
        if !prevent_post && post?
          is_get = html_options.empty? || !html_options.keys.include?(:method) || html_options[:method] == :get
          html_options[:method] = :post if is_get
          html_options = convert_options_to_data_attributes(options, html_options)      
          url = url_for(options)
          if is_get && !url.match(/^\w+\:/)
            if url =~ /^https?\:\/\//
              #url
              y url
              host, path = url.match(/^(https?\:\/\/.*?\/)(.*)/).to_a[1..2]
              url = "#{host}get/#{path}"
            else
              # path
              url = "/get#{url}"
            end
          end
        else
          html_options = convert_options_to_data_attributes(options, html_options)      
          url = url_for(options)
        end

        href = html_options['href']
        tag_options = tag_options(html_options)

        href_attr = "href=\"#{html_escape(url)}\"" unless href
        "<a #{href_attr}#{tag_options}>#{html_escape(name || url)}</a>".html_safe
      end
    end
    
    private
    
    def post?
      instance_exec(&PostEmAll::Post.post?)
    end
    
  end  
end


ActiveSupport.on_load(:action_view) do 
  include PostEmAll::ViewHelpers
end