defmodule Bank.AdminFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Bank.Admin` context.
  """

  def unique_employee_email, do: "employee#{System.unique_integer()}@example.com"
  def valid_employee_password, do: "hello world!"

  def valid_employee_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_employee_email(),
      password: valid_employee_password()
    })
  end

  def employee_fixture(attrs \\ %{}) do
    {:ok, employee} =
      attrs
      |> valid_employee_attributes()
      |> Bank.Admin.register_employee()

    employee
  end

  def extract_employee_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
