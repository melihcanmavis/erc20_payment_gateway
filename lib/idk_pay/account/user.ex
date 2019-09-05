defmodule IdkPay.Account.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias IdkPay.Account.User

  schema "user" do
    field(:avatar, :string)
    field(:bio, :string)
    field(:email, :string)
    field(:fullname, :string)
    field(:is_active, :boolean, default: true)
    field(:location, :string)
    field(:mobile, :string)
    field(:password, :string, virtual: true)
    field(:repassword, :string, virtual: true)
    field(:password_hash, :string)
    field(:role, :string)
    field(:username, :string)
    field(:is_verified, :boolean, default: false)
    field(:verification_code, :string)
    field(:recovery_code, :string)
    field(:merchant_name, :string)
    field(:mainnet_eth_address, :string)
    field(:testnet_eth_address, :string)
    field(:mainnet_key, :string)
    field(:mainnet_secret, :string)
    field(:testnet_key, :string)
    field(:testnet_secret, :string)
    field(:mainnet_webhook, :string)
    field(:testnet_webhook, :string)
    field(:mainnet_default_success_url, :string)
    field(:testnet_default_success_url, :string)
    field(:mainnet_default_error_url, :string)
    field(:testnet_default_error_url, :string)

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [
      :fullname,
      :username,
      :avatar,
      :role,
      :is_active,
      :email,
      :mobile,
      :bio,
      :location
    ])
    |> validate_required([:fullname, :username, :avatar])
  end

  def registration_changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [
      :fullname,
      :avatar,
      :role,
      :is_active,
      :username,
      :password,
      :repassword,
      :email,
      :mobile,
      :bio,
      :location
    ])
    |> validate_required([:fullname, :username, :password])
    |> validate_length(:username, min: 3, max: 16)
    |> validate_length(:password, min: 5)
    |> validate_password
    |> unique_constraint(:username)
    |> put_password_hash()
    |> put_role("user")
  end

  def admin_changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:fullname, :username, :password, :repassword, :email])
    |> validate_required([:fullname, :username, :password, :email])
    |> validate_length(:username, min: 3, max: 16)
    |> validate_length(:password, min: 5)
    |> validate_password
    |> unique_constraint(:username)
    |> put_password_hash()
    |> put_role("administrator")
    |> put_default_avatar
  end

  def front_registration_changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:email, :username, :password])
    |> validate_required([:email, :username, :password])
    |> validate_length(:username, min: 3, max: 16)
    |> validate_length(:password, min: 5)
    |> validate_username
    |> unique_constraint(:username)
    |> unique_constraint(:email)
    |> put_password_hash()
    |> put_default_avatar()
    |> put_fullname()
    |> put_role("user")

    # |> put_verificationhash()
  end

  def validate_password(changeset) do
    password = get_field(changeset, :password)
    repassword = get_field(changeset, :repassword)

    if password == repassword do
      changeset
    else
      add_error(changeset, :repassword, "Password didn't match")
    end
  end

  def put_default_avatar(changeset) do
    change(changeset, avatar: "/images/default.png")
  end

  def put_verificationhash(changeset) do
    change(changeset, verification_code: Ecto.UUID.generate())
  end

  def put_role(changeset, role) do
    change(changeset, role: role)
  end

  def put_fullname(changeset) do
    uname = get_field(changeset, :username)
    change(changeset, fullname: uname)
  end

  def validate_username(changeset) do
    uname = get_field(changeset, :username)

    if Regex.match?(~r/^[0-9A-Za-z]+$/, uname) do
      changeset
    else
      add_error(changeset, :username, "Username only can consisted of alphanumeric character")
    end
  end

  def put_password_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        change(changeset, password_hash: Comeonin.Bcrypt.hashpwsalt(pass))

      _ ->
        changeset
    end
  end
end
