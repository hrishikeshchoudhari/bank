defmodule Bank.CoreBanking do
  @moduledoc """
  The CoreBanking context.
  """

  import Ecto.Query, warn: false
  alias Bank.Repo

  alias Bank.Marketing.Lead
  alias Bank.CoreBanking.{Account, Customer, CustomerNotifier, CustomerToken, Transaction}

  ## Database getters

  @doc """
  Gets a customer by email.

  ## Examples

      iex> get_customer_by_email("foo@example.com")
      %Customer{}

      iex> get_customer_by_email("unknown@example.com")
      nil

  """
  def get_customer_by_email(email) when is_binary(email) do
    Repo.get_by(Customer, email: email)
  end

  @doc """
  Gets a customer by email and password.

  ## Examples

      iex> get_customer_by_email_and_password("foo@example.com", "correct_password")
      %Customer{}

      iex> get_customer_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_customer_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    customer = Repo.get_by(Customer, email: email)
    if Customer.valid_password?(customer, password), do: customer
  end

  @doc """
  Gets a single customer.

  Raises `Ecto.NoResultsError` if the Customer does not exist.

  ## Examples

      iex> get_customer!(123)
      %Customer{}

      iex> get_customer!(456)
      ** (Ecto.NoResultsError)

  """
  def get_customer!(id), do: Repo.get!(Customer, id)

  ## Customer registration

  @doc """
  Registers a customer.

  ## Examples

      iex> register_customer(%{field: value})
      {:ok, %Customer{}}

      iex> register_customer(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_customer(attrs) do
    %Customer{}
    |> Customer.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking customer changes.

  ## Examples

      iex> change_customer_registration(customer)
      %Ecto.Changeset{data: %Customer{}}

  """
  def change_customer_registration(%Customer{} = customer, attrs \\ %{}) do
    Customer.registration_changeset(customer, attrs, hash_password: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the customer email.

  ## Examples

      iex> change_customer_email(customer)
      %Ecto.Changeset{data: %Customer{}}

  """
  def change_customer_email(customer, attrs \\ %{}) do
    Customer.email_changeset(customer, attrs)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_customer_email(customer, "valid password", %{email: ...})
      {:ok, %Customer{}}

      iex> apply_customer_email(customer, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_customer_email(customer, password, attrs) do
    customer
    |> Customer.email_changeset(attrs)
    |> Customer.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the customer email using the given token.

  If the token matches, the customer email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_customer_email(customer, token) do
    context = "change:#{customer.email}"

    with {:ok, query} <- CustomerToken.verify_change_email_token_query(token, context),
         %CustomerToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(customer_email_multi(customer, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp customer_email_multi(customer, email, context) do
    changeset =
      customer
      |> Customer.email_changeset(%{email: email})
      |> Customer.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:customer, changeset)
    |> Ecto.Multi.delete_all(:tokens, CustomerToken.customer_and_contexts_query(customer, [context]))
  end

  @doc """
  Delivers the update email instructions to the given customer.

  ## Examples

      iex> deliver_update_email_instructions(customer, current_email, &Routes.customer_update_email_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_update_email_instructions(%Customer{} = customer, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, customer_token} = CustomerToken.build_email_token(customer, "change:#{current_email}")

    Repo.insert!(customer_token)
    CustomerNotifier.deliver_update_email_instructions(customer, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the customer password.

  ## Examples

      iex> change_customer_password(customer)
      %Ecto.Changeset{data: %Customer{}}

  """
  def change_customer_password(customer, attrs \\ %{}) do
    Customer.password_changeset(customer, attrs, hash_password: false)
  end

  @doc """
  Updates the customer password.

  ## Examples

      iex> update_customer_password(customer, "valid password", %{password: ...})
      {:ok, %Customer{}}

      iex> update_customer_password(customer, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_customer_password(customer, password, attrs) do
    changeset =
      customer
      |> Customer.password_changeset(attrs)
      |> Customer.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:customer, changeset)
    |> Ecto.Multi.delete_all(:tokens, CustomerToken.customer_and_contexts_query(customer, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{customer: customer}} -> {:ok, customer}
      {:error, :customer, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_customer_session_token(customer) do
    {token, customer_token} = CustomerToken.build_session_token(customer)
    Repo.insert!(customer_token)
    token
  end

  @doc """
  Gets the customer with the given signed token.
  """
  def get_customer_by_session_token(token) do
    {:ok, query} = CustomerToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_session_token(token) do
    Repo.delete_all(CustomerToken.token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc """
  Delivers the confirmation email instructions to the given customer.

  ## Examples

      iex> deliver_customer_confirmation_instructions(customer, &Routes.customer_confirmation_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_customer_confirmation_instructions(confirmed_customer, &Routes.customer_confirmation_url(conn, :edit, &1))
      {:error, :already_confirmed}

  """
  def deliver_customer_confirmation_instructions(%Customer{} = customer, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if customer.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, customer_token} = CustomerToken.build_email_token(customer, "confirm")
      Repo.insert!(customer_token)
      CustomerNotifier.deliver_confirmation_instructions(customer, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a customer by the given token.

  If the token matches, the customer account is marked as confirmed
  and the token is deleted.
  """
  def confirm_customer(token) do
    with {:ok, query} <- CustomerToken.verify_email_token_query(token, "confirm"),
         %Customer{} = customer <- Repo.one(query),
         {:ok, %{customer: customer}} <- Repo.transaction(confirm_customer_multi(customer)) do
      {:ok, customer}
    else
      _ -> :error
    end
  end

  defp confirm_customer_multi(customer) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:customer, Customer.confirm_changeset(customer))
    |> Ecto.Multi.delete_all(:tokens, CustomerToken.customer_and_contexts_query(customer, ["confirm"]))
  end

  ## Reset password

  @doc """
  Delivers the reset password email to the given customer.

  ## Examples

      iex> deliver_customer_reset_password_instructions(customer, &Routes.customer_reset_password_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_customer_reset_password_instructions(%Customer{} = customer, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, customer_token} = CustomerToken.build_email_token(customer, "reset_password")
    Repo.insert!(customer_token)
    CustomerNotifier.deliver_reset_password_instructions(customer, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the customer by reset password token.

  ## Examples

      iex> get_customer_by_reset_password_token("validtoken")
      %Customer{}

      iex> get_customer_by_reset_password_token("invalidtoken")
      nil

  """
  def get_customer_by_reset_password_token(token) do
    with {:ok, query} <- CustomerToken.verify_email_token_query(token, "reset_password"),
         %Customer{} = customer <- Repo.one(query) do
      customer
    else
      _ -> nil
    end
  end

  @doc """
  Resets the customer password.

  ## Examples

      iex> reset_customer_password(customer, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %Customer{}}

      iex> reset_customer_password(customer, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_customer_password(customer, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:customer, Customer.password_changeset(customer, attrs))
    |> Ecto.Multi.delete_all(:tokens, CustomerToken.customer_and_contexts_query(customer, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{customer: customer}} -> {:ok, customer}
      {:error, :customer, changeset, _} -> {:error, changeset}
    end
  end




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

  def get_acc_by_name(name) do
    Repo.get_by!(Account, [fname: name])
  end

  def list_transaction_for_an_account(params) do
    query = from t in "transactions",
            where: t.src_acn == ^params.acn
    Repo.all(query)
  end
end
