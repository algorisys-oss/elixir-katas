defmodule ElixirKatas.Katas do
  @moduledoc """
  The Katas context.
  """

  import Ecto.Query, warn: false
  alias ElixirKatas.Repo
  alias ElixirKatas.Katas.UserKata

  @doc """
  Gets a user's version of a kata.
  """
  def get_user_kata(user_id, kata_name) do
    Repo.get_by(UserKata, user_id: user_id, kata_name: kata_name)
  end

  @doc """
  Saves a user's version of a kata. Creates it if it doesn't exist.
  """
  def save_user_kata(user_id, kata_name, source_code) do
    case get_user_kata(user_id, kata_name) do
      nil ->
        %UserKata{}
        |> UserKata.changeset(%{user_id: user_id, kata_name: kata_name, source_code: source_code})
        |> Repo.insert()

      user_kata ->
        user_kata
        |> UserKata.changeset(%{source_code: source_code})
        |> Repo.update()
    end
  end

  @doc """
  Deletes a user's version of a kata (Revert).
  """
  def delete_user_kata(user_id, kata_name) do
    case get_user_kata(user_id, kata_name) do
      nil -> {:error, :not_found}
      user_kata -> Repo.delete(user_kata)
    end
  end
end
