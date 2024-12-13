# Shell Scripts for AI-Powered Automation

## Project Description

This repository contains a collection of shell scripts that leverage large language models (LLMs) to provide powerful AI-driven functionality for a variety of tasks. These scripts cover a range of use cases, including code generation, task planning, prompt improvement, and more. By integrating LLMs into the shell environment, users can seamlessly incorporate AI capabilities into their everyday workflows and automate numerous tedious or complex tasks.

## Installation

To use the scripts in this repository, you will need to have the following dependencies installed:

- [llm](https://github.com/anthropic-research/llm): A command-line interface for interacting with large language models.

Once you have the `llm` tool installed, you can clone this repository and source the relevant script files in your terminal environment. For example, to use the `shelllm_gemini` function, you would run:

```
source path/to/repository/shelp_gemini.sh
```

Alternatively, you can add the script files to your `.bashrc` or `.zshrc` file for permanent availability.

## Usage

The repository contains the following shell scripts and their corresponding functionality:

### `shelp_gemini.sh`

- `shelllm_gemini`: This function allows you to interact with a large language model and execute shell commands based on the generated response. It supports options for controlling the reasoning, verbosity, and raw output of the language model.
- `gshelp`: An alias for `shelllm_gemini`.

### `auxiliary_functions.sh`

This file contains additional helper functions that are used by other scripts in the repository.

### `shelllm.sh`

This file contains a collection of functions that leverage large language models for various tasks, including:

- `write-agent-plan`: Generates a plan for an agent or task.
- `code_explainer`: Provides an explanation of code, including the reasoning behind it.
- `explainer`: An alias for `code_explainer`.
- `shelp`: Generates a shell command based on a user's query, with options for controlling verbosity, reasoning, and raw output.
- `task-plan-generator`: Generates a plan for a task, with options for controlling the reasoning and raw output.
- `task-plan`: An alias for `task-plan-generator`.
- `bash_generator`: Generates a Bash script based on a user's input, with options for controlling verbosity, reasoning, and raw output.
- `shell-script` and `scripter`: Aliases for `bash_generator`.
- `prompt-improver`: Generates an improved version of a user's prompt, with options for controlling verbosity, reasoning, creativity, and raw output.
- `brainstorm-generator`: Generates a brainstorm based on a user's input.
- `brainstorm`: An alias for `brainstorm-generator`.
- `digraph-generator`: Generates a directed graph (digraph) based on a user's input, with options for controlling verbosity, reasoning, and raw output.
- `digraph`: An alias for `digraph-generator`.
- `search_engineer`: Generates a list of search terms based on a user's input, with options for controlling the number, verbosity, reasoning, creativity, and raw output.
- `ai-judge`: Classifies code snippets provided by two candidates, evaluating which one is better.
- `analytical-hierarchy-process-generator`: Generates an Analytical Hierarchy Process (AHP) analysis based on user-provided ideas, criteria, and weights.
- `ahp`: An alias for `analytical-hierarchy-process-generator`.
- `commit-msg-generator`: Generates a commit message for a Git repository, based on the staged changes, and automatically commits and pushes the changes.
- `commit`: An alias for `commit-msg-generator`.
- `cli-ergonomics-engineer`: Analyzes a command-line interface and provides suggestions for improving its ergonomics.

## Contributing

If you would like to contribute to this project, please follow these guidelines:

1. Fork the repository.
2. Create a new branch for your feature or bug fix.
3. Implement your changes and ensure they are properly tested.
4. Update the README.md file to document any new functionality or changes.
5. Submit a pull request, explaining the purpose of your changes.

We welcome contributions that enhance the functionality, usability, or documentation of the shell scripts in this repository.