defmodule Metamorphic.Accounts.UserNotifier do
  import Swoosh.Email

  alias Metamorphic.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"Metamorphic", from_email()})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  defp from_email do
    Metamorphic.config(:mailer_default_from_email)
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(_user, email, url) do
    deliver(email, "Confirmation instructions", """

    ==============================

    Hi #{email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(_user, email, url) do
    deliver(email, "Reset password instructions", """

    ==============================

    Hi #{email},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(_user, email, url) do
    deliver(email, "Update email instructions", """

    ==============================

    Hi #{email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end
end
