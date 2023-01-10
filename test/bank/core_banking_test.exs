defmodule Bank.CoreBankingTest do
  use Bank.DataCase

  alias Bank.CoreBanking

  import Bank.CoreBankingFixtures
  alias Bank.CoreBanking.{Customer, CustomerToken}

  describe "get_customer_by_email/1" do
    test "does not return the customer if the email does not exist" do
      refute CoreBanking.get_customer_by_email("unknown@example.com")
    end

    test "returns the customer if the email exists" do
      %{id: id} = customer = customer_fixture()
      assert %Customer{id: ^id} = CoreBanking.get_customer_by_email(customer.email)
    end
  end

  describe "get_customer_by_email_and_password/2" do
    test "does not return the customer if the email does not exist" do
      refute CoreBanking.get_customer_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the customer if the password is not valid" do
      customer = customer_fixture()
      refute CoreBanking.get_customer_by_email_and_password(customer.email, "invalid")
    end

    test "returns the customer if the email and password are valid" do
      %{id: id} = customer = customer_fixture()

      assert %Customer{id: ^id} =
               CoreBanking.get_customer_by_email_and_password(customer.email, valid_customer_password())
    end
  end

  describe "get_customer!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        CoreBanking.get_customer!(-1)
      end
    end

    test "returns the customer with the given id" do
      %{id: id} = customer = customer_fixture()
      assert %Customer{id: ^id} = CoreBanking.get_customer!(customer.id)
    end
  end

  describe "register_customer/1" do
    test "requires email and password to be set" do
      {:error, changeset} = CoreBanking.register_customer(%{})

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} = CoreBanking.register_customer(%{email: "not valid", password: "not valid"})

      assert %{
               email: ["must have the @ sign and no spaces"],
               password: ["should be at least 12 character(s)"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = CoreBanking.register_customer(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      %{email: email} = customer_fixture()
      {:error, changeset} = CoreBanking.register_customer(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = CoreBanking.register_customer(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers customers with a hashed password" do
      email = unique_customer_email()
      {:ok, customer} = CoreBanking.register_customer(valid_customer_attributes(email: email))
      assert customer.email == email
      assert is_binary(customer.hashed_password)
      assert is_nil(customer.confirmed_at)
      assert is_nil(customer.password)
    end
  end

  describe "change_customer_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = CoreBanking.change_customer_registration(%Customer{})
      assert changeset.required == [:password, :email]
    end

    test "allows fields to be set" do
      email = unique_customer_email()
      password = valid_customer_password()

      changeset =
        CoreBanking.change_customer_registration(
          %Customer{},
          valid_customer_attributes(email: email, password: password)
        )

      assert changeset.valid?
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "change_customer_email/2" do
    test "returns a customer changeset" do
      assert %Ecto.Changeset{} = changeset = CoreBanking.change_customer_email(%Customer{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_customer_email/3" do
    setup do
      %{customer: customer_fixture()}
    end

    test "requires email to change", %{customer: customer} do
      {:error, changeset} = CoreBanking.apply_customer_email(customer, valid_customer_password(), %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{customer: customer} do
      {:error, changeset} =
        CoreBanking.apply_customer_email(customer, valid_customer_password(), %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{customer: customer} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        CoreBanking.apply_customer_email(customer, valid_customer_password(), %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{customer: customer} do
      %{email: email} = customer_fixture()

      {:error, changeset} =
        CoreBanking.apply_customer_email(customer, valid_customer_password(), %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{customer: customer} do
      {:error, changeset} =
        CoreBanking.apply_customer_email(customer, "invalid", %{email: unique_customer_email()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the email without persisting it", %{customer: customer} do
      email = unique_customer_email()
      {:ok, customer} = CoreBanking.apply_customer_email(customer, valid_customer_password(), %{email: email})
      assert customer.email == email
      assert CoreBanking.get_customer!(customer.id).email != email
    end
  end

  describe "deliver_update_email_instructions/3" do
    setup do
      %{customer: customer_fixture()}
    end

    test "sends token through notification", %{customer: customer} do
      token =
        extract_customer_token(fn url ->
          CoreBanking.deliver_update_email_instructions(customer, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert customer_token = Repo.get_by(CustomerToken, token: :crypto.hash(:sha256, token))
      assert customer_token.customer_id == customer.id
      assert customer_token.sent_to == customer.email
      assert customer_token.context == "change:current@example.com"
    end
  end

  describe "update_customer_email/2" do
    setup do
      customer = customer_fixture()
      email = unique_customer_email()

      token =
        extract_customer_token(fn url ->
          CoreBanking.deliver_update_email_instructions(%{customer | email: email}, customer.email, url)
        end)

      %{customer: customer, token: token, email: email}
    end

    test "updates the email with a valid token", %{customer: customer, token: token, email: email} do
      assert CoreBanking.update_customer_email(customer, token) == :ok
      changed_customer = Repo.get!(Customer, customer.id)
      assert changed_customer.email != customer.email
      assert changed_customer.email == email
      assert changed_customer.confirmed_at
      assert changed_customer.confirmed_at != customer.confirmed_at
      refute Repo.get_by(CustomerToken, customer_id: customer.id)
    end

    test "does not update email with invalid token", %{customer: customer} do
      assert CoreBanking.update_customer_email(customer, "oops") == :error
      assert Repo.get!(Customer, customer.id).email == customer.email
      assert Repo.get_by(CustomerToken, customer_id: customer.id)
    end

    test "does not update email if customer email changed", %{customer: customer, token: token} do
      assert CoreBanking.update_customer_email(%{customer | email: "current@example.com"}, token) == :error
      assert Repo.get!(Customer, customer.id).email == customer.email
      assert Repo.get_by(CustomerToken, customer_id: customer.id)
    end

    test "does not update email if token expired", %{customer: customer, token: token} do
      {1, nil} = Repo.update_all(CustomerToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert CoreBanking.update_customer_email(customer, token) == :error
      assert Repo.get!(Customer, customer.id).email == customer.email
      assert Repo.get_by(CustomerToken, customer_id: customer.id)
    end
  end

  describe "change_customer_password/2" do
    test "returns a customer changeset" do
      assert %Ecto.Changeset{} = changeset = CoreBanking.change_customer_password(%Customer{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        CoreBanking.change_customer_password(%Customer{}, %{
          "password" => "new valid password"
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_customer_password/3" do
    setup do
      %{customer: customer_fixture()}
    end

    test "validates password", %{customer: customer} do
      {:error, changeset} =
        CoreBanking.update_customer_password(customer, valid_customer_password(), %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{customer: customer} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        CoreBanking.update_customer_password(customer, valid_customer_password(), %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{customer: customer} do
      {:error, changeset} =
        CoreBanking.update_customer_password(customer, "invalid", %{password: valid_customer_password()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{customer: customer} do
      {:ok, customer} =
        CoreBanking.update_customer_password(customer, valid_customer_password(), %{
          password: "new valid password"
        })

      assert is_nil(customer.password)
      assert CoreBanking.get_customer_by_email_and_password(customer.email, "new valid password")
    end

    test "deletes all tokens for the given customer", %{customer: customer} do
      _ = CoreBanking.generate_customer_session_token(customer)

      {:ok, _} =
        CoreBanking.update_customer_password(customer, valid_customer_password(), %{
          password: "new valid password"
        })

      refute Repo.get_by(CustomerToken, customer_id: customer.id)
    end
  end

  describe "generate_customer_session_token/1" do
    setup do
      %{customer: customer_fixture()}
    end

    test "generates a token", %{customer: customer} do
      token = CoreBanking.generate_customer_session_token(customer)
      assert customer_token = Repo.get_by(CustomerToken, token: token)
      assert customer_token.context == "session"

      # Creating the same token for another customer should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%CustomerToken{
          token: customer_token.token,
          customer_id: customer_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_customer_by_session_token/1" do
    setup do
      customer = customer_fixture()
      token = CoreBanking.generate_customer_session_token(customer)
      %{customer: customer, token: token}
    end

    test "returns customer by token", %{customer: customer, token: token} do
      assert session_customer = CoreBanking.get_customer_by_session_token(token)
      assert session_customer.id == customer.id
    end

    test "does not return customer for invalid token" do
      refute CoreBanking.get_customer_by_session_token("oops")
    end

    test "does not return customer for expired token", %{token: token} do
      {1, nil} = Repo.update_all(CustomerToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute CoreBanking.get_customer_by_session_token(token)
    end
  end

  describe "delete_session_token/1" do
    test "deletes the token" do
      customer = customer_fixture()
      token = CoreBanking.generate_customer_session_token(customer)
      assert CoreBanking.delete_session_token(token) == :ok
      refute CoreBanking.get_customer_by_session_token(token)
    end
  end

  describe "deliver_customer_confirmation_instructions/2" do
    setup do
      %{customer: customer_fixture()}
    end

    test "sends token through notification", %{customer: customer} do
      token =
        extract_customer_token(fn url ->
          CoreBanking.deliver_customer_confirmation_instructions(customer, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert customer_token = Repo.get_by(CustomerToken, token: :crypto.hash(:sha256, token))
      assert customer_token.customer_id == customer.id
      assert customer_token.sent_to == customer.email
      assert customer_token.context == "confirm"
    end
  end

  describe "confirm_customer/1" do
    setup do
      customer = customer_fixture()

      token =
        extract_customer_token(fn url ->
          CoreBanking.deliver_customer_confirmation_instructions(customer, url)
        end)

      %{customer: customer, token: token}
    end

    test "confirms the email with a valid token", %{customer: customer, token: token} do
      assert {:ok, confirmed_customer} = CoreBanking.confirm_customer(token)
      assert confirmed_customer.confirmed_at
      assert confirmed_customer.confirmed_at != customer.confirmed_at
      assert Repo.get!(Customer, customer.id).confirmed_at
      refute Repo.get_by(CustomerToken, customer_id: customer.id)
    end

    test "does not confirm with invalid token", %{customer: customer} do
      assert CoreBanking.confirm_customer("oops") == :error
      refute Repo.get!(Customer, customer.id).confirmed_at
      assert Repo.get_by(CustomerToken, customer_id: customer.id)
    end

    test "does not confirm email if token expired", %{customer: customer, token: token} do
      {1, nil} = Repo.update_all(CustomerToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert CoreBanking.confirm_customer(token) == :error
      refute Repo.get!(Customer, customer.id).confirmed_at
      assert Repo.get_by(CustomerToken, customer_id: customer.id)
    end
  end

  describe "deliver_customer_reset_password_instructions/2" do
    setup do
      %{customer: customer_fixture()}
    end

    test "sends token through notification", %{customer: customer} do
      token =
        extract_customer_token(fn url ->
          CoreBanking.deliver_customer_reset_password_instructions(customer, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert customer_token = Repo.get_by(CustomerToken, token: :crypto.hash(:sha256, token))
      assert customer_token.customer_id == customer.id
      assert customer_token.sent_to == customer.email
      assert customer_token.context == "reset_password"
    end
  end

  describe "get_customer_by_reset_password_token/1" do
    setup do
      customer = customer_fixture()

      token =
        extract_customer_token(fn url ->
          CoreBanking.deliver_customer_reset_password_instructions(customer, url)
        end)

      %{customer: customer, token: token}
    end

    test "returns the customer with valid token", %{customer: %{id: id}, token: token} do
      assert %Customer{id: ^id} = CoreBanking.get_customer_by_reset_password_token(token)
      assert Repo.get_by(CustomerToken, customer_id: id)
    end

    test "does not return the customer with invalid token", %{customer: customer} do
      refute CoreBanking.get_customer_by_reset_password_token("oops")
      assert Repo.get_by(CustomerToken, customer_id: customer.id)
    end

    test "does not return the customer if token expired", %{customer: customer, token: token} do
      {1, nil} = Repo.update_all(CustomerToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute CoreBanking.get_customer_by_reset_password_token(token)
      assert Repo.get_by(CustomerToken, customer_id: customer.id)
    end
  end

  describe "reset_customer_password/2" do
    setup do
      %{customer: customer_fixture()}
    end

    test "validates password", %{customer: customer} do
      {:error, changeset} =
        CoreBanking.reset_customer_password(customer, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{customer: customer} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = CoreBanking.reset_customer_password(customer, %{password: too_long})
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{customer: customer} do
      {:ok, updated_customer} = CoreBanking.reset_customer_password(customer, %{password: "new valid password"})
      assert is_nil(updated_customer.password)
      assert CoreBanking.get_customer_by_email_and_password(customer.email, "new valid password")
    end

    test "deletes all tokens for the given customer", %{customer: customer} do
      _ = CoreBanking.generate_customer_session_token(customer)
      {:ok, _} = CoreBanking.reset_customer_password(customer, %{password: "new valid password"})
      refute Repo.get_by(CustomerToken, customer_id: customer.id)
    end
  end

  describe "inspect/2" do
    test "does not include password" do
      refute inspect(%Customer{password: "123456"}) =~ "password: \"123456\""
    end
  end
end
