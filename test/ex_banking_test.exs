defmodule ExBankingTest do
  use ExUnit.Case
  doctest ExBanking

  test "ex_banking" do
    user1 = "user #1"
    assert ExBanking.create_user(user1) == :ok
    assert ExBanking.create_user(123) == {:error, :wrong_arguments}
    assert ExBanking.create_user(user1) == {:error, :user_already_exists}

    user2 = "user #2"
    assert ExBanking.create_user(user2) == :ok
    assert ExBanking.create_user(user2) == {:error, :user_already_exists}

    assert ExBanking.get_balance(user1, "USD") == {:ok, 0}, "current balance should be 0"

    assert ExBanking.deposit(user1, 10, "USD") == {:ok, 10}
    assert ExBanking.deposit(user1, 10, "USD") == {:ok, 20}

    assert ExBanking.get_balance(user1, "USD") == {:ok, 20}

    assert ExBanking.withdraw(user1, 5, "USD") == {:ok, 15}
    assert ExBanking.get_balance(user1, "USD") == {:ok, 15}

    assert ExBanking.send(user1, user2, 3, "USD") == {:ok, 12, 3}
    assert ExBanking.get_balance(user1, "USD") == {:ok, 12}
    assert ExBanking.get_balance(user2, "USD") == {:ok, 3}
  end
end
