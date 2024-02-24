defmodule TaskManager.Cli do

  @moduledoc """
  Command Line Interface for Task Management System

  This module provides a command line interface (CLI) for interacting with
  a Task Management System. It allows users to view, add, edit, and delete tasks.

  ## Usage

  1. Start the CLI by calling `TaskManager.Cli.start`.
  2. The CLI will display a menu with options to view, add, edit, or delete tasks.
  3. Follow the prompts to perform the desired action.

  ## Example
  iex -S mix
  TaskManager.Cli.start
  """
  alias TaskManager.Tasks
  alias TableRex.Table


  def start() do
    loop()
  end


  def loop() do
    display_menu()
    handle_input()
    loop()
  end


  def continue() do
    IO.puts("\nPress Enter to continue...")
    IO.gets("")
  end


  def display_menu() do
    IO.puts """


    =========== TaskWiz ============
    === A Task Management System ===

    1. View All Tasks
    2. Add a Task
    3. Edit a Task
    4. Delete a Task
    5. EXIT
    """
  end


  def handle_input() do
    IO.puts "Enter your choice: "
    input = IO.gets("") |> String.trim()
    pick_task(input)
  end


  def pick_task("1") do
    view_all_tasks()
    continue()
  end
  def pick_task("2"), do: add_task()
  def pick_task("3"), do: edit_task()
  def pick_task("4"), do: delete_task()
  def pick_task("5"), do: exit_program()
  def pick_task(_), do: IO.puts("\nERROR! Wrong input. Please try again.")


  defp display_task(%TaskManager.Tasks.Task{id: id, title: title, status: status,
  description: description, due_date: due_date}) do
    [id, title, status, description, due_date]
  end


  def view_all_tasks() do
    if Enum.empty?(Tasks.list_tasks()) do
      IO.puts("No tasks available.")
    else
      IO.puts("\n\n=== MY TASKS ===\n")

      header = ["ID", "Title", "Status", "Description", "Due Date"]
      rows = Tasks.list_tasks()
             |> Enum.map(&display_task/1)

      Table.new(rows, header)
      |> Table.render!(horizontal_style: :all, top_frame_symbol: "+", header_separator_symbol: "=", horizontal_symbol: "-", vertical_symbol: "|")
      |> IO.puts
    end
  end


  def add_task() do
    IO.puts("\n\n===== ADD A TASK =====\n")
    task_params = get_task_params()
    case Tasks.create_task(task_params) do
      {:ok, _} -> IO.puts("\nTask added successfully.")
      {:error, changeset} -> IO.puts("\nFailed to add task: #{inspect(changeset.errors)}")
    end
    continue()
  end


  defp get_task_params() do
    IO.puts "\nEnter Title: "
    title = IO.gets("") |> String.trim()

    IO.puts "\nEnter Description: "
    description = IO.gets("") |> String.trim()

    due_date = get_due_date()

    %{title: title, status: "Not Started", description: description, due_date: due_date}
  end


  defp get_due_date() do
    IO.puts "\nEnter Due Date (YYYY-MM-DD): "
    today = Date.utc_today()
    due_date = IO.gets("") |> String.trim()

    case Date.from_iso8601(due_date) do
      {:ok, entered_date} ->
        if Date.compare(entered_date, today) >= 0 do
          due_date
        else
          IO.puts "\nDue date must be today or in the future."
          get_due_date()  # Recursively call the function again
        end

      _ ->
        IO.puts "\nInvalid date format. Please enter the date in the format YYYY-MM-DD."
        get_due_date()  # Recursively call the function again
    end
  end


  def edit_task() do
    IO.puts("""

    ====== EDIT A TASK =======
    Which do you want to edit?

    1. Edit a Title
    2. Edit a Status
    3. Edit a Description
    4. Edit a Due Date
    5. Back to main menu
    """)

    IO.puts "Enter your choice: "
    input = IO.gets("") |> String.trim()

    pick_edit(input)
  end


  def pick_edit("1"), do: edit_task_field(:title)
  def pick_edit("2"), do: edit_task_field(:status)
  def pick_edit("3"), do: edit_task_field(:description)
  def pick_edit("4"), do: edit_task_field(:due_date)
  def pick_edit("5"), do: loop()
  def pick_edit(_), do: IO.puts("\nERROR! Wrong input. Please try again.")


  def edit_task_field(field) do
    view_all_tasks()
    IO.puts("\nEnter ID of task to edit: ")
    id = IO.gets("") |> String.trim()
    task = Tasks.get_task!(id)
    new_value = get_new_value(field)
    attrs = Map.put(%{}, field, new_value)

    case Tasks.update_task(task, attrs) do
      {:ok, _} -> IO.puts("\n#{String.capitalize(to_string(field))} updated successfully.")
      {:error, changeset} -> IO.puts("\nFailed to update task: #{inspect(changeset.errors)}")
    end
    continue()
  end


  defp get_new_value(:title), do: get_input("\nEnter NEW title: ")
  defp get_new_value(:description), do: get_input("\nEnter NEW description: ")
  defp get_new_value(:due_date) do
    IO.puts "\nEnter NEW Due Date (YYYY-MM-DD): "
    today = Date.utc_today()
    new_due_date = IO.gets("") |> String.trim()

    case Date.from_iso8601(new_due_date) do
      {:ok, entered_date} ->
        if Date.compare(entered_date, today) >= 0 do
          new_due_date
        else
          IO.puts "\nDue date must be today or in the future."
          get_new_value(:due_date)  # Recursively call the function again
        end

      _ ->
        IO.puts "\nInvalid date format. Please enter the date in the format YYYY-MM-DD."
        get_new_value(:due_date)  # Recursively call the function again
    end
  end


  defp get_new_value(:status) do
    IO.puts("""

    Select a NEW status:

    0 - "Not Started"
    1 - "In Progress"
    2 - "Done"

    """)
    get_input("Enter NEW status: ")
    |> status()

  end


  defp status("0"), do: "Not Started"
  defp status("1"), do: "In Progress"
  defp status("2"), do: "Done"
  defp status(_), do: "Not Started"


  defp get_input(prompt) do
    IO.puts(prompt)
    IO.gets("") |> String.trim()
  end


  def delete_task() do
    view_all_tasks()
    IO.puts("\n\n===== DELETE A TASK =====\n")
    IO.puts("\nEnter ID of task to delete: ")
    id = IO.gets("") |> String.trim()
    task = Tasks.get_task!(id)

    case Tasks.delete_task(task) do
      {:ok, _} -> IO.puts("\nTask deleted successfully.")
      {:error, changeset} -> IO.puts("\nFailed to delete task: #{inspect(changeset.errors)}")
    end
    continue()
  end


  def exit_program() do
    IO.puts "\nExiting..."
    System.halt(0)
  end


end
