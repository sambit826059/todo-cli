# todo-cli

A simple, lightweight CLI todo list manager for Arch Linux (and other Unix-like systems).

![Todo CLI](https://raw.githubusercontent.com/your-username/todo-cli/main/screenshots/todo-cli.png)

## Features

- ✅ Single command usage with intuitive subcommands
- 🔄 Persistent storage for tasks and completion history
- 🚦 Priority levels with color coding (high, medium, low)
- 📝 Task history tracking with timestamps
- 🎨 ASCII art interface
- 🔧 Simple installation and minimal dependencies

## Installation

```bash
# Clone the repository
git clone https://github.com/your-username/todo-cli.git
cd todo-cli

# Make the script executable
chmod +x todo.sh

# Create a symlink to make it available system-wide (optional)
sudo ln -s $(pwd)/todo.sh /usr/local/bin/todo
```

## Usage

```bash
# Add a new task
todo add Buy groceries

# List all tasks
todo list

# Set priority for a task
todo priority 1 high

# Mark a task as done
todo done 1

# Remove a task without marking as done
todo remove 2

# View completed tasks history
todo history

# Clear all tasks
todo clear

# Clear history of completed tasks
todo clean-history

# Show help
todo help
```

## Configuration

Tasks are stored in `~/.todo_list` and completed tasks in `~/.todo_done`. You can customize these locations by editing the script variables:

```bash
# Configuration
TODO_FILE="$HOME/.todo_list"
DONE_FILE="$HOME/.todo_done"
```

## Customization

The script is designed to be easily customizable:

- Modify the ASCII art in the `show_ascii_art` function
- Change colors by editing the color codes (e.g., `\e[1;31m` for high priority tasks)
- Add new commands by extending the case statement in the main command handling section

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Credits

Built from boredom and endless search for minimalistic todo list on web by me (sambit) and claude
