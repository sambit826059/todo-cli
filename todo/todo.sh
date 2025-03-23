#!/bin/bash

# Configuration
TODO_FILE="$HOME/.todo_list"
DONE_FILE="$HOME/.todo_done"
TODAY_FILE="$HOME/.todo_today"

# Create files if they don't exist
touch "$TODO_FILE"
touch "$DONE_FILE"
touch "$TODAY_FILE"

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
  echo "  add TEXT           Add a new task"
  echo "  add -t TEXT        Add a new task and mark it for today"
  echo "  list               List all tasks"
  echo "  today              List today's tasks"
  echo "  mark-today N       Mark task N for today"
  echo "  unmark-today N     Remove task N from today's list"
  echo "  done N             Mark task N as done"
  echo "  remove N           Remove task N without marking as done"
  echo "  clear              Remove all tasks"
  echo "  clear-today        Clear today's task list (keeps tasks in main list)"
  echo "  history            Show completed tasks"
  echo "  clean-history      Clear history of completed tasks"
  echo "  priority N P       Set priority for task N (P=high|medium|low)"
  echo "  help               Display this help message"
  echo ""
  echo "Example: todo add -t 'Buy groceries'"
}

# List all tasks with numbers
list_tasks() {
  if [ ! -s "$TODO_FILE" ]; then
    echo "No tasks. Add one with 'todo add TASK'."
    return
  fi

  echo -e "\e[1;37mYour tasks:\e[0m"  # Bright white header
  local count=1
  while IFS= read -r line; do
    # Check if task is in today's list
    is_today_task=false
    task_id=$(echo "$line" | cut -d'|' -f1)

    if grep -q "^$task_id|" "$TODAY_FILE" 2>/dev/null; then
      is_today_task=true
    fi

    # Print task number in blue
    echo -ne "  \e[1;34m$count.\e[0m "

    # Extract priority if it exists
    if [[ "$line" =~ ^([^|]+)\|PRIORITY:([^:]+):(.*)$ ]]; then
      id="${BASH_REMATCH[1]}"
      priority="${BASH_REMATCH[2]}"
      task="${BASH_REMATCH[3]}"

      # Add color based on priority
      case "$priority" in
      "high")
        echo -ne "\e[1;31m$task\e[0m \e[1;37;41m HIGH \e[0m"  # Bold red text with white on red background
        ;;
      "medium")
        echo -ne "\e[1;33m$task\e[0m \e[1;30;43m MEDIUM \e[0m"  # Bold yellow text with black on yellow background
        ;;
      "low")
        echo -ne "\e[1;32m$task\e[0m \e[1;37;42m LOW \e[0m"  # Bold green text with white on green background
        ;;
      esac
    else
      id=$(echo "$line" | cut -d'|' -f1)
      task=$(echo "$line" | cut -d'|' -f2-)
      echo -ne "\e[1;37m$task\e[0m"
    fi

    # Add today indicator with skeletal color
    if [ "$is_today_task" = true ]; then
      echo -e " \e[38;5;80m[TODAY]\e[0m"  # Skeletal blue-green
    else
      echo ""
    fi

    ((count++))
  done <"$TODO_FILE"
}

# List today's tasks
list_today_tasks() {
  if [ ! -s "$TODAY_FILE" ]; then
    echo "No tasks for today. Mark a task for today with 'todo mark-today N'."
    return
  fi

  echo -e "\e[1;36mToday's tasks:\e[0m"  # Cyan header
  local count=1

  # Loop through today file
  while IFS= read -r today_line; do
    task_id=$(echo "$today_line" | cut -d'|' -f1)

    # Find the task in the main list
    while IFS= read -r line; do
      line_id=$(echo "$line" | cut -d'|' -f1)

      if [ "$line_id" = "$task_id" ]; then
        # Print task number in blue
        echo -ne "  \e[1;34m$count.\e[0m "

        # Extract priority if it exists
        if [[ "$line" =~ ^([^|]+)\|PRIORITY:([^:]+):(.*)$ ]]; then
          priority="${BASH_REMATCH[2]}"
          task="${BASH_REMATCH[3]}"

          # Add color based on priority
          case "$priority" in
          "high")
            echo -e "\e[1;31m$task\e[0m \e[1;37;41m HIGH \e[0m"  # Bold red text with white on red background
            ;;
          "medium")
            echo -e "\e[1;33m$task\e[0m \e[1;30;43m MEDIUM \e[0m"  # Bold yellow text with black on yellow background
            ;;
          "low")
            echo -e "\e[1;32m$task\e[0m \e[1;37;42m LOW \e[0m"  # Bold green text with white on green background
            ;;
          esac
        else
          task=$(echo "$line" | cut -d'|' -f2-)
          # Print regular tasks in bright white
          echo -e "\e[1;37m$task\e[0m"
        fi
        break
      fi
    done <"$TODO_FILE"

    ((count++))
  done <"$TODAY_FILE"
}

# Generate a unique ID
generate_id() {
  echo $(date +%s%N | md5sum | head -c 10)
}

# Add a new task
add_task() {
  local for_today=false
  local task_text=""

  # Check if -t flag is present
  if [ "$1" = "-t" ]; then
    for_today=true
    shift
    task_text="$*"
  else
    task_text="$*"
  fi

  # Generate a unique ID for the task
  local task_id=$(generate_id)

  # Add task to main list
  echo "$task_id|$task_text" >>"$TODO_FILE"
  echo "Task added: $task_text"

  # If -t flag was used, add to today's list
  if [ "$for_today" = true ]; then
    echo "$task_id|$task_text" >>"$TODAY_FILE"
    echo "Task marked for today."
  fi
}

# Mark a task for today
mark_today() {
  if [ ! -s "$TODO_FILE" ]; then
    echo "No tasks to mark for today."
    return
  fi

  local task_number=$1
  local count=1
  local marked=false
  local task_content=""
  local task_id=""

  # Find the task by number
  while IFS= read -r line; do
    if [ $count -eq $task_number ]; then
      task_id=$(echo "$line" | cut -d'|' -f1)
      task_content=$(echo "$line" | cut -d'|' -f2-)

      # Check if already in today's list
      if grep -q "^$task_id|" "$TODAY_FILE" 2>/dev/null; then
        echo "Task is already marked for today."
      else
        echo "$task_id|$task_content" >>"$TODAY_FILE"
        echo "Task marked for today: $task_content"
      fi

      marked=true
      break
    fi
    ((count++))
  done <"$TODO_FILE"

  if [ "$marked" = false ]; then
    echo "Task number $task_number not found."
  fi
}

# Remove a task from today's list
unmark_today() {
  if [ ! -s "$TODAY_FILE" ]; then
    echo "No tasks marked for today."
    return
  fi

  local task_number=$1
  local count=1
  local unmarked=false

  # Create a temporary file
  local temp_file=$(mktemp)

  # Find the task in the today list
  while IFS= read -r line; do
    if [ $count -eq $task_number ]; then
      task_content=$(echo "$line" | cut -d'|' -f2-)
      echo "Task removed from today's list: $task_content"
      unmarked=true
    else
      echo "$line" >>"$temp_file"
    fi
    ((count++))
  done <"$TODAY_FILE"

  # Replace today file with temp file
  mv "$temp_file" "$TODAY_FILE"

  if [ "$unmarked" = false ]; then
    echo "Today's task number $task_number not found."
  fi
}

# Clear today's list
clear_today() {
  if [ ! -s "$TODAY_FILE" ]; then
    echo "No tasks marked for today."
    return
  fi

  read -p "Are you sure you want to clear today's task list? (y/n): " choice
  case "$choice" in
  y | Y)
    >"$TODAY_FILE"
    echo "Today's tasks cleared."
    ;;
  *)
    echo "Operation cancelled."
    ;;
  esac
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
  local task_id=""

  # Create a temporary file for main list
  local temp_file=$(mktemp)

  # Create a temporary file for today's list
  local today_temp_file=$(mktemp)

  # Copy today's list to temp file
  if [ -s "$TODAY_FILE" ]; then
    cp "$TODAY_FILE" "$today_temp_file"
  fi

  while IFS= read -r line; do
    if [ $count -eq $task_number ]; then
      task_id=$(echo "$line" | cut -d'|' -f1)

      # Extract the actual task text removing priority if it exists
      if [[ "$line" =~ ^([^|]+)\|PRIORITY:([^:]+):(.*)$ ]]; then
        task_content="${BASH_REMATCH[3]}"
      else
        task_content=$(echo "$line" | cut -d'|' -f2-)
      fi

      # Add to done file with timestamp
      echo "$(date '+%Y-%m-%d %H:%M:%S') - $task_content" >>"$DONE_FILE"
      echo "Task marked as done: $task_content"

      # Also remove from today's list if it's there
      if [ -s "$TODAY_FILE" ]; then
        grep -v "^$task_id|" "$TODAY_FILE" >"$today_temp_file"
        mv "$today_temp_file" "$TODAY_FILE"
      fi

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
  local task_id=""

  # Create a temporary file for main list
  local temp_file=$(mktemp)

  # Create a temporary file for today's list
  local today_temp_file=$(mktemp)

  # Copy today's list to temp file
  if [ -s "$TODAY_FILE" ]; then
    cp "$TODAY_FILE" "$today_temp_file"
  fi

  while IFS= read -r line; do
    if [ $count -eq $task_number ]; then
      task_id=$(echo "$line" | cut -d'|' -f1)
      task_content=$(echo "$line" | cut -d'|' -f2-)
      echo "Task removed: $task_content"

      # Also remove from today's list if it's there
      if [ -s "$TODAY_FILE" ]; then
        grep -v "^$task_id|" "$TODAY_FILE" >"$today_temp_file"
        mv "$today_temp_file" "$TODAY_FILE"
      fi

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
  local task_id=""

  # Create a temporary file
  local temp_file=$(mktemp)

  while IFS= read -r line; do
    if [ $count -eq $task_number ]; then
      # Extract the task ID and content
      task_id=$(echo "$line" | cut -d'|' -f1)

      # Extract the actual task text removing priority if it exists
      if [[ "$line" =~ ^([^|]+)\|PRIORITY:([^:]+):(.*)$ ]]; then
        task_content="${BASH_REMATCH[3]}"
      else
        task_content=$(echo "$line" | cut -d'|' -f2-)
      fi

      echo "$task_id|PRIORITY:$priority:$task_content" >>"$temp_file"
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
    >"$TODAY_FILE" # Also clear today's tasks
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
    echo "Usage: todo add [-t] 'Your task here'"
    exit 1
  fi
  shift
  add_task "$@"
  ;;
"list")
  list_tasks
  ;;
"today")
  list_today_tasks
  ;;
"mark-today")
  if [[ ! "$2" =~ ^[0-9]+$ ]]; then
    echo "Error: Task number must be a positive integer."
    exit 1
  fi
  mark_today "$2"
  ;;
"unmark-today")
  if [[ ! "$2" =~ ^[0-9]+$ ]]; then
    echo "Error: Task number must be a positive integer."
    exit 1
  fi
  unmark_today "$2"
  ;;
"clear-today")
  clear_today
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