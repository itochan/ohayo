module Ohayo
  class App < Padrino::Application
    use ActiveRecord::ConnectionAdapters::ConnectionManagement
    register Padrino::Mailer
    register Padrino::Helpers

    enable :sessions

    get '/' do
      "ohayo"
    end

    get '/call/menu' do
      content_type 'text/xml'

      Twilio::TwiML::Response.new do |r|
        r.Say "おはよう", language: "ja-jp", voice: "woman"
        r.Gather numDigits: '1', action: '/call/handle-gather', method: 'get' do |g|
          g.Say "録音するには1を、再生する場合には2を押してください。", language: "ja-jp", voice: "woman"
        end
      end.text
    end

    get '/call/handle-gather' do
      content_type 'text/xml'

      case params['Digits']
      when '1'
        response = Twilio::TwiML::Response.new do |r|
          r.Say "録音します。終わるときはいずれかのキーを押してください。"
          r.Record maxLength: '10', action: '/call/handle-record', method: 'get'
        end
      else
        redirect '/call/menu'
      end

      response.text
    end

    get '/call/handle-record' do
      content_type 'text/xml'

      Twilio::TwiML::Response.new do |r|
        r.Say "録音が終わりました。再生します。"
        r.Play params['RecordingUrl']
        r.Say "ありがとうございました"
      end.text
    end
  end
end
