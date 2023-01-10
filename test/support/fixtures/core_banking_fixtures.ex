defmodule Bank.CoreBankingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Bank.CoreBanking` context.
  """

  def unique_customer_email, do: "customer#{System.unique_integer()}@example.com"
  def valid_customer_password, do: "hello world!"

  def valid_customer_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_customer_email(),
      password: valid_customer_password()
    })
  end

  def customer_fixture(attrs \\ %{}) do
    {:ok, customer} =
      attrs
      |> valid_customer_attributes()
      |> Bank.CoreBanking.register_customer()

    customer
  end

  def extract_customer_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
