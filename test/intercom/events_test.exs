defmodule Intercom.EventsTest do
  use ExUnit.Case

  describe "submit/2" do
    test "returns correct result" do
      contact_id = "123"
      event_name = "testevent"

      expected_url = Intercom.API.Rest.url("events")
      response_code = 202

      Intercom.ApiMockHelpers.mock_post(expected_url, nil, response_code, "")

      {:ok, data, _metadata} = Intercom.Events.submit(contact_id, event_name)

      assert %{} == data
    end
  end

  describe "submit/3" do
    test "returns correct result" do
      contact_id = "123"
      event_name = "testevent"
      created_at = DateTime.utc_now() |> DateTime.add(-3600, :second)

      expected_url = Intercom.API.Rest.url("events")

      expected_data = %{
        id: contact_id,
        event_name: event_name,
        created_at: created_at |> DateTime.to_unix()
      }

      response_code = 202

      Intercom.ApiMockHelpers.mock_post(expected_url, expected_data, response_code, "")

      {:ok, data, _metadata} = Intercom.Events.submit(contact_id, event_name, created_at)

      assert %{} == data
    end
  end
end
