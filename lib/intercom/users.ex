defmodule Intercom.Users do
  @moduledoc """
  Provides functionality for managing users.

  See https://developers.intercom.com/intercom-api-reference/reference#users
  """

  @spec get(String.t()) :: Intercom.API.response()
  def get(id) do
    Intercom.API.call_endpoint(:get, "users/#{id}")
  end

  @spec get_by(user_id: String.t()) :: Intercom.API.response()
  def get_by(user_id: user_id) do
    Intercom.API.call_endpoint(:get, "users?user_id=#{user_id}")
  end

  @spec list :: Intercom.API.response()
  def list() do
    Intercom.API.call_endpoint(:get, "users")
  end

  @spec list_by([{:email, String.t()}] | [{:tag_id, String.t()}] | [{:segment_id, String.t()}]) ::
          Intercom.API.response()
  def list_by(email: email) do
    Intercom.API.call_endpoint(:get, "users?email=#{email}")
  end

  def list_by(tag_id: tag_id) do
    Intercom.API.call_endpoint(:get, "users?tag_id=#{tag_id}")
  end

  def list_by(segment_id: segment_id) do
    Intercom.API.call_endpoint(:get, "users?segment_id=#{segment_id}")
  end

  @spec upsert(map()) :: Intercom.API.response()
  def upsert(user_data) when is_map(user_data) do
    Intercom.API.call_endpoint(:post, "users", user_data)
  end

  @spec bulk_upsert(list(), integer()) :: [Intercom.API.response()]
  def bulk_upsert(user_data_list, chunk_size \\ 100) when is_list(user_data_list) do
    user_data_list
    |> Enum.map(fn(user_data) -> %{method: "post", data_type: "user", data: user_data} end)
    |> Enum.chunk_every(chunk_size)
    |> Enum.map(&Intercom.API.call_endpoint(:post, "bulk/users", %{items: &1}))
  end
end
