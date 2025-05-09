# frozen_string_literal: true

require 'spec_helper'

module Bullet
  describe Rack do
    let(:middleware) { Bullet::Rack.new app }
    let(:app) { Support::AppDouble.new }

    context '#html_request?' do
      it 'should be true if Content-Type is text/html and http body contains html tag' do
        headers = { 'Content-Type' => 'text/html' }
        response = double(body: '<html><head></head><body></body></html>')
        expect(middleware).to be_html_request(headers, response)
      end

      it 'should be true if Content-Type is text/html and http body contains html tag with attributes' do
        headers = { 'Content-Type' => 'text/html' }
        response = double(body: "<html attr='hello'><head></head><body></body></html>")
        expect(middleware).to be_html_request(headers, response)
      end

      it 'should be false if there is no Content-Type header' do
        headers = {}
        response = double(body: '<html><head></head><body></body></html>')
        expect(middleware).not_to be_html_request(headers, response)
      end

      it 'should be false if Content-Type is javascript' do
        headers = { 'Content-Type' => 'text/javascript' }
        response = double(body: '<html><head></head><body></body></html>')
        expect(middleware).not_to be_html_request(headers, response)
      end
    end

    context '#skip_html_injection?' do
      let(:request) { double('request') }

      it 'should return false if query_string is nil' do
        allow(request).to receive(:env).and_return({ 'QUERY_STRING' => nil })
        expect(middleware.skip_html_injection?(request)).to be_falsey
      end

      it 'should return false if query_string is empty' do
        allow(request).to receive(:env).and_return({ 'QUERY_STRING' => '' })
        expect(middleware.skip_html_injection?(request)).to be_falsey
      end

      it 'should return true if skip_html_injection parameter is true' do
        allow(request).to receive(:env).and_return({ 'QUERY_STRING' => 'skip_html_injection=true' })
        expect(middleware.skip_html_injection?(request)).to be_truthy
      end

      it 'should return false if skip_html_injection parameter is not true' do
        allow(request).to receive(:env).and_return({ 'QUERY_STRING' => 'skip_html_injection=false' })
        expect(middleware.skip_html_injection?(request)).to be_falsey
      end

      it 'should return false if skip_html_injection parameter is not present' do
        allow(request).to receive(:env).and_return({ 'QUERY_STRING' => 'other_param=value' })
        expect(middleware.skip_html_injection?(request)).to be_falsey
      end

      it 'should handle complex query strings' do
        allow(request).to receive(:env).and_return({ 'QUERY_STRING' => 'param1=value1&skip_html_injection=true&param2=value2' })
        expect(middleware.skip_html_injection?(request)).to be_truthy
      end
    end

    context 'empty?' do
      it 'should be false if response is a string and not empty' do
        response = double(body: '<html><head></head><body></body></html>')
        expect(middleware).not_to be_empty(response)
      end

      it 'should be false if response is not found' do
        response = ['Not Found']
        expect(middleware).not_to be_empty(response)
      end

      it 'should be true if response body is empty' do
        response = double(body: '')
        expect(middleware).to be_empty(response)
      end

      it 'should be true if no response body' do
        response = double
        expect(middleware).to be_empty(response)
      end
    end

    context '#call' do
      context 'when Bullet is enabled' do
        it 'should return original response body' do
          expected_response = Support::ResponseDouble.new 'Actual body'
          app.response = expected_response
          _, _, response = middleware.call({})
          expect(response).to eq(expected_response)
        end

        it 'should change response body if notification is active' do
          expect(Bullet).to receive(:notification?).and_return(true)
          expect(Bullet).to receive(:console_enabled?).and_return(true)
          expect(Bullet).to receive(:gather_inline_notifications).and_return('<bullet></bullet>')
          expect(Bullet).to receive(:perform_out_of_channel_notifications)
          _, headers, response = middleware.call('Content-Type' => 'text/html')
          expect(headers['Content-Length']).to eq('56')
          expect(response).to eq(%w[<html><head></head><body><bullet></bullet></body></html>])
        end

        it 'should change response body if always_append_html_body is true' do
          expect(Bullet).to receive(:always_append_html_body).and_return(true)
          expect(Bullet).to receive(:console_enabled?).and_return(true)
          expect(Bullet).to receive(:gather_inline_notifications).and_return('<bullet></bullet>')
          expect(Bullet).to receive(:perform_out_of_channel_notifications)
          _, headers, response = middleware.call('Content-Type' => 'text/html')
          expect(headers['Content-Length']).to eq('56')
          expect(response).to eq(%w[<html><head></head><body><bullet></bullet></body></html>])
        end

        it 'should set the right Content-Length if response body contains accents' do
          response = Support::ResponseDouble.new
          response.body = '<html><head></head><body>é</body></html>'
          app.response = response
          expect(Bullet).to receive(:notification?).and_return(true)
          allow(Bullet).to receive(:console_enabled?).and_return(true)
          expect(Bullet).to receive(:gather_inline_notifications).and_return('<bullet></bullet>')
          _, headers, response = middleware.call('Content-Type' => 'text/html')
          expect(headers['Content-Length']).to eq('58')
        end

        shared_examples 'inject notifiers' do
          before do
            allow(Bullet).to receive(:gather_inline_notifications).and_return('<bullet></bullet>')
            allow(middleware).to receive(:xhr_script).and_return('<script></script>')
            allow(middleware).to receive(:footer_note).and_return('footer')
            expect(Bullet).to receive(:perform_out_of_channel_notifications)
          end

          it 'should change response body if add_footer is true' do
            expect(Bullet).to receive(:add_footer).exactly(3).times.and_return(true)
            _, headers, response = middleware.call('Content-Type' => 'text/html')

            expect(headers['Content-Length']).to eq((73 + middleware.send(:footer_note).length).to_s)
            expect(response).to eq(%w[<html><head></head><body>footer<bullet></bullet><script></script></body></html>])
          end

          it 'should change response body for html safe string if add_footer is true' do
            expect(Bullet).to receive(:add_footer).exactly(3).times.and_return(true)
            app.response =
              Support::ResponseDouble.new.tap do |response|
                response.body = ActiveSupport::SafeBuffer.new('<html><head></head><body></body></html>')
              end
            _, headers, response = middleware.call('Content-Type' => 'text/html')

            expect(headers['Content-Length']).to eq((73 + middleware.send(:footer_note).length).to_s)
            expect(response).to eq(%w[<html><head></head><body>footer<bullet></bullet><script></script></body></html>])
          end

          it 'should add the footer-text header for non-html requests when add_footer is true' do
            allow(Bullet).to receive(:add_footer).at_least(:once).and_return(true)
            allow(Bullet).to receive(:footer_info).and_return(['footer text'])
            app.headers = { 'Content-Type' => 'application/json' }
            _, headers, _response = middleware.call({})
            expect(headers).to include('X-bullet-footer-text' => '["footer text"]')
          end

          it 'should change response body if console_enabled is true' do
            expect(Bullet).to receive(:console_enabled?).and_return(true)
            _, headers, response = middleware.call('Content-Type' => 'text/html')
            expect(headers['Content-Length']).to eq('56')
            expect(response).to eq(%w[<html><head></head><body><bullet></bullet></body></html>])
          end

          it 'should include CSP nonce in inline script if console_enabled and a CSP is applied' do
            allow(Bullet).to receive(:add_footer).at_least(:once).and_return(true)
            expect(Bullet).to receive(:console_enabled?).and_return(true)
            allow(middleware).to receive(:xhr_script).and_call_original

            nonce = '+t9/wTlgG6xbHxXYUaDNzQ=='
            app.headers = {
              'Content-Type' => 'text/html',
              'Content-Security-Policy' => "default-src 'self' https:; script-src 'self' https: 'nonce-#{nonce}'"
            }

            _, headers, response = middleware.call('Content-Type' => 'text/html')

            size = 56 + middleware.send(:footer_note, nonce).length + middleware.send(:xhr_script, nonce).length
            expect(headers['Content-Length']).to eq(size.to_s)
          end

          it 'should include CSP nonce in inline script if console_enabled and a CSP (report only) is applied' do
            allow(Bullet).to receive(:add_footer).at_least(:once).and_return(true)
            expect(Bullet).to receive(:console_enabled?).and_return(true)
            allow(middleware).to receive(:xhr_script).and_call_original

            nonce = '+t9/wTlgG6xbHxXYUaDNzQ=='
            app.headers = {
              'Content-Type' => 'text/html',
              'Content-Security-Policy-Report-Only' =>
                "default-src 'self' https:; script-src 'self' https: 'nonce-#{nonce}'"
            }

            _, headers, response = middleware.call('Content-Type' => 'text/html')

            size = 56 + middleware.send(:footer_note, nonce).length + middleware.send(:xhr_script, nonce).length
            expect(headers['Content-Length']).to eq(size.to_s)
          end

          it 'should include CSP nonce in inline style if console_enabled and a CSP is applied' do
            allow(Bullet).to receive(:add_footer).at_least(:once).and_return(true)
            expect(Bullet).to receive(:console_enabled?).and_return(true)
            allow(middleware).to receive(:xhr_script).and_call_original

            nonce = '+t9/wTlgG6xbHxXYUaDNzQ=='
            app.headers = {
              'Content-Type' => 'text/html',
              'Content-Security-Policy' => "default-src 'self' https:; style-src 'self' https: 'nonce-#{nonce}'"
            }

            _, headers, response = middleware.call('Content-Type' => 'text/html')

            size = 56 + middleware.send(:footer_note, nonce).length + middleware.send(:xhr_script, nonce).length
            expect(headers['Content-Length']).to eq(size.to_s)
          end

          it 'should include CSP nonce in inline style if console_enabled and a CSP (report only) is applied' do
            allow(Bullet).to receive(:add_footer).at_least(:once).and_return(true)
            expect(Bullet).to receive(:console_enabled?).and_return(true)
            allow(middleware).to receive(:xhr_script).and_call_original

            nonce = '+t9/wTlgG6xbHxXYUaDNzQ=='
            app.headers = {
              'Content-Type' => 'text/html',
              'Content-Security-Policy-Report-Only' =>
                "default-src 'self' https:; style-src 'self' https: 'nonce-#{nonce}'"
            }

            _, headers, response = middleware.call('Content-Type' => 'text/html')

            size = 56 + middleware.send(:footer_note, nonce).length + middleware.send(:xhr_script, nonce).length
            expect(headers['Content-Length']).to eq(size.to_s)
          end

          it 'should change response body for html safe string if console_enabled is true' do
            expect(Bullet).to receive(:console_enabled?).and_return(true)
            app.response =
              Support::ResponseDouble.new.tap do |response|
                response.body = ActiveSupport::SafeBuffer.new('<html><head></head><body></body></html>')
              end
            _, headers, response = middleware.call('Content-Type' => 'text/html')
            expect(headers['Content-Length']).to eq('56')
            expect(response).to eq(%w[<html><head></head><body><bullet></bullet></body></html>])
          end

          it 'should add headers for non-html requests when console_enabled is true' do
            allow(Bullet).to receive(:console_enabled?).at_least(:once).and_return(true)
            allow(Bullet).to receive(:text_notifications).and_return(['text notifications'])
            app.headers = { 'Content-Type' => 'application/json' }
            _, headers, _response = middleware.call({})
            expect(headers).to include('X-bullet-console-text' => '["text notifications"]')
          end

          it "shouldn't change response body unnecessarily" do
            expected_response = Support::ResponseDouble.new 'Actual body'
            app.response = expected_response
            _, _, response = middleware.call({})
            expect(response).to eq(expected_response)
          end

          it "shouldn't add headers unnecessarily" do
            app.headers = { 'Content-Type' => 'application/json' }
            _, headers, _response = middleware.call({})
            expect(headers).not_to include('X-bullet-footer-text')
            expect(headers).not_to include('X-bullet-console-text')
          end

          context 'when skip_http_headers is enabled' do
            before do
              allow(Bullet).to receive(:skip_http_headers).and_return(true)
            end

            it 'should include the footer but not the xhr script tag if add_footer is true' do
              expect(Bullet).to receive(:add_footer).at_least(:once).and_return(true)
              _, headers, response = middleware.call({})

              expect(headers['Content-Length']).to eq((56 + middleware.send(:footer_note).length).to_s)
              expect(response).to eq(%w[<html><head></head><body>footer<bullet></bullet></body></html>])
            end

            it 'should not include the xhr script tag if console_enabled is true' do
              expect(Bullet).to receive(:console_enabled?).and_return(true)
              _, headers, response = middleware.call({})
              expect(headers['Content-Length']).to eq('56')
              expect(response).to eq(%w[<html><head></head><body><bullet></bullet></body></html>])
            end

            it 'should not add the footer-text header for non-html requests when add_footer is true' do
              allow(Bullet).to receive(:add_footer).at_least(:once).and_return(true)
              app.headers = { 'Content-Type' => 'application/json' }
              _, headers, _response = middleware.call({})
              expect(headers).not_to include('X-bullet-footer-text')
            end

            it 'should not add headers for non-html requests when console_enabled is true' do
              allow(Bullet).to receive(:console_enabled?).at_least(:once).and_return(true)
              app.headers = { 'Content-Type' => 'application/json' }
              _, headers, _response = middleware.call({})
              expect(headers).not_to include('X-bullet-console-text')
            end
          end
        end

        context 'with notifications present' do
          before do
            expect(Bullet).to receive(:notification?).and_return(true)
          end

          include_examples 'inject notifiers'
        end

        context 'with always_append_html_body true' do
          before do
            expect(Bullet).to receive(:always_append_html_body).and_return(true)
          end

          include_examples 'inject notifiers'
        end

        context 'when skip_html_injection is enabled' do
          it 'should not try to inject html' do
            expected_response = Support::ResponseDouble.new 'Actual body'
            app.response = expected_response
            allow(Bullet).to receive(:notification?).and_return(true)
            allow(Bullet).to receive(:skip_html_injection?).and_return(true)
            expect(Bullet).to receive(:gather_inline_notifications).never
            expect(middleware).to receive(:xhr_script).never
            expect(Bullet).to receive(:perform_out_of_channel_notifications)
            _, _, response = middleware.call('Content-Type' => 'text/html')
            expect(response).to eq(expected_response)
          end
        end
      end

      context 'when Bullet is disabled' do
        before(:each) { allow(Bullet).to receive(:enable?).and_return(false) }

        it 'should not call Bullet.start_request' do
          expect(Bullet).not_to receive(:start_request)
          middleware.call({})
        end
      end
    end

    context '#set_header' do
      it 'should truncate headers to under 8kb' do
        long_header = ['a' * 1_024] * 10
        expected_res = (['a' * 1_024] * 7).to_json
        expect(middleware.set_header({}, 'Dummy-Header', long_header)).to eq(expected_res)
      end
    end

    describe '#response_body' do
      let(:response) { double }
      let(:body_string) { '<html><body>My Body</body></html>' }

      context 'when `response` responds to `body`' do
        before { allow(response).to receive(:body).and_return(body) }

        context 'when `body` returns an Array' do
          let(:body) { [body_string, 'random string'] }
          it 'should return the plain body string' do
            expect(middleware.response_body(response)).to eq body_string
          end
        end

        context 'when `body` does not return an Array' do
          let(:body) { body_string }
          it 'should return the plain body string' do
            expect(middleware.response_body(response)).to eq body_string
          end
        end
      end

      context 'when `response` does not respond to `body`' do
        before { allow(response).to receive(:first).and_return(body_string) }

        it 'should return the plain body string' do
          expect(middleware.response_body(response)).to eq body_string
        end
      end

      begin
        require 'rack/files'

        context 'when `response` is a Rack::Files::Iterator' do
          let(:response) { instance_double(::Rack::Files::Iterator) }
          before { allow(response).to receive(:is_a?).with(::Rack::Files::Iterator) { true } }

          it 'should return nil' do
            expect(middleware.response_body(response)).to be_nil
          end
        end
      rescue LoadError
      end
    end
  end
end
