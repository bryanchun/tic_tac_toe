defmodule TicTacToeWeb.Components.Board do
  use Surface.LiveComponent

  alias TicTacToeWeb.Components.Square

  # TODO: Fix int/string conversions of the map keys

  data statuses, :map,
    default: for rowIdx <- [1, 2, 3], colIdx <- [1, 2, 3],
      into: %{},
      do: {{ "#{rowIdx}", "#{colIdx}"}, "playing"}

  data pieces, :map,
    default: for rowIdx <- [1, 2, 3], colIdx <- [1, 2, 3],
      into: %{},
      do: {{ "#{rowIdx}", "#{colIdx}" }, nil}

  data whose_turn, :string, default: "X"

  data winner_piece, :string, default: nil

  def render(assigns) do
    ~H"""
    <div class="container">
      <div class="board container-col">
        <div class="board-row" :for={{ row_idx <- [1, 2, 3] }}>
          <span :for={{ col_idx <- [1, 2, 3] }}>
            <Square
              piece={{ @pieces |> Map.get({ "#{row_idx}", "#{col_idx}" }) }}
              status={{ Map.get(@statuses, { "#{row_idx}", "#{col_idx}" }) }}
              click="move"
              loc_x={{ "#{row_idx}" }}
              loc_y={{ "#{col_idx}" }}
            />
          </span>
        </div>
      </div>
      <div class="container-col">
        {{ next_instruction(@whose_turn, @winner_piece) }}
      </div>
    </div>
    """
  end

  defp next_instruction(whose_turn, nil), do: "Next player: #{next_turn(whose_turn)}"
  defp next_instruction(_whose_turn, winner_piece) when winner_piece in ["O", "X"], do: "Winner: #{winner_piece}"
  defp next_instruction(_whose_turn, " "), do: "Draw"

  defp next_turn("X"), do: "O"
  defp next_turn("O"), do: "X"

  def handle_event(
    "move",
    %{"status" => "playing", "piece" => nil,
      "loc_x" => loc_x, "loc_y" => loc_y},
    socket
  ) do
    IO.puts("Moved { #{loc_x}, #{loc_y} }")

    socket =
      socket
      |> update(:pieces, & Map.put(
        &1, { loc_x, loc_y }, socket.assigns[:whose_turn]
      ))
      |> update(:whose_turn, &
        next_turn(&1)
      )

    # Evaluate :winner_piece and :statuses

    {:noreply, socket}
  end

  def handle_event("move", %{"status" => "won"}, socket),       do: {:noreply, socket}
  def handle_event("move", %{"status" => "disabled"}, socket),  do: {:noreply, socket}
end
