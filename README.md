# Shell Scripts

## Project Description

This repository contains a collection of shell scripts that provide various functionalities, including command execution, task planning, script generation, prompt improvement, and more. These scripts utilize natural language processing (NLP) capabilities to assist users in automating tasks and enhancing their command-line interface (CLI) experience.

## Installation

To use the scripts in this repository, you will need to have the following dependencies installed:

- A compatible shell (e.g., Bash, Zsh)
- The `llm` command-line tool for interacting with the NLP model

Once you have the dependencies installed, you can clone the repository and source the desired scripts in your shell configuration file (e.g., `.bashrc`, `.zshrc`).

## Usage

### `shell-commander`
The `shell-commander` script allows you to execute shell commands with the help of an NLP model. It takes a user input, generates a command based on the input, and executes the command. The script supports verbosity levels to provide additional information about the reasoning behind the generated command.

Usage:
```
shelp [-v <verbosity>] <user_input>
```

### `task_planner`
The `task_planner` script generates a task plan based on user input. It supports various options, such as specifying a verbosity level, adding notes, and controlling the display of the reasoning behind the task plan.

Usage:
```
task_plan [--v=<verbosity>] [--n=<note>] [--reasoning] [--show-reasoning] [--raw] <task_description>
```

### `shell-explain`
The `shell-explain` script provides an explanation for a given shell command or script. It generates a short explanation of the command's functionality based on the user's input.

Usage:
```
explainer [-v <verbosity>] <command>
```

### `shell-scripter`
The `shell-scripter` script generates a shell script based on user input. It provides the generated script, as well as an explanation of the script's functionality.

Usage:
```
scripter [-v <verbosity>] <user_input>
```

### `prompt-improver`
The `prompt-improver` script takes user input and generates an improved prompt based on the input. This can be useful for enhancing the quality of prompts used in various contexts, such as chatbots or task automation.

Usage:
```
prompt-improver [-v <verbosity>] <prompt>
```

### `mindstorm-ideas-generator`
The `mindstorm-ideas-generator` script generates creative ideas for a given topic or problem. It can be used to stimulate brainstorming and ideation.

Usage:
```
mindstorm <topic>
```

### `py-explain`
The `py-explain` script provides an explanation of Python code with a specified verbosity level.

Usage:
```
py-explain [<verbosity>] <python_code>
```

### `digraph_generator`
The `digraph_generator` script generates a digraph (directed graph) based on user input, with support for adjusting the verbosity level.

Usage:
```
digraph [-v <verbosity>] <input>
```

### `search_term_engineer`
The `search_term_engineer` script generates high-quality search queries based on user input, with support for specifying the number of queries to generate.

Usage:
```
search_term_engineer [-v <verbosity>] <user_input> [<num_queries>]
```

### `write_agent_plan`
The `write_agent_plan` script generates an agent plan based on a task description, with support for specifying the number of steps in the plan.

Usage:
```
agent_plan [-v <verbosity>] <task_description> [<num_steps>]
```

### `analytical_hierarchy_process_agent`
The `analytical_hierarchy_process_agent` script generates an Analytical Hierarchy Process (AHP) analysis based on user-provided ideas, criteria, and weights.

Usage:
```
ahp [--v=<verbosity>] [--n=<note>] [--raw] ideas criterion weights
```

### `commit_msg_generator`
The `commit_msg_generator` script generates a commit message based on the changes in the local git repository. It stages all changes, generates a commit message, and then pushes the changes to the remote repository.

Usage:
```
commit_msg [-v=<verbosity>] [-n=<note>]
```

### `cli_ergonomics_agent`
The `cli_ergonomics_agent` script analyzes a command-line interface (CLI) and provides recommendations for improving its ergonomics and usability.

Usage:
```
cli_ergonomics_agent [--v=<verbosity>] [--n=<note>] [--raw] <cli_interface>
```

## Contributing

Contributions to this repository are welcome. If you have any improvements or additional functionality to add, please feel free to submit a pull request. When contributing, please follow the existing coding style and provide clear documentation for any new features or scripts.