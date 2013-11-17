require 'spec_helper'

describe ApiConnection do
  let(:endpoint) { stub("nestful_endpoint") }

  before(:each) do
    Esendex.configure do |config|
      config.username = random_string
      config.password = random_string
    end
    stub_const("Nestful::Endpoint", endpoint)
    endpoint
      .stub(:new)
      .with(anything, anything)
      .and_return(endpoint)
  end

  describe "#initialise" do

    subject { ApiConnection.new }

    it "should set the api_host" do
      endpoint
        .should_receive(:new)
        .with(Esendex.api_host, anything)
      subject
    end
    it "should set the username" do
      endpoint
        .should_receive(:new)
        .with(anything, hash_including(user: Esendex.username))
      subject
    end
    it "should set the password" do
      endpoint
        .should_receive(:new)
        .with(anything, hash_including(password: Esendex.password))
      subject
    end
    it "should set the auth to basic" do
      endpoint
        .should_receive(:new)
        .with(anything, hash_including(auth_type: :basic))
      subject
    end
    it "should set the user-agent header" do
      endpoint
        .should_receive(:new)
        .with(anything, hash_including(headers: hash_including('User-Agent' => Esendex.user_agent)))
      subject
    end
    it "should set format" do
      endpoint
        .should_receive(:new)
        .with(anything, hash_including(format: an_instance_of(ApplicationXmlFormat)))
      subject
    end
  end

  describe "#get" do
    let(:url) { random_string }

    before(:each) do
      endpoint.stub(:[]).and_return(endpoint)
      endpoint.stub(:get)
    end

    subject { ApiConnection.new.get url }
    
    it "should set url" do
      endpoint.should_receive(:[]).with(url)
      subject
    end

    it "should call get" do
      endpoint.should_receive(:get)
      subject
    end

    context "when 403 raised" do
      before(:each) do
        endpoint.stub(:get) { raise Nestful::ForbiddenAccess.new(nil) }
      end
      it "raises an ForbiddenError" do
        expect { subject }.to raise_error(ForbiddenError)
      end
    end
  end

  describe "#post" do
    let(:url) { random_string }
    let(:body) { random_string }

    before(:each) do
      endpoint.stub(:[]).and_return(endpoint)
      endpoint.stub(:post)
    end

    subject { ApiConnection.new.post url, body }
    
    it "should set url" do
      endpoint.should_receive(:[]).with(url)
      subject
    end

    it "should call post" do
      endpoint.should_receive(:post).with(nil, hash_including(body: body))
      subject
    end

    context "when 403 raised" do
      before(:each) do
        endpoint.stub(:post) { raise Nestful::ForbiddenAccess.new(nil) }
      end
      it "raises an ForbiddenError" do
        expect { subject }.to raise_error(ForbiddenError)
      end
    end
  end
end