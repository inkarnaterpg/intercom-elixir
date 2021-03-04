defmodule Intercom.API do
  @moduledoc """
  Provides direct access to the Intercom API if other modules in
  this package don't provide the functionality you need.

  See https://developers.intercom.com/intercom-api-reference/reference
  """

  @type opts :: {:per_page, integer()} | {:starting_after, binary()}

  @type metadata_pagination ::
          %{
            required(:page) => integer(),
            optional(:next_page) => integer(),
            required(:total_pages) => integer(),
            required(:per_page) => integer(),
            optional(:starting_after) => binary()
          }
  @type metadata ::
          %{
            required(:response) => map(),
            required(:rate_limit) => %{
              limit: integer() | nil,
              reset: %DateTime{} | nil,
              remaining: integer() | nil
            },
            optional(:pagination) => metadata_pagination,
            optional(:errors) => [map()]
          }
  @type single_success :: {:ok, map(), metadata}
  @type multiple_success :: {:ok, [map()], metadata}
  @type error :: {:error, atom(), metadata | nil}
  @type response :: single_success | multiple_success | error

  @doc """
  Call an Intercom API endpoint.

  Arguments:
  - `method`: The HTTP request method.
  - `path`: The request path, e.g `"users/1234"`.
  - `body`: The body of the request. Optional.
  - `opts`: Will be added either to the query part of the url (get) or the body of the request (post). Optional.
    - `per_page`: Results per page if result is a list, has to be between 1 and 150.
    - `starting_after`: Hash returned by the intercom API to get next page of results.

  Returns `{:ok, data, metadata}` or `{:error, error_code, metadata}`.
  """
  def call_endpoint(method, path, body \\ nil, opts \\ [])

  @spec call_endpoint(:get, String.t(), nil) :: response()
  @spec call_endpoint(:get, String.t(), nil, [opts]) :: response()
  def call_endpoint(:get, path, nil, opts) do
    with url <- Intercom.API.Rest.url(path, opts) do
      call_endpoint_with_full_url_and_body(:get, url, nil)
    end
  end

  @spec call_endpoint(:post, String.t(), map() | nil) :: response()
  def call_endpoint(:post, path, body, []) do
    with url <- Intercom.API.Rest.url(path) do
      call_endpoint_with_full_url_and_body(:post, url, body)
    end
  end

  @spec call_endpoint(:post, String.t(), map() | nil, [opts]) :: response()
  def call_endpoint(:post, path, body, opts) do
    body =
      Map.merge(body, %{
        pagination: Enum.reduce(opts, %{}, fn {k, v}, acc -> Map.merge(acc, %{"#{k}": v}) end)
      })

    call_endpoint(:post, path, body)
  end

  @spec call_endpoint(:put, String.t(), map() | nil) :: response()
  def call_endpoint(:put, path, body, []) do
    with url <- Intercom.API.Rest.url(path) do
      call_endpoint_with_full_url_and_body(:put, url, body)
    end
  end

  defp call_endpoint_with_full_url_and_body(method, url, body) do
    with {:ok, authorized_headers} <- Intercom.API.Rest.authorized_headers(),
         {:ok, response, body} <-
           Intercom.API.Request.make_request(method, url, authorized_headers, body) do
      metadata =
        Map.merge(extract_metadata_from_headers(response), extract_metadata_from_body(body))

      {:ok, extract_body(body), metadata}
    else
      {:error, response, body} ->
        metadata =
          Map.merge(extract_metadata_from_headers(response), extract_metadata_from_body(body))

        {:error, extract_error_code(response), metadata}

      {:error, response} ->
        {:error, extract_error_code(response), extract_metadata_from_headers(response)}
    end
  end

  defp extract_metadata_from_body(%{"pages" => %{"next" => next} = pages, "type" => "list"}) do
    %{
      pagination: %{
        page: Map.get(pages, "page"),
        next_page: Map.get(next, "page"),
        total_pages: Map.get(pages, "total_pages"),
        per_page: Map.get(pages, "per_page"),
        starting_after: Map.get(next, "starting_after")
      }
    }
  end

  defp extract_metadata_from_body(%{"pages" => pages, "type" => "list"}) do
    %{
      pagination: %{
        page: Map.get(pages, "page"),
        total_pages: Map.get(pages, "total_pages"),
        per_page: Map.get(pages, "per_page")
      }
    }
  end

  defp extract_metadata_from_body(%{"type" => "error.list", "errors" => errors}) do
    %{
      errors: errors
    }
  end

  defp extract_metadata_from_body(_body), do: %{}

  defp extract_metadata_from_headers(%HTTPoison.Response{} = response) do
    headers = Enum.into(response.headers, %{})

    %{
      response: response,
      rate_limit: %{
        limit: extract_x_ratelimit_limit_from_headers(headers),
        reset: extract_x_ratelimit_reset_from_headers(headers),
        remaining: extract_x_ratelimit_remaining_from_headers(headers)
      }
    }
  end

  defp extract_metadata_from_headers(%HTTPoison.Error{} = error), do: %{error: error}

  defp extract_metadata_from_headers(_response), do: nil

  defp extract_x_ratelimit_limit_from_headers(%{"X-RateLimit-Limit" => x_ratelimit_limit}),
    do: String.to_integer(x_ratelimit_limit)

  defp extract_x_ratelimit_limit_from_headers(_headers), do: nil

  defp extract_x_ratelimit_reset_from_headers(%{"X-RateLimit-Reset" => x_ratelimit_reset}),
    do: x_ratelimit_reset |> String.to_integer() |> DateTime.from_unix!()

  defp extract_x_ratelimit_reset_from_headers(_headers), do: nil

  defp extract_x_ratelimit_remaining_from_headers(%{
         "X-RateLimit-Remaining" => x_ratelimit_remaining
       }),
       do: String.to_integer(x_ratelimit_remaining)

  defp extract_x_ratelimit_remaining_from_headers(_headers), do: nil

  defp extract_body(%{"data" => data, "type" => "list"}), do: data

  defp extract_body(body), do: body

  defp extract_error_code(%HTTPoison.Response{status_code: 400}), do: :bad_request

  defp extract_error_code(%HTTPoison.Response{status_code: 404}), do: :resource_not_found

  defp extract_error_code(%HTTPoison.Response{status_code: 429}), do: :rate_limit_exceeded

  defp extract_error_code(:no_access_token), do: :no_access_token

  defp extract_error_code(:invalid_access_token), do: :invalid_access_token

  defp extract_error_code(_response), do: :undefined
end
