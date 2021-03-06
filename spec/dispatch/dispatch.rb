require File.dirname(__FILE__) + '/helper'

describe "Togo Dispatch" do

  before(:each) do
    @browser = setup_browser
  end

  it "should respond ok on request" do
    @browser.get '/'
    @browser.last_response.status.should == 200
    @browser.last_response.body.should =~ /<h1>Index<\/h1>/
  end

  it "should render layout with erb" do
    @browser.get '/'
    @browser.last_response.body.should =~ /<title>Togo<\/title>/
  end

  it "should render no layout when requested" do
    @browser.get '/no-layout'
    @browser.last_response.body.should_not =~ /<title>Togo<\/title>/
  end

  it "should return last value on method" do
    @browser.get '/returns-last'
    @browser.last_response.status.should == 200
    @browser.last_response.body.should == 'return value'
  end

  it "should set var in params" do
    @browser.get "/variable-test/foo"
    @browser.last_response.body.should == 'foo'
  end

  it "should redirect" do
    @browser.get('/redirect-test')
    @browser.last_response.status.should == 301
    @browser.last_response.headers['Location'].should == '/'
  end
      
  it "should return not found" do
    @browser.get('/not-found')
    @browser.last_response.status.should == 404
    @browser.last_response.body.should == '404 Not Found'
  end

  it "should rescue and display exceptions" do
    @browser.get('/exception-test')
    @browser.last_response.status.should == 500
    @browser.last_response.body.should =~ /Error: Exception Test/
  end

  it "should have routes" do
    DispatchTest.routes.should be_a(Hash)
  end

  it "should run before method" do
    @browser.get('/before-test')
    @browser.last_response.status.should == 200
    @browser.last_response.body.should == "true"
  end

  it "should accept routes in config" do
    config = {:routes => [
                          {:type => 'get', :path => '/configured-route', :template => 'configured_route'}
                         ]}
    @configured_browser = Rack::Test::Session.new(Rack::MockSession.new(DispatchTest.run!(config)))
    @configured_browser.get('/configured-route')
    @configured_browser.last_response.status.should == 200
    @configured_browser.last_response.body.should =~ /<h1>Configured Route<\/h1>/
  end

  it "should accept routes and not add if already defined in class" do
    config = {:routes => [
                          {:type => 'get', :path => '/', :template => 'configured_route'}
                         ]}
    @configured_browser = Rack::Test::Session.new(Rack::MockSession.new(DispatchTest.run!(config)))
    @configured_browser.get('/')
    @configured_browser.last_response.status.should == 200
    @configured_browser.last_response.body.should =~ /<h1>Index<\/h1>/ # instead of configured route
  end

  it "should work with path_prefix" do
    config = {:path_prefix => '/admin'}
    @configured_browser = Rack::Test::Session.new(Rack::MockSession.new(DispatchTest.run!(config)))
    @configured_browser.get('/admin')
    @configured_browser.last_response.status.should == 200
    @configured_browser.last_response.body.should =~ /<h1>Index<\/h1>/
  end

end
