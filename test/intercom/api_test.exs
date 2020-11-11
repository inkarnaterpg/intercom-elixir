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

    test "makes authorized post requests" do
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
      assert Map.has_key?(metadata, :response)
      assert 167 == metadata.rate_limit.limit
      assert 167 == metadata.rate_limit.remaining
    end

    test "returns error messages for known errors" do
      Application.delete_env(:intercom, :access_token)

      assert {:error, :no_access_token, nil} == Intercom.API.call_endpoint(:get, "contacts/123")
    end

    test "returns raw unknown error messages" do
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
