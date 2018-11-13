defmodule ExBanking.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      worker(ExBanking.User, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  @spec create_user(user :: String.t()) :: :ok | ExBanking.banking_error
  def create_user(user) when is_binary(user) do
    case Supervisor.start_child(__MODULE__, [user]) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> {:error, :user_already_exists}
    end
  end
  def create_user(_name), do: {:error, :wrong_arguments}

end
