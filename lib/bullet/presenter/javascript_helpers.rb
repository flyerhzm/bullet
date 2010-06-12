module Bullet
  module Presenter
    module JavascriptHelpers
      def self.wrap_js_association( message )
        %{ 
          <script type="text/javascript">/*<![CDATA[*/
          #{message}
          /*]]>*/</script>
        }
      end
    end
  end
end
