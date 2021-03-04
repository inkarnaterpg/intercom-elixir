defmodule Intercom.APITest do
  use ExUnit.Case, async: false
  import Mox

  doctest Intercom

  setup do
    access_token = Application.get_env(:intercom, :access_token)

    on_exit(fn ->
      Application.put_env(:intercom, :access_token, access_token)
    end)
  end

  describe "call_endpoint/3" do
    test "makes authorized get requests" do
      user_id = "123"
      expected_url = Intercom.API.Rest.url("contacts/#{user_id}")
      response_code = 200
      body = "{\"id\": \"#{user_id}\", \"name\": \"Tester\"}"

      Intercom.ApiMockHelpers.mock_get(expected_url, response_code, body)

      {:ok, data, metadata} = Intercom.API.call_endpoint(:get, "contacts/#{user_id}")

      assert %{"id" => user_id, "name" => "Tester"} == data
      refute Map.has_key?(metadata, :pagination)
      assert Map.has_key?(metadata, :response)
      assert 167 == metadata.rate_limit.limit
      assert 167 == metadata.rate_limit.remaining
    end

    test "makes authorized get requests with per_page query param" do
      user_id = "123"
      expected_url = Intercom.API.Rest.url("contacts/#{user_id}") <> "?per_page=50"
      response_code = 200
      body = "{\"id\": \"#{user_id}\", \"name\": \"Tester\"}"

      Intercom.ApiMockHelpers.mock_get(expected_url, response_code, body)

      {:ok, data, metadata} =
        Intercom.API.call_endpoint(:get, "contacts/#{user_id}", nil, per_page: 50)

      assert %{"id" => user_id, "name" => "Tester"} == data
      refute Map.has_key?(metadata, :pagination)
      assert Map.has_key?(metadata, :response)
      assert 167 == metadata.rate_limit.limit
      assert 167 == metadata.rate_limit.remaining
    end

    test "makes authorized post requests" do
      expected_url = Intercom.API.Rest.url("contacts/search")

      data = %{
        query: %{field: "role", operator: "=", value: "user"}
      }

      response_code = 200

      body =
        "{\"type\":\"list\",\"data\": [{\"id\": \"123\", \"name\": \"Sebastian\"}], \"total_count\": 1, \"pages\":{\"type\":\"pages\",\"page\":1,\"per_page\":1,\"total_pages\":1}}"

      Intercom.ApiMockHelpers.mock_post(expected_url, data, response_code, body)

      {:ok, data, metadata} = Intercom.API.call_endpoint(:post, "contacts/search", data)

      assert length(data) == 1
      assert Map.has_key?(metadata, :response)
      assert 167 == metadata.rate_limit.limit
      assert 167 == metadata.rate_limit.remaining
    end

    test "makes authorized post requests with pagination" do
      expected_url = Intercom.API.Rest.url("contacts/search")

      data = %{
        query: %{field: "role", operator: "=", value: "user"}
      }

      response_code = 200

      body =
        "{\"type\":\"list\",\"data\": [{\"id\": \"123\", \"name\": \"Sebastian\"}, {\"id\": \"456\", \"name\": \"Tester\"}], \"total_count\": 4, \"pages\":{\"type\":\"pages\",\"page\":1,\"per_page\":2,\"total_pages\":2, \"next\": {\"page\": 2, \"starting_after\": \"WzE2MDI1MzgzMTEwMDAsIjVhM2FlYjVjOThhYmRhYjhlMDk3YzhmOSIsMl0=\"}}}"

      Intercom.ApiMockHelpers.mock_post(expected_url, data, response_code, body)

      {:ok, data, metadata} = Intercom.API.call_endpoint(:post, "contacts/search", data)

      assert length(data) == 2
      assert Map.has_key?(metadata, :pagination)
      assert Map.has_key?(metadata.pagination, :starting_after)
    end

    test "makes authorized post requests with pagination request" do
      expected_url = Intercom.API.Rest.url("contacts/search")

      data = %{
        query: %{field: "role", operator: "=", value: "user"}
      }

      expected_data = Map.merge(data, %{pagination: %{per_page: 50, starting_after: "abc_123"}})

      response_code = 200

      body =
        "{\"type\":\"list\",\"data\": [{\"id\": \"123\", \"name\": \"Sebastian\"}], \"total_count\": 1, \"pages\":{\"type\":\"pages\",\"page\":1,\"per_page\":50,\"total_pages\":1}}"

      Intercom.ApiMockHelpers.mock_post(expected_url, expected_data, response_code, body)

      {:ok, data, _metadata} =
        Intercom.API.call_endpoint(:post, "contacts/search", data,
          per_page: 50,
          starting_after: "abc_123"
        )

      assert length(data) == 1
    end

    test "makes authorized put requests" do
      expected_url = Intercom.API.Rest.url("contacts/1")

      data = %{
        email: "chuck@dgns.wtf"
      }

      response_code = 200

      body =
        "{\"type\":\"contact\",\"id\":\"58d90c0e1580bdc9390f0059\",\"external_id\":\"ab41f085-af25-3b16-b223-1f7a241a1200\",\"role\":\"user\",\"email\":\"chuck@dgns.wtf\"}"

      Intercom.ApiMockHelpers.mock_put(expected_url, data, response_code, body)

      {:ok, data, metadata} = Intercom.API.call_endpoint(:put, "contacts/1", data)

      assert data["email"] == "chuck@dgns.wtf"
      assert Map.has_key?(metadata, :response)
      assert 167 == metadata.rate_limit.limit
      assert 167 == metadata.rate_limit.remaining
    end

    test "returns correct error in case of 404" do
      user_id = "123"
      expected_url = Intercom.API.Rest.url("contacts/#{user_id}")
      response_code = 404

      body =
        "{\"type\":\"error.list\",\"request_id\":\"001epk13vcts36rcb9gg\",\"errors\":[{\"code\":\"not_found\",\"message\":\"User Not Found\"}]}"

      Intercom.ApiMockHelpers.mock_get(expected_url, response_code, body)

      {:error, :resource_not_found, metadata} =
        Intercom.API.call_endpoint(:get, "contacts/#{user_id}")

      assert Map.has_key?(metadata, :errors)
    end

    test "returns correct error in case rate limit exceeded" do
      user_id = "123"
      expected_url = Intercom.API.Rest.url("contacts/#{user_id}")
      response_code = 429

      headers =
        Intercom.ApiMockHelpers.intercom_headers(response_code, %{"X-RateLimit-Remaining" => "0"})

      Intercom.ApiMockHelpers.mock_get(expected_url, response_code, "", headers)

      {:error, :rate_limit_exceeded, metadata} =
        Intercom.API.call_endpoint(:get, "contacts/#{user_id}")

      assert 0 == metadata.rate_limit.remaining
    end

    test "returns error messages if no access token is given" do
      Application.delete_env(:intercom, :access_token)

      assert {:error, :no_access_token, nil} == Intercom.API.call_endpoint(:get, "contacts/123")
    end

    test "returns undefined and metadata in case of HTTPoison.Error" do
      expected_error = %HTTPoison.Error{id: nil, reason: :econnrefused}

      Intercom.MockHTTPoison
      |> expect(:get, fn _expected_url, _headers ->
        {:error, expected_error}
      end)

      {:error, :undefined, metadata} = Intercom.API.call_endpoint(:get, "contacts/123")

      assert expected_error == metadata.error
    end
  end
end
