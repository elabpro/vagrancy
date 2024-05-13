require 'sinatra/base'

require 'vagrancy/filestore'
require 'vagrancy/filestore_configuration'
require 'vagrancy/upload_path_handler'
require 'vagrancy/box'
require 'vagrancy/provider_box'
require 'vagrancy/dummy_artifact'
require 'vagrancy/invalid_file_path'

module Vagrancy
  class App < Sinatra::Base
    set :logging, true
    set :show_exceptions, :after_handler

    error Vagrancy::InvalidFilePath do
      status 403
      env['sinatra.error'].message
    end


    get '/:username/:name' do
      box = Vagrancy::Box.new(params[:name], params[:username], filestore, request)

      status box.exists? ? 200 : 404
      content_type 'application/json'
      box.to_json if box.exists?
    end

    get '/api/v2/vagrant/:username/:name' do
      box = Vagrancy::Box.new(params[:name], params[:username], filestore, request)
      status box.exists? ? 200 : 404
      content_type 'application/json'
      box.to_json if box.exists?
    end

    put '/:username/:name/:version/:provider' do
      box = Vagrancy::Box.new(params[:name], params[:username], filestore, request)
      provider_box = ProviderBox.new(params[:provider], params[:version], box, filestore, request)

      provider_box.write(request.body)
      status 201
    end

    get '/:username/:name/:version/:provider' do
      box = Vagrancy::Box.new(params[:name], params[:username], filestore, request)
      provider_box = ProviderBox.new(params[:provider], params[:version], box, filestore, request)

      send_file filestore.file_path(provider_box.file_path) if provider_box.exists?
      status provider_box.exists? ? 200 : 404
    end

    delete '/:username/:name/:version/:provider' do
      box = Vagrancy::Box.new(params[:name], params[:username], filestore, request)
      provider_box = ProviderBox.new(params[:provider], params[:version], box, filestore, request)

      status provider_box.exists? ? 200 : 404
      provider_box.delete
    end

    # Atlas emulation, no authentication
    get '/api/v1/authenticate' do
      status 200
    end

    post '/api/v1/artifacts/:username/:name/vagrant.box' do
      content_type 'application/json'
      UploadPathHandler.new(params[:name], params[:username], request, filestore).to_json
    end

    get '/api/v1/artifacts/:username/:name' do
      status 200
      content_type 'application/json'
      DummyArtifact.new(params).to_json
    end

    get '/api/v1/user/:u?' do
      status 200
      content_type 'application/json'
      {
        username: params[:u],
        avatar_url: "",
        profile_html: "<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.</p>\n",
        profile_markdown: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
        boxes: []
      }.to_json
    end

    get '/api/v1/user' do
      status 200
    end

    get '/api/v1/search' do
      # Get list of boxes - read folder and get all folders in it, save it in array
      q = params['q']
      status 200
      content_type 'application/json'
      dir_path = FilestoreConfiguration.new.path
      boxes = Array.new
      box_list = Dir.glob("#{dir_path}/*")
      for box in box_list
        user = File.basename(box)
        boxsub = Dir.glob("#{dir_path}/"+user+"/*")
        for b in boxsub
          name = File.basename(b)
          boxes.push(
            {
              tag: user+"/"+name,
              name: name,
              short_description: "No description",
              username: user,
              current_version: {
                version: "1.0.0",
                status: "active",
                providers: [{
                  download_url: "https://vagrant.elab.pro/" + user + "/" + name + "/1.0.0/virtualbox"
                }]
              }
            }
          )
        end
      end
      { boxes: boxes}.to_json
    end

    get '/api/v2/search' do
      # Get list of boxes - read folder and get all folders in it, save it in array
      q = params['q']
      status 200
      content_type 'application/json'
      dir_path = FilestoreConfiguration.new.path
      boxes = Array.new
      box_list = Dir.glob("#{dir_path}/*")
      for box in box_list
        user = File.basename(box)
        boxsub = Dir.glob("#{dir_path}/"+user+"/*")
        for b in boxsub
          name = File.basename(b)
          boxes.push(
            {
              tag: user+"/"+name,
              name: name,
              short_description: "No description",
              username: user,
              current_version: {
                version: "1.0.0",
                status: "active",
                providers: [{
                  download_url: "https://vagrant.elab.pro/" + user + "/" + name + "/1.0.0/virtualbox"
                }]
              }
            }
          )
        end
      end
      { boxes: boxes}.to_json
    end

    def filestore 
      path = FilestoreConfiguration.new.path
      Filestore.new(path)
    end

  end
end
