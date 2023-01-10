defmodule BankWeb.CustomerSettingsController do
  use BankWeb, :controller

  alias Bank.CoreBanking
  alias BankWeb.CustomerAuth

  plug :assign_email_and_password_changesets

  def edit(conn, _params) do
    render(conn, "edit.html")
  end

  def update(conn, %{"action" => "update_email"} = params) do
    %{"current_password" => password, "customer" => customer_params} = params
    customer = conn.assigns.current_customer

    case CoreBanking.apply_customer_email(customer, password, customer_params) do
      {:ok, applied_customer} ->
        CoreBanking.deliver_update_email_instructions(
          applied_customer,
          customer.email,
          &Routes.customer_settings_url(conn, :confirm_email, &1)
        )

        conn
        |> put_flash(
          :info,
          "A link to confirm your email change has been sent to the new address."
        )
        |> redirect(to: Routes.customer_settings_path(conn, :edit))

      {:error, changeset} ->
        render(conn, "edit.html", email_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"current_password" => password, "customer" => customer_params} = params
    customer = conn.assigns.current_customer

    case CoreBanking.update_customer_password(customer, password, customer_params) do
      {:ok, customer} ->
        conn
        |> put_flash(:info, "Password updated successfully.")
        |> put_session(:customer_return_to, Routes.customer_settings_path(conn, :edit))
        |> CustomerAuth.log_in_customer(customer)

      {:error, changeset} ->
        render(conn, "edit.html", password_changeset: changeset)
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    case CoreBanking.update_customer_email(conn.assigns.current_customer, token) do
      :ok ->
        conn
        |> put_flash(:info, "Email changed successfully.")
        |> redirect(to: Routes.customer_settings_path(conn, :edit))

      :error ->
        conn
        |> put_flash(:error, "Email change link is invalid or it has expired.")
        |> redirect(to: Routes.customer_settings_path(conn, :edit))
    end
  end

  defp assign_email_and_password_changesets(conn, _opts) do
    customer = conn.assigns.current_customer

    conn
    |> assign(:email_changeset, CoreBanking.change_customer_email(customer))
    |> assign(:password_changeset, CoreBanking.change_customer_password(customer))
  end
end
