defmodule Bank.MarketingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Bank.Marketing` context.
  """

  @doc """
  Generate a enrolment.
  """
  def enrolment_fixture(attrs \\ %{}) do
    {:ok, enrolment} =
      attrs
      |> Enum.into(%{
        address: "some address",
        branch: "some branch",
        email: "some email",
        fname: "some fname",
        lname: "some lname",
        mname: "some mname",
        phone: "some phone"
      })
      |> Bank.Marketing.create_enrolment()

    enrolment
  end
end
