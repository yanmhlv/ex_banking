defmodule ExBanking.User do
    use GenServer

    def start_link(user), do: GenServer.start_link(__MODULE__, nil, name: via_registry(user))

    def via_registry(user), do: {:via, Registry, {ExBanking.Registry, user}}

    def init(_), do: {:ok, %{}}

    @spec get_pid(user :: String.t) :: {:ok, pid :: pid()} | {:error}
    def get_pid(user) when is_binary(user) do
        case Registry.lookup(ExBanking.Registry, user) do
            [{pid, _}] ->
                if check_rate(pid) do
                    {:ok, pid}
                else
                    {:error, :too_many_requests_to_user}
                end
            [] -> {:error, :user_does_not_exist}
        end
    end

    @spec check_rate(pid :: pid()) :: boolean
    defp check_rate(pid) when is_pid(pid) do
        {:message_queue_len, n} = Process.info(pid, :message_queue_len)
        n < 10
    end

    @spec get_balance(user :: String.t, currency :: String.t) :: {:ok, balance :: number} | ExBanking.banking_error
    def get_balance(user, currency) when is_binary(user) and is_binary(currency) do
        case get_pid(user) do
            {:ok, pid} -> GenServer.call(pid, {:get_balance, currency})
            err -> err
        end
    end
    def get_balance(_, _), do: {:error, :wrong_arguments}

    @spec deposit(user :: String.t, amount :: number, currency :: String.t) :: {:ok, new_balance :: number} | ExBanking.banking_error
    def deposit(user, amount, currency) when is_binary(user) and is_number(amount) and is_binary(currency) and amount > 0 do
        case get_pid(user) do
            {:ok, pid} -> GenServer.call(pid, {:deposit, amount, currency})
            err -> err
        end
    end
    def deposit(_user, _amount, _currency), do: {:error, :wrong_arguments}

    @spec withdraw(user :: String.t, amount :: number, currency :: String.t) :: {:ok, new_balance :: number} | ExBanking.banking_error
    def withdraw(user, amount, currency) when is_binary(user) and is_number(amount) and is_binary(currency) do
        case get_pid(user) do
            {:ok, pid} -> GenServer.call(pid, {:withdraw, amount, currency})
            err -> err
        end
    end
    def withdraw(_user, _amount, _currency), do: {:error, :wrong_arguments}

    @spec send(from_user :: String.t, to_user :: String.t, amount :: number, currency :: String.t) :: {:ok, from_user_balance :: number, to_user_balance :: number} | ExBanking.banking_error
    def send(from_user, to_user, amount, currency) when is_binary(from_user) and is_binary(to_user) and is_number(amount) and is_binary(currency) and amount > 0 do
        case get_pid(from_user) do
            {:ok, from_pid} ->
                case get_pid(to_user) do
                    {:ok, to_pid} ->
                        case GenServer.call(from_pid, {:withdraw, amount, currency}) do
                            {:ok, from_user_balance} ->
                                case GenServer.call(to_pid, {:deposit, amount, currency}) do
                                    {:ok, to_user_balance} -> {:ok, from_user_balance, to_user_balance}
                                    err -> err
                                end
                            err -> err
                        end
                    {:error, :user_does_not_exist} -> {:error, :receiver_does_not_exist}
                    err -> err
                end
            {:error, :user_does_not_exist} -> {:error, :sender_does_not_exist}
            err -> err
        end
    end
    def send(_from_user, _to_user, _amount, _currency), do: {:error, :wrong_arguments}


    def handle_call({:get_balance, currency}, _from, state) do
        balance = Map.get(state, currency, 0.0)
        {:reply, {:ok, balance}, state}
    end

    def handle_call({:deposit, amount, currency}, _from, state) do
        balance = Map.get(state, currency, 0.0)
        new_balance = balance + amount
        new_state = Map.put(state, currency, new_balance)

        {:reply, {:ok, new_balance}, new_state}
    end

    def handle_call({:withdraw, amount, currency}, _from, state) do
        balance = Map.get(state, currency, 0.0)
        new_balance = balance - amount

        if new_balance >= 0 do
            new_state = Map.put(state, currency, new_balance)
            {:reply, {:ok, new_balance}, new_state}
        else
            {:reply, {:error, :not_enough_money}, state}
        end
    end
end
