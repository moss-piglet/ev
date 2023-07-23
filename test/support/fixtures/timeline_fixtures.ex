defmodule Metamorphic.TimelineFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Metamorphic.Timeline` context.
  """

  @doc """
  Generate a post.
  """
  def post_fixture(attrs \\ %{}) do
    {:ok, post} =
      attrs
      |> Enum.into(%{
        body: "some body",
        username: "some username",
        favs_count: 42,
        reposts_count: 42
      })
      |> Metamorphic.Timeline.create_post()

    post
  end
end
