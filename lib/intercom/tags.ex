defmodule Intercom.Tags do
  @moduledoc """
  Provides functionality for managing tags.

  See https://developers.intercom.com/intercom-api-reference/reference#tag-model
  """

  @doc """
  Retrieves all tags. No pagination is available until Intercom implements them into their API.

  Returns `{:ok, data, metadata}` or `{:error, error_code, metadata}`
  """
  @spec list() :: Intercom.API.response()
  def list() do
    Intercom.API.call_endpoint(:get, "tags")
  end
end
