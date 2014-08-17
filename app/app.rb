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
        r.Say "おはようを録音しましょう", language: "ja-jp", voice: "woman"
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
          r.Say "録音します。終わるときはいずれかのキーを押してください。", language: "ja-jp", voice: "woman"
          r.Record maxLength: '10', action: '/call/handle-record', method: 'get'
          r.Redirect 'menu', method: 'get'
        end
      when '2'
        redirect '/call/play/menu'
      else
        redirect '/call/menu'
      end

      response.text
    end

    get '/call/handle-record' do
      content_type 'text/xml'

      recording_url = params['RecordingUrl']

      record = Records.new
      record.url = recording_url
      record.save

      Twilio::TwiML::Response.new do |r|
        r.Say "録音が終わりました。再生します。", language: "ja-jp", voice: "woman"
        r.Play recording_url
        r.Say "ありがとうございました", language: "ja-jp", voice: "woman"
      end.text
    end

    get '/call/play/menu' do
      content_type 'text/xml'

      Twilio::TwiML::Response.new do |r|
        r.Gather numDigits: '1', action: '/call/play/handle-gather', method: 'get' do |g|
          g.Say "最新の音声を再生するには1を、そのほかの音声を再生するには2を押してください。", language: "ja-jp", voice: "woman"
        end
      end.text
    end

    get '/call/play/handle-gather' do
      content_type 'text/xml'

      case params['Digits']
      when '1'
        response = Twilio::TwiML::Response.new do |r|
          r.Say "最新の音声を再生します。", language: "ja-jp", voice: "woman"
          r.play Records.last.url
          r.Redirect "menu", method: 'get'
        end
      when '2'
        response = Twilio::TwiML::Response.new do |r|
          r.Gather action: '/call/play/choose/handle-gather', method: 'get' do |g|
            g.Say "再生したい番号を押して、最後にシャープを押してください。", language: "ja-jp", voice: "woman"
          end
        end
      else
        response = Twilio::TwiML::Response.new do |r|
          r.Redirect '/call/menu', method: 'get'
        end
      end

      response.text
    end

    get '/call/play/choose/handle-gather' do
      content_type 'text/xml'

      number = params['Digits']

      Twilio::TwiML::Response.new do |r|
        r.Say "#{number}番の音声を再生します。", language: "ja-jp", voice: "woman"
        r.play Records.find_by(number).url
        r.Redirect '../menu', method: 'get'
      end.text
    end
  end
end
