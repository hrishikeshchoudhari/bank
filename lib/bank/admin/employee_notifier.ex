defmodule Bank.Admin.EmployeeNotifier do
  import Swoosh.Email

  alias Bank.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"Bank", "contact@example.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(employee, url) do
    deliver(employee.email, "Confirmation instructions", """

    ==============================

    Hi #{employee.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to reset a employee password.
  """
  def deliver_reset_password_instructions(employee, url) do
    deliver(employee.email, "Reset password instructions", """

    ==============================

    Hi #{employee.email},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update a employee email.
  """
  def deliver_update_email_instructions(employee, url) do
    deliver(employee.email, "Update email instructions", """

    ==============================

    Hi #{employee.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end
end
