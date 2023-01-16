defmodule BankWeb.CustomerResetPasswordController do
  use BankWeb, :controller

  alias Bank.CoreBanking

  plug :get_customer_by_reset_password_token when action in [:edit, :update]

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"customer" => %{"email" => email}}) do
    if customer = CoreBanking.get_customer_by_email(email) do
      CoreBanking.deliver_customer_reset_password_instructions(
        customer,
        &Routes.customer_reset_password_url(conn, :edit, &1)
      )
    end

    conn
    |> put_flash(
      :info,
      "If your email is in our system, you will receive instructions to reset your password shortly."
    )
    |> redirect(to: "/")
  end

  def edit(conn, _params) do
    render(conn, "edit.html", changeset: CoreBanking.change_customer_password(conn.assigns.customer))
  end

  def update(conn, %{"customer" => customer_params}) do
    case CoreBanking.reset_customer_password(conn.assigns.customer, customer_params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Password reset successfully.")
        |> redirect(to: Routes.customer_session_path(conn, :new))

      {:error, changeset} ->
        render(conn, "edit.html", changeset: changeset)
    end
  end

  defp get_customer_by_reset_password_token(conn, _opts) do
    %{"token" => token} = conn.params

    if customer = CoreBanking.get_customer_by_reset_password_token(token) do
      conn |> assign(:customer, customer) |> assign(:token, token)
    else
      conn
      |> put_flash(:error, "Reset password link is invalid or it has expired.")
      |> redirect(to: "/")
      |> halt()
    end
  end
end
