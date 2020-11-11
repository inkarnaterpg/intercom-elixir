defmodule Intercom.ApiMockHelpers do
  import Mox

  def mock_get(expected_url, response_code),
    do: mock_get(expected_url, response_code, "", intercom_headers())

  def mock_get(expected_url, response_code, body),
    do: mock_get(expected_url, response_code, body, intercom_headers())

  def mock_get(expected_url, response_code, body, headers) do
    Intercom.MockHTTPoison
    |> expect(:get, fn ^expected_url, _headers ->
      {:ok,
       %HTTPoison.Response{
         status_code: response_code,
         body: body,
         headers: headers
       }}
    end)
  end

  def mock_post(expected_url, expected_body, response_code),
    do: mock_post(expected_url, expected_body, response_code, "", intercom_headers())

  def mock_post(expected_url, expected_body, response_code, body),
    do: mock_post(expected_url, expected_body, response_code, body, intercom_headers())

  def mock_post(expected_url, expected_body, response_code, body, headers) do
    expected_body = Jason.encode!(expected_body)

    Intercom.MockHTTPoison
    |> expect(:post, fn ^expected_url, ^expected_body, _headers, [] ->
      {:ok,
       %HTTPoison.Response{
         status_code: response_code,
         body: body,
         headers: headers
       }}
    end)
  end

  def intercom_headers(headers \\ %{}) do
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
end
