defmodule Bank.CoreBanking do
  @moduledoc """
  The CoreBanking context.
  """

  import Ecto.Query, warn: false
  alias Bank.Repo

  alias Bank.CoreBanking.Account
  alias Bank.Marketing.Lead

  def get_lead!(id) do
    Repo.get!(Lead, id)
  end

  def create_account(name) do
    acn = Integer.to_string(System.unique_integer([:positive]))
    secret = Float.to_string(:rand.uniform())
    new_acc = %{acn: acn, fname: name, balance: 1000, secret: secret}
    %Account{}
    |> Account.changeset(new_acc)
    |> Repo.insert()
  end
end
