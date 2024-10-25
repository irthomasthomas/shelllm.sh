# Shell Scripts for Productivity and Automation

## Project Description
This repository contains a collection of shell scripts designed to enhance productivity, streamline workflows, and automate various tasks. The scripts leverage large language models (LLMs) to provide intelligent assistance, generate code, and simplify complex operations.

## Installation
To use the scripts in this repository, you will need to have the following installed on your system:

1. **Bash** or compatible shell environment
2. **llm** command-line tool for interacting with LLMs (e.g., GPT-3, GPT-J, GPT-Neo)

You can install the `llm` tool using the following command:

```bash
pip install llm
```

## Usage

The repository includes the following shell scripts:

### Shell Commander
The `shell-commander` script allows you to generate shell commands based on a natural language prompt. It uses an LLM to understand the user's intent and provide the appropriate command.

Usage:
```bash
shelp [options] <command_prompt>
```

Options:
- `--v=<level>` or `--verbosity=<level>`: Set the verbosity level (0-9) for the response.
- `--reasoning`: Display the reasoning behind the generated command.
- `--show-reasoning`: Show the reasoning along with the command.
- `--raw` or `--r`: Return the raw command without any additional formatting.

### Task Planner
The `task_planner` script generates a step-by-step plan for a given task. It uses an LLM to understand the task and provide a detailed plan.

Usage:
```bash
task_plan [options] <task_description>
```

Options:
- `--v=<level>` or `--verbosity=<level>`: Set the verbosity level (0-9) for the response.
- `--n=<note>` or `--note=<note>`: Provide additional notes to guide the task planning.
- `--reasoning`: Display the reasoning behind the generated plan.
- `--show-reasoning`: Show the reasoning along with the plan.
- `--raw` or `--r`: Return the raw plan without any additional formatting.

### Shell Explainer
The `shell-explain` script provides a natural language explanation for a given shell command or script.

Usage:
```bash
explainer [-v <verbosity>] <shell_command> [arguments]
```

Options:
- `-v <verbosity>`: Set the verbosity level (0-9) for the response.

### Shell Scripter
The `shell-scripter` script generates a shell script based on a natural language prompt. It uses an LLM to understand the user's intent and generate the appropriate script.

Usage:
```bash
scripter [options] <script_prompt>
```

Options:
- `-v <verbosity>`: Set the verbosity level (0-9) for the response.

### Prompt Improver
The `prompt-improver` script refines a given prompt to generate a more effective response from an LLM.

Usage:
```bash
prompt-improver [options] <prompt>
```

Options:
- `-v <verbosity>`: Set the verbosity level (0-9) for the response.

### Mindstorm Ideas Generator
The `mindstorm-ideas-generator` script generates a list of creative ideas based on a given prompt.

Usage:
```bash
mindstorm <prompt>
```

### Python Explainer
The `py-explain` script provides a natural language explanation for a given Python script or code snippet.

Usage:
```bash
py-explain [verbosity] <python_code>
```

### Digraph Generator
The `digraph-generator` script generates a directed graph (digraph) based on user input.

Usage:
```bash
digraph [options] <input>
```

Options:
- `-v <verbosity>`: Set the verbosity level (0-9) for the response.

### Search Term Engineer
The `search_term_engineer` script generates high-quality search queries based on user input.

Usage:
```bash
search_term_engineer [options] <user_input> [num_queries]
```

Options:
- `-v <verbosity>`: Set the verbosity level (0-9) for the response.

### Agent Plan Writer
The `write_agent_plan` script writes an agent plan based on a task description.

Usage:
```bash
agent_plan [options] <task_description> [num_steps]
```

Options:
- `-v <verbosity>`: Set the verbosity level (0-9) for the response.

### Analytical Hierarchy Process Agent
The `analytical_hierarchy_process_agent` script generates a multi-criteria decision analysis using the Analytical Hierarchy Process (AHP) method.

Usage:
```bash
ahp [options] ideas criterion weights
```

Options:
- `--v=<level>` or `--verbosity=<level>`: Set the verbosity level (0-9) for the response.
- `--n=<note>` or `--note=<note>`: Provide additional notes to guide the AHP process.
- `--raw` or `--r`: Return the raw AHP result without additional formatting.

### Commit Message Generator
The `commit_msg_generator` script generates a commit message based on the staged changes in the repository.

Usage:
```bash
commit [options]
```

Options:
- `-v=<level>` or `-verbosity=<level>`: Set the verbosity level (0-9) for the response.
- `-n=<note>` or `-note=<note>`: Provide additional notes to guide the commit message generation.

### CLI Ergonomics Agent
The `cli_ergonomics_agent` script analyzes a command-line interface and provides suggestions for improving its ergonomics and usability.

Usage:
```bash
cli_ergonomics_agent [options] <cli_interface>
```

Options:
- `--v=<level>` or `--verbosity=<level>`: Set the verbosity level (0-9) for the response.
- `--n=<note>` or `--note=<note>`: Provide additional notes to guide the CLI analysis.
- `--raw` or `--r`: Return the raw response without parsing.

## Contributing
If you find any issues or have suggestions for improvements, feel free to submit a pull request or open an issue in the repository. Contributions are welcome, and we appreciate your feedback to make these scripts more useful and effective.