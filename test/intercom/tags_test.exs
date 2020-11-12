defmodule Intercom.TagsTest do
  use ExUnit.Case

  describe "list/0" do
    test "returns correct result" do
      expected_url = Intercom.API.Rest.url("tags")
      response_code = 200

      body =
        "{\"type\":\"list\",\"data\":[{\"type\":\"tag\",\"id\":\"123\",\"name\":\"Test #2\"},{\"type\":\"tag\",\"id\":\"456\",\"name\":\"Test #2\"}]}"

      Intercom.ApiMockHelpers.mock_get(expected_url, response_code, body)

      {:ok, data, _metadata} = Intercom.Tags.list()

      assert 2 == length(data)
    end
  end
end
