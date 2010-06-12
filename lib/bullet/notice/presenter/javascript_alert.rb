module Bullet
  module Notice
    module Presenter
      module JavascriptAlert
        def present( notice )
          JavascriptHelpers::wrap_js_association "alert( #{notice.response.inspect} ); "
        end
      end
    end
  end
end
