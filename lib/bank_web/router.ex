defmodule BankWeb.Router do
  # alias BankWeb.EmployeeSessionController
  use BankWeb, :router

  import BankWeb.CustomerAuth

  import BankWeb.EmployeeAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {BankWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_customer
    plug :fetch_current_employee
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BankWeb do
    pipe_through :browser

    get "/", PageController, :index
    resources "/enrolments", EnrolmentController

    get "/leads/new", LeadController, :new
    post "/leads", LeadController, :create
    get "/leads/thanks", LeadController, :thanks



  end

  scope "/", BankWeb do
    pipe_through [:browser, :require_authenticated_employee]

    get "/admin", EmployeeSessionController, :admin
    get "/leads", LeadController, :index
    get "/accounts/:id", AccountController, :create
    get "/accounts/gen_acc_num/:name", AccountController, :gen_acc_num
    get "/admin/cust_acc", EmployeeSessionController, :get_cust_acc
    get "/admin/all_customers", EmployeeSessionController, :get_all_customers
    get "/admin/all_accounts", EmployeeSessionController, :get_all_accounts
  end

  scope "/", BankWeb do
    pipe_through [:browser, :require_authenticated_customer]

    get "/account/home", AccountController, :accounthome
    get "/account/statement", AccountController, :statement

    get "/transaction", TransactionController, :index
    get "/transaction/new", TransactionController, :new
    post "/transaction", TransactionController, :create
    get "/transaction/:id", TransactionController, :show

  end

  # Other scopes may use custom stacks.
  # scope "/api", BankWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BankWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", BankWeb do
    pipe_through [:browser, :redirect_if_employee_is_authenticated]

    get "/employees/register", EmployeeRegistrationController, :new
    post "/employees/register", EmployeeRegistrationController, :create
    get "/employees/log_in", EmployeeSessionController, :new
    post "/employees/log_in", EmployeeSessionController, :create
    get "/employees/reset_password", EmployeeResetPasswordController, :new
    post "/employees/reset_password", EmployeeResetPasswordController, :create
    get "/employees/reset_password/:token", EmployeeResetPasswordController, :edit
    put "/employees/reset_password/:token", EmployeeResetPasswordController, :update
  end

  scope "/", BankWeb do
    pipe_through [:browser, :require_authenticated_employee]

    get "/employees/settings", EmployeeSettingsController, :edit
    put "/employees/settings", EmployeeSettingsController, :update
    get "/employees/settings/confirm_email/:token", EmployeeSettingsController, :confirm_email
  end

  scope "/", BankWeb do
    pipe_through [:browser]

    delete "/employees/log_out", EmployeeSessionController, :delete
    get "/employees/confirm", EmployeeConfirmationController, :new
    post "/employees/confirm", EmployeeConfirmationController, :create
    get "/employees/confirm/:token", EmployeeConfirmationController, :edit
    post "/employees/confirm/:token", EmployeeConfirmationController, :update
  end

  ## Authentication routes

  scope "/", BankWeb do
    pipe_through [:browser, :redirect_if_customer_is_authenticated]

    get "/customers/register", CustomerRegistrationController, :new
    post "/customers/register", CustomerRegistrationController, :create
    get "/customers/log_in", CustomerSessionController, :new
    post "/customers/log_in", CustomerSessionController, :create
    get "/customers/reset_password", CustomerResetPasswordController, :new
    post "/customers/reset_password", CustomerResetPasswordController, :create
    get "/customers/reset_password/:token", CustomerResetPasswordController, :edit
    put "/customers/reset_password/:token", CustomerResetPasswordController, :update

  end

  scope "/", BankWeb do
    pipe_through [:browser, :require_authenticated_customer]

    get "/customers/settings", CustomerSettingsController, :edit
    put "/customers/settings", CustomerSettingsController, :update
    get "/customers/settings/confirm_email/:token", CustomerSettingsController, :confirm_email


  end

  scope "/", BankWeb do
    pipe_through [:browser]

    delete "/customers/log_out", CustomerSessionController, :delete
    get "/customers/confirm", CustomerConfirmationController, :new
    post "/customers/confirm", CustomerConfirmationController, :create
    get "/customers/confirm/:token", CustomerConfirmationController, :edit
    post "/customers/confirm/:token", CustomerConfirmationController, :update

  end
end
