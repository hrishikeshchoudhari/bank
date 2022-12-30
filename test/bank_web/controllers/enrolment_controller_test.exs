defmodule BankWeb.EnrolmentControllerTest do
  use BankWeb.ConnCase

  import Bank.MarketingFixtures

  @create_attrs %{address: "some address", branch: "some branch", email: "some email", fname: "some fname", lname: "some lname", mname: "some mname", phone: "some phone"}
  @update_attrs %{address: "some updated address", branch: "some updated branch", email: "some updated email", fname: "some updated fname", lname: "some updated lname", mname: "some updated mname", phone: "some updated phone"}
  @invalid_attrs %{address: nil, branch: nil, email: nil, fname: nil, lname: nil, mname: nil, phone: nil}

  describe "index" do
    test "lists all enrolments", %{conn: conn} do
      conn = get(conn, Routes.enrolment_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Enrolments"
    end
  end

  describe "new enrolment" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.enrolment_path(conn, :new))
      assert html_response(conn, 200) =~ "New Enrolment"
    end
  end

  describe "create enrolment" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.enrolment_path(conn, :create), enrolment: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.enrolment_path(conn, :show, id)

      conn = get(conn, Routes.enrolment_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Enrolment"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.enrolment_path(conn, :create), enrolment: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Enrolment"
    end
  end

  describe "edit enrolment" do
    setup [:create_enrolment]

    test "renders form for editing chosen enrolment", %{conn: conn, enrolment: enrolment} do
      conn = get(conn, Routes.enrolment_path(conn, :edit, enrolment))
      assert html_response(conn, 200) =~ "Edit Enrolment"
    end
  end

  describe "update enrolment" do
    setup [:create_enrolment]

    test "redirects when data is valid", %{conn: conn, enrolment: enrolment} do
      conn = put(conn, Routes.enrolment_path(conn, :update, enrolment), enrolment: @update_attrs)
      assert redirected_to(conn) == Routes.enrolment_path(conn, :show, enrolment)

      conn = get(conn, Routes.enrolment_path(conn, :show, enrolment))
      assert html_response(conn, 200) =~ "some updated address"
    end

    test "renders errors when data is invalid", %{conn: conn, enrolment: enrolment} do
      conn = put(conn, Routes.enrolment_path(conn, :update, enrolment), enrolment: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Enrolment"
    end
  end

  describe "delete enrolment" do
    setup [:create_enrolment]

    test "deletes chosen enrolment", %{conn: conn, enrolment: enrolment} do
      conn = delete(conn, Routes.enrolment_path(conn, :delete, enrolment))
      assert redirected_to(conn) == Routes.enrolment_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.enrolment_path(conn, :show, enrolment))
      end
    end
  end

  defp create_enrolment(_) do
    enrolment = enrolment_fixture()
    %{enrolment: enrolment}
  end
end
