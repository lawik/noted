defmodule Noted.Telegram.BotPollerTest do
  use ExUnit.Case, async: true

  defmodule TestTelegramEmpty do
    def get_me(key) do
      Phoenix.PubSub.broadcast!(Noted.PubSub, "test-telegram:#{key}", :get_me)
      {:ok, %{"id" => 101, "username" => "test_bot"}}
    end

    def get_updates(key, params) do
      Phoenix.PubSub.broadcast!(Noted.PubSub, "test-telegram:#{key}", {:get_updates, params})
      updates = []
      {:ok, updates}
    end
  end

  defmodule TestTelegramSingle do
    @update_id 677_244_601
    def get_me(key) do
      Phoenix.PubSub.broadcast!(Noted.PubSub, "test-telegram:#{key}", :get_me)
      {:ok, %{"id" => 102, "username" => "test_bot"}}
    end

    def get_updates(key, params) do
      Phoenix.PubSub.broadcast!(Noted.PubSub, "test-telegram:#{key}", {:get_updates, params})

      last_seen = Keyword.get(params, :offset)
      updates = if last_seen > @update_id do
        []
      else
        [
          %{
            "from" => %{
              "username" => "test_bot"
            },
            "message_id" => 1,
            "text" => "hey what's up",
            "update_id" => @update_id
          }
        ]
      end

      {:ok, updates}
    end
  end

  defmodule TestTelegramMultiple do
    @starting_id 677_244_601
    @count 3
    def get_me(key) do
      Phoenix.PubSub.broadcast!(Noted.PubSub, "test-telegram:#{key}", :get_me)
      {:ok, %{"id" => 103, "username" => "test_bot"}}
    end

    def get_updates(key, params) do
      Phoenix.PubSub.broadcast!(Noted.PubSub, "test-telegram:#{key}", {:get_updates, params})
      {offset, _} = Keyword.pop(params, :offset)

      if offset < @starting_id + @count do
        update = [
          %{
            "from" => %{
              "username" => "test_bot"
            },
            "message_id" => nil,
            "text" => "hey what's up",
            "update_id" => @starting_id
          }
        ]

        updates =
          update
          |> List.duplicate(@count)
          |> List.flatten()
          |> Enum.with_index()
          |> Enum.map(fn {update, index} ->
            update
            |> Map.put("message_id", System.unique_integer([:positive, :monotonic]))
            |> Map.put("update_id", @starting_id + index)
          end)

        {:ok, updates}
      else
        {:ok, []}
      end
    end
  end

  test "get multiple updates with poller" do
    key = "multi"
    state_id = 103
    Phoenix.PubSub.subscribe(Noted.PubSub, "test-telegram:#{key}")
    Phoenix.PubSub.subscribe(Noted.PubSub, "telegram_bot_update:#{state_id}")


    assert {:ok, pid} =
             Noted.Telegram.BotPoller.start_link(
               bot_key: key,
               telegram_module: TestTelegramMultiple
             )

    assert_receive :get_me
    assert_receive {:get_updates, [offset: -1, timeout: 30]}
    last_seen = Enum.reduce(1..3, 0, fn _count, last_seen ->
      assert_receive {:update,
                    %{
                      "from" => %{"username" => "test_bot"},
                      "message_id" => _,
                      "text" => "hey what's up",
                      "update_id" => update_id
                    }}
      if last_seen > 0 do
        assert update_id > last_seen
        assert update_id == last_seen + 1
      end
      update_id
    end) + 1
    assert_receive {:get_updates, [offset: ^last_seen, timeout: 30]}
    refute_received {:update, _}
    GenServer.stop(pid, :normal)
  end

  test "get single update with poller" do
    key = "single"
    state_id = 102
    Phoenix.PubSub.subscribe(Noted.PubSub, "test-telegram:#{key}")
    Phoenix.PubSub.subscribe(Noted.PubSub, "telegram_bot_update:#{state_id}")

    assert {:ok, pid} =
             Noted.Telegram.BotPoller.start_link(
               bot_key: key,
               telegram_module: TestTelegramSingle
             )

    assert_receive :get_me

    assert_receive {:get_updates, [offset: -1, timeout: 30]}
    assert_receive {:update,
                    %{
                      "from" => %{"username" => "test_bot"},
                      "message_id" => 1,
                      "text" => "hey what's up",
                      "update_id" => 677_244_601 = update_id
                    }}
    last_seen = update_id + 1
    assert_receive {:get_updates, [offset: ^last_seen, timeout: 30]}
    refute_received {:update, _}
    GenServer.stop(pid, :normal)
  end

  test "get empty with poller" do
    key = System.unique_integer() |> Integer.to_string()
    state_id = 101
    Phoenix.PubSub.subscribe(Noted.PubSub, "test-telegram:#{key}")
    Phoenix.PubSub.subscribe(Noted.PubSub, "telegram_bot_update:#{state_id}")

    assert {:ok, pid} =
             Noted.Telegram.BotPoller.start_link(bot_key: key, telegram_module: TestTelegramEmpty)

    assert_received :get_me
    # Keeps getting updates, keeps producing no updates
    assert_receive {:get_updates, [offset: -1, timeout: 30]}
    refute_received {:update, _}
    assert_receive {:get_updates, [offset: -1, timeout: 30]}

    GenServer.stop(pid, :normal)
  end
end
