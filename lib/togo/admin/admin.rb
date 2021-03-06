require 'togo/admin/helpers'

module Togo
  class Admin < Dispatch

    include Helpers

    before do
      if not logged_in? and request.path != @path_prefix + '/login'
        redirect "/login"
      else
        @model = Togo.const_get(params[:model]) if params[:model]
      end
    end

    get '/' do
      redirect "/#{Togo.models.first}"
    end

    get '/login' do
      erb :login, :layout => false
    end

    post '/login' do
      session[:user] = config[:auth_model].authenticate(params[:username], params[:password])
      flash[:error] = "Invalid Username or Password" if not logged_in?
      redirect '/'
    end

    get '/logout' do
      session[:user] = nil
      redirect '/'
    end

    get '/:model' do
      @q = params[:q] || ''
      @p = (params[:p] || 1).to_i
      @limit = 50
      @offset = @limit*(@p-1)
      @order = (params[:o] || "id.desc").split('.').map(&:to_sym)
      @count = (@q.blank? ? @model.all : @model.search(:q => @q)).size
      @page_count = @count == 0 ? 1 : (@count.to_f/@limit.to_f).ceil
      @criteria = {:limit => @limit, :offset => @offset, :order => @order[0].send(@order[1])}
      @content = @q.blank? ? @model.all(@criteria) : @model.search(@criteria.merge(:q => @q))
      erb :index
    end

    get '/new/:model' do
      @content = @model.new
      erb :new
    end

    post '/create/:model' do
      @content = @model.stage_content(@model.new,params)
      begin
        raise "Could not save content" if not @content.save
        redirect params[:return_url] || "/#{@model.name}"
      rescue => detail
        @errors = detail.to_s
        erb :new
      end
    end

    get '/edit/:model/:id' do
      @content = @model.first(:id => params[:id].to_i)
      erb :edit
    end

    post '/update/:model/:id' do
      @content = @model.stage_content(@model.first(:id => params[:id].to_i),params)
      begin
        raise "Could not save content" if not @content.save
        redirect params[:return_url] || "/#{@model.name}"
      rescue => detail
        @errors = detail.to_s
        erb :edit
      end
    end

    post '/delete/:model' do
      @items = @model.all(:id => params[:id].split(','))
      begin
        @items.each do |i|
          @model.delete_content(i)
        end
        redirect params[:return_url] || "/#{@model.name}"
      rescue => detail
        @errors = detail.to_s
        @content = params[:q] ? @model.search(:q => params[:q]) : @model.all
        erb :index
      end
    end

    get '/search/:model' do
      @limit = params[:limit] || 10
      @offset = params[:offset] || 0
      @q = params[:q] || ''
      @count = (@q.blank? ? @model.all : @model.search(:q => @q)).size
      @criteria = {:offset => @offset, :limit => @limit}
      if params[:ids]
        @items = @model.all(@criteria.merge(:id => params[:ids].split(',').map(&:to_i)))
      else
        @items = @model.search(@criteria.merge(:q => @q))
      end
      {:count => @count, :results => @items}.to_json
    end

  end

  # Subclass Rack Reloader to call DataMapper.auto_upgrade! on file reload
  class TogoReloader < Rack::Reloader
    def safe_load(*args)
      super(*args)
      ::DataMapper.auto_upgrade!
    end
  end

end
