defmodule BankWeb.EmployeeConfirmationControllerTest do
  use BankWeb.ConnCase, async: true

  alias Bank.Admin
  alias Bank.Repo
  import Bank.AdminFixtures

  setup do
    %{employee: employee_fixture()}
  end

  describe "GET /employees/confirm" do
    test "renders the resend confirmation page", %{conn: conn} do
      conn = get(conn, Routes.employee_confirmation_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Resend confirmation instructions</h1>"
    end
  end

  describe "POST /employees/confirm" do
    @tag :capture_log
    test "sends a new confirmation token", %{conn: conn, employee: employee} do
      conn =
        post(conn, Routes.employee_confirmation_path(conn, :create), %{
          "employee" => %{"email" => employee.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.get_by!(Admin.EmployeeToken, employee_id: employee.id).context == "confirm"
    end

    test "does not send confirmation token if Employee is confirmed", %{conn: conn, employee: employee} do
      Repo.update!(Admin.Employee.confirm_changeset(employee))

      conn =
        post(conn, Routes.employee_confirmation_path(conn, :create), %{
          "employee" => %{"email" => employee.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      refute Repo.get_by(Admin.EmployeeToken, employee_id: employee.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.employee_confirmation_path(conn, :create), %{
          "employee" => %{"email" => "unknown@example.com"}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.all(Admin.EmployeeToken) == []
    end
  end

  describe "GET /employees/confirm/:token" do
    test "renders the confirmation page", %{conn: conn} do
      conn = get(conn, Routes.employee_confirmation_path(conn, :edit, "some-token"))
      response = html_response(conn, 200)
      assert response =~ "<h1>Confirm account</h1>"

      form_action = Routes.employee_confirmation_path(conn, :update, "some-token")
      assert response =~ "action=\"#{form_action}\""
    end
  end

  describe "POST /employees/confirm/:token" do
    test "confirms the given token once", %{conn: conn, employee: employee} do
      token =
        extract_employee_token(fn url ->
          Admin.deliver_employee_confirmation_instructions(employee, url)
        end)

      conn = post(conn, Routes.employee_confirmation_path(conn, :update, token))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "Employee confirmed successfully"
      assert Admin.get_employee!(employee.id).confirmed_at
      refute get_session(conn, :employee_token)
      assert Repo.all(Admin.EmployeeToken) == []

      # When not logged in
      conn = post(conn, Routes.employee_confirmation_path(conn, :update, token))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Employee confirmation link is invalid or it has expired"

      # When logged in
      conn =
        build_conn()
        |> log_in_employee(employee)
        |> post(Routes.employee_confirmation_path(conn, :update, token))

      assert redirected_to(conn) == "/"
      refute get_flash(conn, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, employee: employee} do
      conn = post(conn, Routes.employee_confirmation_path(conn, :update, "oops"))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Employee confirmation link is invalid or it has expired"
      refute Admin.get_employee!(employee.id).confirmed_at
    end
  end
end
