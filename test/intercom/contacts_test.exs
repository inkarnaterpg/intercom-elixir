defmodule Intercom.ContactsTest do
  use ExUnit.Case

  @user_id "123"

  describe "get/1" do
    test "returns correct result in case user id does exist" do
      expected_url = Intercom.API.Rest.url("contacts/#{@user_id}")
      response_code = 200
      body = "{\"id\": \"#{@user_id}\", \"name\": \"Tester\"}"

      Intercom.ApiMockHelpers.mock_get(expected_url, response_code, body)

      {:ok, data, _metadata} = Intercom.Contacts.get(@user_id)

      assert %{"id" => @user_id, "name" => "Tester"} == data
    end

    test "returns correct result in case user id does not exist" do
      expected_url = Intercom.API.Rest.url("contacts/#{@user_id}")
      response_code = 404

      Intercom.ApiMockHelpers.mock_get(expected_url, response_code)

      {:error, error, _metadata} = Intercom.Contacts.get(@user_id)

      assert :resource_not_found == error
    end

    test "returns correct result in case rate limit exceeded" do
      expected_url = Intercom.API.Rest.url("contacts/#{@user_id}")
      response_code = 429
      headers = Intercom.ApiMockHelpers.intercom_headers(%{"X-RateLimit-Remaining" => "0"})

      Intercom.ApiMockHelpers.mock_get(expected_url, response_code, "", headers)

      {:error, error, metadata} = Intercom.Contacts.get(@user_id)

      assert :rate_limit_exceeded == error
      assert 0 == metadata.rate_limit.remaining
    end
  end

  describe "find_equal/2" do
    test "returns correct result for one result" do
      expected_url = Intercom.API.Rest.url("contacts/search")

      expected_data = %{
        query: %{field: "email", operator: "=", value: "test@test.local"}
      }

      response_code = 200

      body =
        "{\"type\":\"list\",\"data\": [{\"id\": \"123\", \"name\": \"Sebastian\"}], \"total_count\": 1, \"pages\":{\"type\":\"pages\",\"page\":1,\"per_page\":50,\"total_pages\":1}}"

      Intercom.ApiMockHelpers.mock_post(expected_url, expected_data, response_code, body)

      {:ok, data, _metadata} = Intercom.Contacts.find_equal("test", "test@test.local")

      assert length(data) == 1
    end

    test "returns correct result for multiple result on one page" do
      expected_url = Intercom.API.Rest.url("contacts/search")

      expected_data = %{
        query: %{field: "role", operator: "=", value: "user"}
      }

      response_code = 200

      body =
        "{\"type\":\"list\",\"data\": [{\"id\": \"123\", \"name\": \"Sebastian\"}, {\"id\": \"456\", \"name\": \"Tester\"}], \"total_count\": 1, \"pages\":{\"type\":\"pages\",\"page\":1,\"per_page\":50,\"total_pages\":1}}"

      Intercom.ApiMockHelpers.mock_post(expected_url, expected_data, response_code, body)

      {:ok, data, _metadata} = Intercom.Contacts.find_equal("role", "user")

      assert length(data) == 2
    end

    test "returns correct result for multiple result on multiple pages" do
      expected_url = Intercom.API.Rest.url("contacts/search")

      expected_data = %{
        query: %{field: "role", operator: "=", value: "user"}
      }

      response_code = 200

      body =
        "{\"type\":\"list\",\"data\": [{\"id\": \"123\", \"name\": \"Sebastian\"}, {\"id\": \"456\", \"name\": \"Tester\"}], \"total_count\": 4, \"pages\":{\"type\":\"pages\",\"page\":1,\"per_page\":2,\"total_pages\":2, \"next\": {\"page\": 2, \"starting_after\": \"WzE2MDI1MzgzMTEwMDAsIjVhM2FlYjVjOThhYmRhYjhlMDk3YzhmOSIsMl0=\"}}}"

      Intercom.ApiMockHelpers.mock_post(expected_url, expected_data, response_code, body)

      {:ok, data, _metadata} = Intercom.Contacts.find_equal("role", "user")

      assert length(data) == 2
    end
  end
end
