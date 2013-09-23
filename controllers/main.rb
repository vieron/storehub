require 'padrino-helpers'
require 'kaminari/sinatra'

require "net/http"
require 'tempfile'
require 'uri'
require 'json'
require "base64"
require './controllers/dropbox'
require './controllers/flickr'

URL_CAPTURE_ENDPOINT = 'http://url-capture.herokuapp.com/url2png'
DROPBOX_CAPTURES_FOLDER = 'web-captures/'



configure do
  enable :sessions
  enable :logging

  # see https://github.com/sinatra/sinatra/issues/518
  set :protection, :except => [:http_origin, :accept, :origin, :'content-type', :json_csrf, :remote_token, :auth_token, :'auth-token']
  use Rack::Protection, reaction: :drop_session
  # disable :protection

  # enable :cross_origin

  # set :allow_origin, :any
  # set :allow_methods, [:get, :post, :options]
  # set :allow_credentials, true
end

helpers Kaminari::Helpers::SinatraHelpers



before do

  if request.request_method == 'OPTIONS' or request.request_method == 'POST'
    response.headers['Access-Control-Allow-Origin'] = "*"
  end

  if request.request_method == 'OPTIONS'
    response.headers['Access-Control-Allow-Methods'] = %w{GET POST OPTIONS}.join(',')
    response.headers['Access-Control-Allow-Headers'] = "accept, origin, auth-token, content-type"
    response.headers['Access-Control-Allow-Credentials'] = "true"
    halt 200
  end

  @droppy_box = DroppyBox.new
  start_auth_flow unless @droppy_box.client? or request.path.match(%r{/auth})

  logger.datetime_format = "%Y/%m/%d @ %H:%M:%S "
  logger.level = Logger::INFO
end

def start_auth_flow
  @droppy_box.session.clear_access_token
  request_token = @droppy_box.session.get_request_token
  session[:request_token] = request_token
  redirect @droppy_box.session.get_authorize_url(url('/auth'))
end


def start_flickr_auth_flow
  token = flickr.get_request_token
  auth_url = flickr.get_authorize_url(token['oauth_token'], :perms => 'delete')

  puts "Open this url in your process to complete the authication process : #{auth_url}"
  puts "Copy here the number given when you complete the process."
  verify = STDIN.gets
  verify = verify.strip

  begin
    flickr.get_access_token(token['oauth_token'], token['oauth_token_secret'], verify)
    login = flickr.test.login
    puts "You are now authenticated as #{login.username}. Copy this to your .env file FLICKR_ACCESS_TOKEN=#{flickr.access_token} and FLICKR_ACCESS_SECRET=#{flickr.access_secret}"
  rescue FlickRaw::FailedResponse => e
    puts "Authentication failed : #{e.msg}"
  end
end

def get_b64_capture(url)
  # get website capture through url2png API
  url2png_uri = URI.parse(URL_CAPTURE_ENDPOINT)
  url2png_uri.query = ::URI.encode_www_form({
    :url => url,
    :type => "json"
  })
  response = Net::HTTP.get(url2png_uri)
  halt 500, 'error' unless response

  JSON.parse(response)["image"]
end

def img_to_io(image, url = 'temp')
    io = StringIO.new(Base64.decode64(image))
    io
end


before '/*.json' do
  content_type 'application/json'
end



# dropbox auth
get '/auth' do
  if request_token = session[:request_token]
    @droppy_box.session.set_request_token(request_token.key, request_token.secret)
    token = @droppy_box.session.get_access_token
    erb "Here is your DROPBOX_TOKEN=#{token.key}:#{token.secret}"
  else
    erb "Sorry, must have expired"
  end
end


options '/2dropbox.json' do
    ''
end



get '/2dropbox.json' do
  response.headers['Access-Control-Allow-Origin'] = "*"
  response.headers['Access-Control-Allow-Methods'] = %w{GET POST OPTIONS}.join(',')
  response.headers['Access-Control-Allow-Headers'] = "auth-token"
  response.headers['Access-Control-Allow-Credentials'] = "true"

  # halt 403, 'Access Forbidden' unless request.env["auth-token"] and ENV["SEND_TO_DROPBOX_TOKEN"] and ENV["SEND_TO_DROPBOX_TOKEN"] == request.env["auth-token"]

  @url = params[:url]

  # Upload image to dropbox
  image64 = get_b64_capture @url
  target_filename = DROPBOX_CAPTURES_FOLDER + URI.parse(URI.encode(@url.strip)).host + '.png'

  begin
    file = @droppy_box.client.put_file(target_filename, Base64.decode64(image64), false)
  rescue DropboxAuthError
    start_auth_flow
  end

  # return file metadata
  if file
    begin
      file = file.merge @droppy_box.client.media(file["path"])
    rescue DropboxAuthError
      start_auth_flow
    end
  end

  file.to_json if file
end



get '/2flickr.json' do
  response.headers['Access-Control-Allow-Origin'] = "*"
  response.headers['Access-Control-Allow-Methods'] = %w{GET POST OPTIONS}.join(',')
  response.headers['Access-Control-Allow-Headers'] = "auth-token"
  response.headers['Access-Control-Allow-Credentials'] = "true"

  if !ENV['FLICKR_ACCESS_TOKEN'] and !ENV['FLICKR_ACCESS_SECRET']
    start_flickr_auth_flow
    return
  end

  @url = params[:url]
  halt 500, 'Url param required' unless @url

  flickr.access_token = ENV['FLICKR_ACCESS_TOKEN']
  flickr.access_secret = ENV['FLICKR_ACCESS_SECRET']
  login = flickr.test.login

  image = get_b64_capture @url
  halt 500, 'Not image returned' unless image

  begin
    photo_id = flickr.upload_photo img_to_io(image), :title => @url, :tags => 'webcapture', :is_public => 1, :content_type => 2
  rescue FlickRaw::FailedResponse => e
    puts "Error uploading image: #{e.msg}"
  end

  info = flickr.photos.getInfo(:photo_id => photo_id)
  if info
    {
      :url => FlickRaw.url_o(info)
    }.to_json
  end
end



get 'proxy.html' do
  render :proxy
end



get '/' do
  if !ENV['FLICKR_ACCESS_TOKEN'] and !ENV['FLICKR_ACCESS_SECRET']
    start_flickr_auth_flow
    return
  end

  per_page = 15
  page = params[:page] or 1

  flickr.access_token = ENV['FLICKR_ACCESS_TOKEN']
  flickr.access_secret = ENV['FLICKR_ACCESS_SECRET']
  login = flickr.test.login

  begin
    user = flickr.people.findByUsername :username => 'vieron'

    imgs = flickr.people.getPublicPhotos :user_id => user["nsid"], :extras => 'description,url_t,url_z,url_o,date_upload', :per_page => per_page, :page => page
    total = imgs.total
    imgs = imgs.to_a

  rescue FlickRaw::FailedResponse => e
    puts "Error accessing images: #{e.msg}"
  end


  @imgs = Kaminari.paginate_array(imgs, total_count: total).page(page).per(per_page)

  erb :gallery
end




