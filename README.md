This is a fork of the [intercom](https://github.com/intercom/intercom-elixir) library which is no longer maintained.

# Intercom

An Elixir library for working with [Intercom](https://intercom.io) using the [Intercom API](https://developers.intercom.com/building-apps/docs/rest-apis).

## Installation

Add `intercom` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:intercom, "~> 2.0", hex: :intercom_elixir}
  ]
end
```

## Configuration

To get started you'll need to add your [access_token](https://developers.intercom.com/building-apps/docs/authentication-types#section-access-tokens) to your `config.exs` file. You can also change the http_adapter used to make requests. This library uses `HTTPoison` by default.

See [How to get your Access Token](https://developers.intercom.com/building-apps/docs/authentication-types#section-how-to-get-your-access-token).

**Keep your access token secret. It provides access to your private Intercom data and should be treated like a password.**

```elixir
config :intercom,
  access_token: "access_token_here..."
  http_adapter: HTTPoison
```

## Usage

The [full documentation](https://hexdocs.pm/intercom_elixir/api-reference.html) is published to hexdocs.

This library provides functions for easy access to API endpoints. For example, [User](https://developers.intercom.com/intercom-api-reference/reference#users) endpoints can be accessed like this:

```elixir
# Get a user
{:ok, user} = Intercom.Users.get("a1b2")

# List users by `tag_id`
{:ok, %{"users" => users}} = Intercom.Users.list_by(tag_id: "a1b2")

# Insert or update a user
{:ok, upserted_user} = Intercom.Users.upsert(%{id: "a1b2", name: "Steve Buscemi"})
```

If there are endpoints in the API that aren't currently supported by this library, you can access them manually like this:

```elixir
{:ok, data} = Intercom.API.call_endpoint(:post, "new_endpoint/a1b2", %{body_data: "here"})
```

## Resources

- [Intercom Developer Hub](https://developers.intercom.com/)
- [API Guide](https://developers.intercom.com/building-apps/docs/rest-apis)
- [API Reference](https://developers.intercom.com/intercom-api-reference/reference)
- [SDKs and Plugins](https://developers.intercom.com/building-apps/docs/sdks-plugins)
