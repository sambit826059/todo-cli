#!/bin/bash

# Configuration
TODO_FILE="$HOME/.todo_list"
DONE_FILE="$HOME/.todo_done"

# Create files if they don't exist
touch "$TODO_FILE"
touch "$DONE_FILE"

# ASCII Art function for todo list
show_ascii_art() {
  echo -e "\e[36m" # Cyan color
  echo "  _________________ "
  echo " /                /|"
  echo "/________________/ |"
  echo "|    _______    | |"
  echo "|   |__✓__|_|   | |"
  echo "|   |__✓__|_|   | |"
  echo "|   |_____|_|   | |"
  echo "|   |_____|_|   | |"
  echo "|   |_____|_|   | |"
  echo "|                | /"
  echo "|________________|/ "
  echo -e "\e[0m" # Reset color
}

# Help function
show_help() {
  show_ascii_art
  echo "Todo List Manager"
  echo "Usage: todo [OPTION]"
  echo ""
  echo "Options:"
  echo "  add TEXT       Add a new task"
  echo "  list           List all tasks"
  echo "  done N         Mark task N as done"
  echo "  remove N       Remove task N without marking as done"
  echo "  clear          Remove all tasks"
  echo "  history        Show completed tasks"
  echo "  clean-history  Clear history of completed tasks"
  echo "  priority N P   Set priority for task N (P=high|medium|low)"
  echo "  help           Display this help message"
  echo ""
  echo "Example: todo add 'Buy groceries'"
}

# List all tasks with numbers
list_tasks() {
  if [ ! -s "$TODO_FILE" ]; then
    echo "No tasks. Add one with 'todo add TASK'."
    return
  fi

  echo "Your tasks:"
  local count=1
  while IFS= read -r line; do
    # Extract priority if it exists
    if [[ "$line" =~ ^PRIORITY:([^:]+):(.*)$ ]]; then
      priority="${BASH_REMATCH[1]}"
      task="${BASH_REMATCH[2]}"

      # Add color based on priority
      case "$priority" in
      "high")
        echo -e "  \e[1;31m$count. $task \e[0m[\e[1;31mHIGH\e[0m]"
        ;;
      "medium")
        echo -e "  \e[1;33m$count. $task \e[0m[\e[1;33mMEDIUM\e[0m]"
        ;;
      "low")
        echo -e "  \e[1;32m$count. $task \e[0m[\e[1;32mLOW\e[0m]"
        ;;
      esac
    else
      echo "  $count. $line"
    fi
    ((count++))
  done <"$TODO_FILE"
}

# Add a new task
add_task() {
  echo "$1" >>"$TODO_FILE"
  echo "Task added: $1"
}

# Mark a task as done
mark_done() {
  if [ ! -s "$TODO_FILE" ]; then
    echo "No tasks to mark as done."
    return
  fi

  local task_number=$1
  local count=1
  local removed=false
  local task_content=""

  # Create a temporary file
  local temp_file=$(mktemp)

  while IFS= read -r line; do
    if [ $count -eq $task_number ]; then
      # Extract the actual task text removing priority if it exists
      if [[ "$line" =~ ^PRIORITY:([^:]+):(.*)$ ]]; then
        task_content="${BASH_REMATCH[2]}"
      else
        task_content="$line"
      fi

      # Add to done file with timestamp
      echo "$(date '+%Y-%m-%d %H:%M:%S') - $task_content" >>"$DONE_FILE"
      echo "Task marked as done: $task_content"
      removed=true
    else
      echo "$line" >>"$temp_file"
    fi
    ((count++))
  done <"$TODO_FILE"

  # Replace original file with temp file
  mv "$temp_file" "$TODO_FILE"

  if [ "$removed" = false ]; then
    echo "Task number $task_number not found."
  fi
}

# Remove a task without marking as done
remove_task() {
  if [ ! -s "$TODO_FILE" ]; then
    echo "No tasks to remove."
    return
  fi

  local task_number=$1
  local count=1
  local removed=false

  # Create a temporary file
  local temp_file=$(mktemp)

  while IFS= read -r line; do
    if [ $count -eq $task_number ]; then
      echo "Task removed: $line"
      removed=true
    else
      echo "$line" >>"$temp_file"
    fi
    ((count++))
  done <"$TODO_FILE"

  # Replace original file with temp file
  mv "$temp_file" "$TODO_FILE"

  if [ "$removed" = false ]; then
    echo "Task number $task_number not found."
  fi
}

# Set priority for a task
set_priority() {
  local task_number=$1
  local priority=$2

  # Validate priority
  if [[ ! "$priority" =~ ^(high|medium|low)$ ]]; then
    echo "Invalid priority. Use 'high', 'medium', or 'low'."
    return
  fi

  if [ ! -s "$TODO_FILE" ]; then
    echo "No tasks to set priority."
    return
  fi

  local count=1
  local modified=false

  # Create a temporary file
  local temp_file=$(mktemp)

  while IFS= read -r line; do
    if [ $count -eq $task_number ]; then
      # Extract the actual task text removing priority if it exists
      if [[ "$line" =~ ^PRIORITY:([^:]+):(.*)$ ]]; then
        task_content="${BASH_REMATCH[2]}"
      else
        task_content="$line"
      fi

      echo "PRIORITY:$priority:$task_content" >>"$temp_file"
      echo "Priority set to $priority for: $task_content"
      modified=true
    else
      echo "$line" >>"$temp_file"
    fi
    ((count++))
  done <"$TODO_FILE"

  # Replace original file with temp file
  mv "$temp_file" "$TODO_FILE"

  if [ "$modified" = false ]; then
    echo "Task number $task_number not found."
  fi
}

# Show completed tasks
show_history() {
  if [ ! -s "$DONE_FILE" ]; then
    echo "No completed tasks in history."
    return
  fi

  echo "Completed tasks:"
  cat "$DONE_FILE" | nl -w2 -s". "
}

# Clear all tasks
clear_tasks() {
  if [ ! -s "$TODO_FILE" ]; then
    echo "No tasks to clear."
    return
  fi

  read -p "Are you sure you want to clear all tasks? (y/n): " choice
  case "$choice" in
  y | Y)
    >"$TODO_FILE"
    echo "All tasks cleared."
    ;;
  *)
    echo "Operation cancelled."
    ;;
  esac
}

# Clear history of completed tasks
clear_history() {
  if [ ! -s "$DONE_FILE" ]; then
    echo "No history to clear."
    return
  fi

  read -p "Are you sure you want to clear all completed tasks history? (y/n): " choice
  case "$choice" in
  y | Y)
    >"$DONE_FILE"
    echo "History cleared."
    ;;
  *)
    echo "Operation cancelled."
    ;;
  esac
}

# Main command handling
case "$1" in
"add")
  if [ -z "$2" ]; then
    echo "Error: Missing task description."
    echo "Usage: todo add 'Your task here'"
    exit 1
  fi
  shift
  add_task "$*"
  ;;
"list")
  list_tasks
  ;;
"done")
  if [[ ! "$2" =~ ^[0-9]+$ ]]; then
    echo "Error: Task number must be a positive integer."
    exit 1
  fi
  mark_done "$2"
  ;;
"remove")
  if [[ ! "$2" =~ ^[0-9]+$ ]]; then
    echo "Error: Task number must be a positive integer."
    exit 1
  fi
  remove_task "$2"
  ;;
"clear")
  clear_tasks
  ;;
"history")
  show_history
  ;;
"clean-history")
  clear_history
  ;;
"priority")
  if [[ ! "$2" =~ ^[0-9]+$ ]]; then
    echo "Error: Task number must be a positive integer."
    exit 1
  fi
  set_priority "$2" "$3"
  ;;
"help" | "--help" | "-h" | "")
  show_help
  ;;
*)
  echo "Unknown command: $1"
  echo "Try 'todo help' for valid commands."
  exit 1
  ;;
esac

exit 0
