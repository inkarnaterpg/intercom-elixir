defmodule Intercom.ContactsTest do
  use ExUnit.Case

  describe "get/1" do
    test "returns correct result in case contact_id does exist" do
      contact_id = "123"

      expected_url = Intercom.API.Rest.url("contacts/#{contact_id}")
      response_code = 200
      body = "{\"id\": \"#{contact_id}\", \"name\": \"Tester\"}"

      Intercom.ApiMockHelpers.mock_get(expected_url, response_code, body)

      {:ok, data, _metadata} = Intercom.Contacts.get(contact_id)

      assert %{"id" => contact_id, "name" => "Tester"} == data
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

      {:ok, [data], _metadata} = Intercom.Contacts.find_equal("email", "test@test.local")

      assert data["id"] == "123"
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

  describe "create/1" do
    test "returns correct result for new contact" do
      expected_url = Intercom.API.Rest.url("contacts")

      expected_data = %{
        role: "user",
        external_id: "123",
        email: "chuck@dgns.wtf"
      }

      response_code = 200

      body =
        "{\"id\": \"test\", \"role\": \"user\", \"email\": \"chuck@dgns.wtf\", \"external_id\": \"123\"}"

      Intercom.ApiMockHelpers.mock_post(expected_url, expected_data, response_code, body)

      {:ok, data, _metadata} =
        Intercom.Contacts.create(%{role: "user", external_id: "123", email: "chuck@dgns.wtf"})

      assert %{
               "id" => "test",
               "role" => "user",
               "email" => "chuck@dgns.wtf",
               "external_id" => "123"
             } == data
    end
  end

  describe "update/2" do
    test "returns correct result in case contact_id does exist" do
      contact_id = "123"

      expected_url = Intercom.API.Rest.url("contacts/#{contact_id}")

      expected_data = %{
        email: "chuck@dgns.wtf"
      }

      response_code = 200
      body = "{\"id\": \"#{contact_id}\", \"name\": \"Tester\", \"email\": \"chuck@dgns.wtf\"}"

      Intercom.ApiMockHelpers.mock_put(expected_url, expected_data, response_code, body)

      {:ok, data, _metadata} = Intercom.Contacts.update(contact_id, %{email: "chuck@dgns.wtf"})

      assert %{"id" => contact_id, "name" => "Tester", "email" => "chuck@dgns.wtf"} == data
    end
  end

  describe "archive/1" do
    test "returns correct result in case contact_id does exist" do
      contact_id = "123"

      expected_url = Intercom.API.Rest.url("contacts/#{contact_id}/archive")

      expected_data = nil

      response_code = 200
      body = "{\"id\": \"#{contact_id}\", \"archived\": true}"

      Intercom.ApiMockHelpers.mock_post(expected_url, expected_data, response_code, body)

      {:ok, data, _metadata} = Intercom.Contacts.archive(contact_id)

      assert %{"id" => contact_id, "archived" => true} == data
    end
  end

  describe "add_tag/2" do
    test "returns correct result in case contact_id and tag_id does exist" do
      contact_id = "123"
      tag_id = "456"

      expected_url = Intercom.API.Rest.url("contacts/#{contact_id}/tags")

      expected_data = %{
        id: tag_id
      }

      response_code = 200

      body = "{\"type\": \"tag\", \"id\": \"#{tag_id}\", \"name\": \"Test Tag\"}"

      Intercom.ApiMockHelpers.mock_post(expected_url, expected_data, response_code, body)

      {:ok, data, _metadata} = Intercom.Contacts.add_tag(contact_id, tag_id)

      assert %{"type" => "tag", "id" => tag_id, "name" => "Test Tag"} == data
    end
  end
end
