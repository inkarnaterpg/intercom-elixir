defmodule Intercom.API.RequestTest do
  use ExUnit.Case
  import Mox

  @module Intercom.API.Request
  @http_adapter Application.compile_env(:intercom, :http_adapter)
  @url "https://example.com/users"
  @headers [Authorization: "Bearer abcde"]
  @json_body "{\"user_id\":25}"
  @body %{"user_id" => 25}

  setup :verify_on_exit!

  describe "make_request/4" do
    test "with :get method and nil body makes call to HTTPoison get" do
      expect(@http_adapter, :get, fn @url, @headers ->
        {:ok, %HTTPoison.Response{status_code: 200, body: @json_body}}
      end)

      {:ok, _response, _body} = @module.make_request(:get, @url, @headers, nil)
    end

    test "with :post method makes call to HTTPoison post and 200 status code" do
      expect(@http_adapter, :post, fn @url, @json_body, @headers, [] ->
        {:ok, %HTTPoison.Response{status_code: 200, body: @json_body}}
      end)

      {:ok, _response, _body} = @module.make_request(:post, @url, @headers, @body)
    end

    test "with :post method makes call to HTTPoison post and 202 status code" do
      expect(@http_adapter, :post, fn @url, @json_body, @headers, [] ->
        {:ok, %HTTPoison.Response{status_code: 202, body: ""}}
      end)

      {:ok, _response, _body} = @module.make_request(:post, @url, @headers, @body)
    end

    test "returns map of parsed JSON body when JSON returned with 200 response" do
      expect(@http_adapter, :get, fn @url, @headers ->
        {:ok, %HTTPoison.Response{status_code: 200, body: @json_body}}
      end)

      {:ok, _response, body} = @module.make_request(:get, @url, @headers, nil)

      assert body == @body
    end

    test "returns error with response data if status_code is not 200" do
      expect(@http_adapter, :get, fn @url, @headers ->
        {:ok, %HTTPoison.Response{status_code: 418, body: @json_body}}
      end)

      assert {:error, %HTTPoison.Response{status_code: 418, body: @json_body}, %{"user_id" => 25}} ==
               @module.make_request(:get, @url, @headers, nil)
    end

    test "returns error with response data if body isn't valid JSON" do
      expect(@http_adapter, :get, fn @url, @headers ->
        {:ok, %HTTPoison.Response{status_code: 200, body: "potato"}}
      end)

      assert {:error, %HTTPoison.Response{status_code: 200, body: "potato"}} ==
               @module.make_request(:get, @url, @headers, nil)
    end

    test "passes errors through from HTTPoison" do
      expect(@http_adapter, :get, fn @url, @headers ->
        {:error, %HTTPoison.Error{id: nil, reason: :econnrefused}}
      end)

      assert {:error, %HTTPoison.Error{id: nil, reason: :econnrefused}} ==
               @module.make_request(:get, @url, @headers, nil)
    end

    test "encodes body as JSON in post request" do
      expect(@http_adapter, :post, fn @url, @json_body, @headers, [] ->
        {:ok, %HTTPoison.Response{status_code: 200, body: @json_body}}
      end)

      {:ok, _response, body} = @module.make_request(:post, @url, @headers, @body)

      assert body == @body
    end
  end
end
