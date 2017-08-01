
require 'spec_helper'

module Bullet
  describe Rack do
    let(:middleware) { Bullet::Rack.new app }
    let(:app) { Support::AppDouble.new }

    context '#html_request?' do
      it 'should be true if Content-Type is text/html and http body contains html tag' do
        headers = {'Content-Type' => 'text/html'}
        response = double(:body => '<html><head></head><body></body></html>')
        expect(middleware).to be_html_request(headers, response)
      end

      it 'should be true if Content-Type is text/html and http body contains html tag with attributes' do
        headers = {'Content-Type' => 'text/html'}
        response = double(:body => "<html attr='hello'><head></head><body></body></html>")
        expect(middleware).to be_html_request(headers, response)
      end

      it 'should be false if there is no Content-Type header' do
        headers = {}
        response = double(:body => '<html><head></head><body></body></html>')
        expect(middleware).not_to be_html_request(headers, response)
      end

      it 'should be false if Content-Type is javascript' do
        headers = {'Content-Type' => 'text/javascript'}
        response = double(:body => '<html><head></head><body></body></html>')
        expect(middleware).not_to be_html_request(headers, response)
      end

      it "should be false if response body doesn't contain html tag" do
        headers = {'Content-Type' => 'text/html'}
        response = double(:body => '<div>Partial</div>')
        expect(middleware).not_to be_html_request(headers, response)
      end
    end

    context 'empty?' do
      it 'should be false if response is a string and not empty' do
        response = double(:body => '<html><head></head><body></body></html>')
        expect(middleware).not_to be_empty(response)
      end

      it 'should be true if response is not found' do
        response = ['Not Found']
        expect(middleware).to be_empty(response)
      end

      it 'should be true if response body is empty' do
        response = double(:body => '')
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
          expect(Bullet).to receive(:gather_inline_notifications).and_return('<bullet></bullet>')
          expect(Bullet).to receive(:perform_out_of_channel_notifications)
          status, headers, response = middleware.call({'Content-Type' => 'text/html'})
          expect(headers['Content-Length']).to eq('56')
          expect(response).to eq(['<html><head></head><body><bullet></bullet></body></html>'])
        end

        it 'should set the right Content-Length if response body contains accents' do
          response = Support::ResponseDouble.new
          response.body = '<html><head></head><body>é</body></html>'
          app.response = response
          expect(Bullet).to receive(:notification?).and_return(true)
          expect(Bullet).to receive(:gather_inline_notifications).and_return('<bullet></bullet>')
          status, headers, response = middleware.call({'Content-Type' => 'text/html'})
          expect(headers['Content-Length']).to eq('58')
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
    end
  end
end
