defmodule Intercom.ApiMockHelpers do
  @moduledoc false

  import Mox

  def mock_get(expected_url, response_code),
    do: mock_get(expected_url, response_code, "", intercom_headers(response_code))

  def mock_get(expected_url, response_code, body),
    do: mock_get(expected_url, response_code, body, intercom_headers(response_code))

  def mock_get(expected_url, response_code, body, headers) do
    Intercom.MockHTTPoison
    |> expect(:get, fn ^expected_url, _headers ->
      mock_response(response_code, headers, body)
    end)
  end

  def mock_post(expected_url, expected_body, response_code),
    do: mock_post(expected_url, expected_body, response_code, "", intercom_headers(response_code))

  def mock_post(expected_url, expected_body, response_code, body),
    do:
      mock_post(expected_url, expected_body, response_code, body, intercom_headers(response_code))

  def mock_post(expected_url, nil, response_code, body, headers) do
    Intercom.MockHTTPoison
    |> expect(:post, fn ^expected_url, _expected_body, _headers, [] ->
      mock_response(response_code, headers, body)
    end)
  end

  def mock_post(expected_url, expected_body, response_code, body, headers) do
    expected_body = Jason.encode!(expected_body)

    Intercom.MockHTTPoison
    |> expect(:post, fn ^expected_url, ^expected_body, _headers, [] ->
      mock_response(response_code, headers, body)
    end)
  end

  def mock_put(expected_url, expected_body, response_code, body) do
    expected_body = Jason.encode!(expected_body)

    Intercom.MockHTTPoison
    |> expect(:put, fn ^expected_url, ^expected_body, _headers, [] ->
      mock_response(response_code, intercom_headers(response_code), body)
    end)
  end

  def intercom_headers(response_code, headers \\ %{})

  def intercom_headers(200, headers) do
    Map.merge(
      %{
        "Content-Type" => "application/json; charset=utf-8",
        "X-RateLimit-Limit" => "167",
        "X-RateLimit-Reset" => "1604928780",
        "X-RateLimit-Remaining" => "167"
      },
      headers
    )
    |> Map.to_list()
  end

  def intercom_headers(202, headers) do
    Map.merge(
      %{
        "Content-Type" => "application/json; charset=utf-8",
        "X-RateLimit-Limit" => "167",
        "X-RateLimit-Reset" => "1604928780",
        "X-RateLimit-Remaining" => "167"
      },
      headers
    )
    |> Map.to_list()
  end

  def intercom_headers(_response_code, headers) do
    Map.merge(
      %{
        "Content-Type" => "application/json; charset=utf-8"
      },
      headers
    )
    |> Map.to_list()
  end

  defp mock_response(response_code, headers, body) do
    {:ok,
     %HTTPoison.Response{
       status_code: response_code,
       body: body,
       headers: headers
     }}
  end
end
