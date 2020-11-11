defmodule Intercom.API.Rest do
  @moduledoc false

  def url(path, opts \\ []) do
    ("https://api.intercom.io/" <> path)
    |> URI.parse()
    |> put_query(opts)
    |> URI.to_string()
  end

  defp put_query(uri, []), do: uri

  defp put_query(uri, opts), do: Map.put(uri, :query, URI.encode_query(opts))

  def authorized_headers do
    case Intercom.API.Authentication.get_access_token() do
      {:ok, access_token} ->
        {:ok,
         [
           Authorization: "Bearer #{access_token}",
           Accept: "application/json",
           "Content-Type": "application/json"
         ]}

      {:error, error} ->
        {:error, error}
    end
  end
end
