defmodule Intercom.API.RestTest do
  use ExUnit.Case, async: false

  @module Intercom.API.Rest
  @valid_access_token "abcde"

  setup do
    access_token = Application.get_env(:intercom, :access_token)

    on_exit(fn ->
      Application.put_env(:intercom, :access_token, access_token)
    end)
  end

  describe "url/1" do
    test "appends path to base endpoint url" do
      assert "https://api.intercom.io/users" == @module.url("users")
    end
  end

  describe "authorized_headers/0" do
    test "puts access token into authorization header" do
      assert {:ok,
              [
                Authorization: "Bearer #{@valid_access_token}",
                Accept: "application/json",
                "Content-Type": "application/json"
              ]} == @module.authorized_headers()
    end

    test "returns errors from getting access token" do
      Application.delete_env(:intercom, :access_token)
      assert {:error, :no_access_token} == @module.authorized_headers()
    end
  end
end
