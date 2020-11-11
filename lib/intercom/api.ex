defmodule Intercom.API do
  @moduledoc """
  Provides direct access to the Intercom API if other modules in
  this package don't provide the functionality you need.

  See https://developers.intercom.com/intercom-api-reference/reference
  """

  @type metadata_pagination ::
          %{page: integer(), total_pages: integer(), per_page: integer()}
          | %{
              page: integer(),
              next_page: integer(),
              total_pages: integer(),
              per_page: integer(),
              starting_after: binary()
            }
  @type metadata ::
          %{
            response: map(),
            rate_limit: %{
              limit: integer(),
              reset: %DateTime{},
              remaining: integer()
            }
          }
          | %{
              response: map(),
              rate_limit: %{
                limit: integer(),
                reset: %DateTime{},
                remaining: integer()
              },
              pagination: metadata_pagination
            }
  @type success :: {:ok, map(), metadata}
  @type error :: {:error, atom(), metadata | nil}
  @type response :: success | error

  @doc """
  Call an Intercom API endpoint.

  Arguments:
  - `method`: The HTTP request method.
  - `path`: The request path, e.g `"users/1234"`.
  - `body`: The body of the request. Optional.

  Returns `{:ok, data, metadata}` or `{:error, error_code, metadata}`.
  """
  @spec call_endpoint(:get | :post, String.t(), map() | nil) :: response()
  def call_endpoint(method, path, body \\ nil) do
    with url <- Intercom.API.Rest.url(path),
         {:ok, authorized_headers} <- Intercom.API.Rest.authorized_headers(),
         {:ok, response, body} <-
           Intercom.API.Request.make_request(method, url, authorized_headers, body) do
      metadata =
        Map.merge(extract_metadata_from_headers(response), extract_metadata_from_body(body))

      {:ok, extract_body(body), metadata}
    else
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

  defp extract_metadata_from_body(_body), do: %{}

  defp extract_metadata_from_headers(%HTTPoison.Response{} = response) do
    headers = Enum.into(response.headers, %{})

    %{
      response: response,
      rate_limit: %{
        limit: String.to_integer(headers["X-RateLimit-Limit"]),
        reset: DateTime.from_unix!(String.to_integer(headers["X-RateLimit-Reset"])),
        remaining: String.to_integer(headers["X-RateLimit-Remaining"])
      }
    }
  end

  defp extract_metadata_from_headers(%HTTPoison.Error{} = error), do: %{error: error}

  defp extract_metadata_from_headers(_response), do: nil

  defp extract_body(%{"data" => data, "type" => "list"}), do: data

  defp extract_body(body), do: body

  defp extract_error_code(%HTTPoison.Response{status_code: 400}), do: :bad_request

  defp extract_error_code(%HTTPoison.Response{status_code: 404}), do: :resource_not_found

  defp extract_error_code(%HTTPoison.Response{status_code: 429}), do: :rate_limit_exceeded

  defp extract_error_code(:no_access_token), do: :no_access_token

  defp extract_error_code(:invalid_access_token), do: :invalid_access_token

  defp extract_error_code(_response), do: :undefined
end
