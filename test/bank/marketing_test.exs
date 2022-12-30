defmodule Bank.MarketingTest do
  use Bank.DataCase

  alias Bank.Marketing

  describe "enrolments" do
    alias Bank.Marketing.Enrolment

    import Bank.MarketingFixtures

    @invalid_attrs %{address: nil, branch: nil, email: nil, fname: nil, lname: nil, mname: nil, phone: nil}

    test "list_enrolments/0 returns all enrolments" do
      enrolment = enrolment_fixture()
      assert Marketing.list_enrolments() == [enrolment]
    end

    test "get_enrolment!/1 returns the enrolment with given id" do
      enrolment = enrolment_fixture()
      assert Marketing.get_enrolment!(enrolment.id) == enrolment
    end

    test "create_enrolment/1 with valid data creates a enrolment" do
      valid_attrs = %{address: "some address", branch: "some branch", email: "some email", fname: "some fname", lname: "some lname", mname: "some mname", phone: "some phone"}

      assert {:ok, %Enrolment{} = enrolment} = Marketing.create_enrolment(valid_attrs)
      assert enrolment.address == "some address"
      assert enrolment.branch == "some branch"
      assert enrolment.email == "some email"
      assert enrolment.fname == "some fname"
      assert enrolment.lname == "some lname"
      assert enrolment.mname == "some mname"
      assert enrolment.phone == "some phone"
    end

    test "create_enrolment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Marketing.create_enrolment(@invalid_attrs)
    end

    test "update_enrolment/2 with valid data updates the enrolment" do
      enrolment = enrolment_fixture()
      update_attrs = %{address: "some updated address", branch: "some updated branch", email: "some updated email", fname: "some updated fname", lname: "some updated lname", mname: "some updated mname", phone: "some updated phone"}

      assert {:ok, %Enrolment{} = enrolment} = Marketing.update_enrolment(enrolment, update_attrs)
      assert enrolment.address == "some updated address"
      assert enrolment.branch == "some updated branch"
      assert enrolment.email == "some updated email"
      assert enrolment.fname == "some updated fname"
      assert enrolment.lname == "some updated lname"
      assert enrolment.mname == "some updated mname"
      assert enrolment.phone == "some updated phone"
    end

    test "update_enrolment/2 with invalid data returns error changeset" do
      enrolment = enrolment_fixture()
      assert {:error, %Ecto.Changeset{}} = Marketing.update_enrolment(enrolment, @invalid_attrs)
      assert enrolment == Marketing.get_enrolment!(enrolment.id)
    end

    test "delete_enrolment/1 deletes the enrolment" do
      enrolment = enrolment_fixture()
      assert {:ok, %Enrolment{}} = Marketing.delete_enrolment(enrolment)
      assert_raise Ecto.NoResultsError, fn -> Marketing.get_enrolment!(enrolment.id) end
    end

    test "change_enrolment/1 returns a enrolment changeset" do
      enrolment = enrolment_fixture()
      assert %Ecto.Changeset{} = Marketing.change_enrolment(enrolment)
    end
  end
end
