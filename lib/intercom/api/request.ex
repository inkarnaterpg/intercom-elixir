defmodule Intercom.API.Request do
  @moduledoc false

  @spec make_request(:get, binary(), list(), nil) ::
          {:error, HTTPoison.Response.t() | any()} | {:ok, HTTPoison.Response.t(), map()}
  def make_request(:get, url, headers, nil) do
    http_adapter().get(url, headers)
    |> parse_response()
  end

  @spec make_request(:post, binary(), list(), map()) ::
          {:error, HTTPoison.Response.t() | any()} | {:ok, HTTPoison.Response.t(), map()}
  def make_request(:post, url, headers, body) do
    http_adapter().post(url, Jason.encode!(body), headers, [])
    |> parse_response()
  end

  @spec make_request(:put, binary(), list(), map()) ::
          {:error, HTTPoison.Response.t() | any()} | {:ok, HTTPoison.Response.t(), map()}
  def make_request(:put, url, headers, body) do
    http_adapter().put(url, Jason.encode!(body), headers, [])
    |> parse_response()
  end

  @spec make_request(:delete, binary(), list(), nil) ::
          {:error, HTTPoison.Response.t() | any()} | {:ok, HTTPoison.Response.t(), map()}
  def make_request(:delete, url, headers, nil) do
    http_adapter().delete(url, headers, [])
    |> parse_response()
  end

  defp parse_response({:ok, %HTTPoison.Response{} = response}) do
    case decode_body(response) do
      {:ok, body} ->
        case response.status_code do
          200 -> {:ok, response, body}
          202 -> {:ok, response, body}
          _ -> {:error, response, body}
        end

      {:error, response} ->
        {:error, response}
    end
  end

  defp parse_response({:error, error}), do: {:error, error}

  defp parse_response({:ok, response}) do
    {:error, response}
  end

  defp decode_body(%HTTPoison.Response{body: ""}), do: {:ok, %{}}

  defp decode_body(%HTTPoison.Response{body: body} = response) do
    case Jason.decode(body) do
      {:ok, json} ->
        {:ok, json}

      {:error, _} ->
        {:error, response}
    end
  end

  defp http_adapter() do
    Application.get_env(:intercom, :http_adapter)
  end
end
