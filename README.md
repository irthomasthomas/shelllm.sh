# Shell Scripts Repository

## Project Description
This repository contains a collection of shell scripts that provide various functionalities to automate tasks and enhance productivity. The scripts cover a wide range of use cases, including command execution, code explanation, script generation, task planning, and more. These scripts leverage the power of large language models (LLMs) to generate responses based on user input and requests.

## Installation
To use the scripts in this repository, you will need to have the following dependencies installed:

1. `llm` (Large Language Model) command-line tool
2. `pv` (Pipe Viewer) for displaying output with a smooth animation

You can install these dependencies using your system's package manager (e.g., `apt`, `brew`, `yum`, etc.).

## Usage

### Shell Commander (`shelp`)
The `shelp` command allows you to execute shell commands and receive a response with reasoning and the actual command to be executed. The `shelp` command supports optional verbosity settings.

**Usage:**
```
shelp [-v <verbosity>] <command>
```

### Shell Explainer (`explainer`)
The `explainer` command provides a short explanation for a given shell command. The explanation is generated using an LLM and can be displayed with optional verbosity settings.

**Usage:**
```
explainer [-v <verbosity>] <command>
```

### Shell Scripter (`scripter`)
The `scripter` command generates a shell script based on a user's request. It provides the generated script, along with an explanation of the script's purpose and reasoning.

**Usage:**
```
scripter [-v <verbosity>] <task_description>
```

### Prompt Improver (`prompt-improver`)
The `prompt-improver` command takes a user prompt and generates an improved version of the prompt with additional context and details, based on the user's requested verbosity level.

**Usage:**
```
prompt-improver [-v <verbosity>] <prompt>
```

### Mindstorm Ideas Generator (`mindstorm`)
The `mindstorm` command generates creative ideas for a given topic or task, leveraging the capabilities of LLMs.

**Usage:**
```
mindstorm [-v <verbosity>] <topic>
```

### Python Explainer (`py-explain`)
The `py-explain` command provides an explanation for a given Python code snippet, with optional verbosity settings.

**Usage:**
```
py-explain [<verbosity>] <python_code>
```

### Digraph Generator (`digraph`)
The `digraph` command generates a directed graph (digraph) based on user input, with optional verbosity settings.

**Usage:**
```
digraph [-v <verbosity>] <input>
```

### Search Term Engineer (`search_term_engineer`)
The `search_term_engineer` command generates high-quality search queries based on user input, with optional control over the number of queries to be generated.

**Usage:**
```
search_term_engineer [-v <verbosity>] <user_input> [<num_queries>]
```

### Agent Plan Writer (`agent_plan`)
The `agent_plan` command writes an agent plan based on a task description, with optional control over the number of steps in the plan.

**Usage:**
```
agent_plan [-v <verbosity>] <task_description> [<num_steps>]
```

### Task Plan Writer (`task_plan`)
The `task_plan` command writes a detailed task plan based on a task description, with optional control over the number of steps in the plan.

**Usage:**
```
task_plan [-v <verbosity>] <task_description> [<num_steps>]
```

### Analytical Hierarchy Process (AHP) Generator (`ahp`)
The `ahp` command generates an Analytical Hierarchy Process (AHP) based on user-provided ideas, criteria, and weights.

**Usage:**
```
ahp [-v <verbosity>] <industry/product> ideas criterion weights
```

### Commit Helper (`commit`)
The `commit` command automates the Git commit process, generating a commit message based on the changes in the repository and user-provided notes.

**Usage:**
```
commit [-v <verbosity>] [<note>]
```

## Contributing
Contributions to this repository are welcome! If you have any improvements, bug fixes, or new scripts to add, please submit a pull request. Make sure to follow the existing coding style and provide clear documentation for any new features or scripts.