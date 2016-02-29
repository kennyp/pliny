require "spec_helper"

describe Pliny::Middleware::Instruments do
  def app
    Rack::Builder.new do
      run Sinatra.new {
        use Pliny::Middleware::Instruments

        error Pliny::Errors::Error do
          Pliny::Errors::Error.render(env["sinatra.error"])
        end

        get "/apps/:id" do
          status 201
          "hi"
        end

        get "/error" do
          raise Pliny::Errors::NotFound
        end
      }
    end
  end

  it "performs logging" do
    mock(Pliny).log(hash_including(
      instrumentation: true,
      at:              "start",
      method:          "GET",
      path:            "/apps/123",
    ))
    mock(Pliny).log(hash_including(
      instrumentation: true,
      at:              "finish",
      method:          "GET",
      path:            "/apps/123",
      route_signature: "/apps/:id",
      status:          201
    ))
    get "/apps/123"
  end

  it "respects Pliny error status codes" do
    mock(Pliny).log.with_any_args
    mock(Pliny).log(hash_including(
      status: 404
    ))
    get "/error"
  end
end
