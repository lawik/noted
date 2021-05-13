defmodule Noted.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Noted.Repo

  alias Noted.Accounts.User

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    users = Repo.all(User)

    Enum.map(users, fn user ->
      {:ok, user} = decode!({:ok, user})
      user
    end)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id) do
    user = Repo.get!(User, id)

    case user do
      %User{} = user ->
        {:ok, user} = decode!({:ok, user})
        user

      _ ->
        user
    end
  end

  def get_user(id) do
    user = Repo.get(User, id)

    case user do
      %User{} = user ->
        {:ok, user} = decode!({:ok, user})
        user

      _ ->
        user
    end
  end

  def get_user_by_telegram_id(telegram_id) do
    user = Repo.get_by(User, telegram_id: telegram_id)

    case user do
      %User{} = user ->
        {:ok, user} = decode!({:ok, user})
        user

      nil ->
        nil
    end
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    attrs = encode!(attrs)

    user =
      %User{}
      |> User.changeset(attrs)
      |> Repo.insert()

    decode!(user)
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    attrs = encode!(attrs)

    user =
      user
      |> User.changeset(attrs)
      |> Repo.update()

    decode!(user)
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    attrs = encode!(attrs)
    User.changeset(user, attrs)
  end

  defp encode!(attrs) do
    case attrs do
      %{"telegram_data" => %{} = unencoded} ->
        Map.put(attrs, "telegram_data", Jason.encode!(unencoded))

      %{telegram_data: %{} = unencoded} ->
        Map.put(attrs, :telegram_data, Jason.encode!(unencoded))

      _ ->
        attrs
    end
  end

  defp decode!(user) do
    case user do
      {:ok, user} -> {:ok, %{user | telegram_data: Jason.decode!(user.telegram_data)}}
      {:error, _} -> user
    end
  end
end
