# Shell Scripts and Language Model Integration Project

## Project Description

This project showcases the integration of shell scripts with a large language model (LLM) to enhance the functionality and capabilities of command-line interfaces (CLIs). The repository contains a set of shell scripts that utilize the LLM to provide various features, such as:

1. **Code Explanation and Reasoning**: The `code_explainer` function allows users to request explanations and reasoning for code snippets, with customizable verbosity and reasoning levels.
2. **Task Planning**: The `task-plan-generator` function generates task plans based on user input, with the ability to show the reasoning process.
3. **Bash Script Generation**: The `bash_generator` function can generate bash scripts based on user prompts, with support for verbosity and reasoning levels.
4. **Prompt Improvement**: The `prompt-improver` function can enhance user prompts, with options to control verbosity, reasoning, and creativity levels.
5. **Brainstorming**: The `brainstorm-generator` function can provide creative brainstorming ideas based on user input.
6. **Directed Acyclic Graph (DAG) Generation**: The `digraph-generator` function can generate visualizations of directed acyclic graphs, with support for verbosity and reasoning levels.
7. **Search Term Recommendation**: The `search_engineer` function can suggest relevant search terms based on user input, with options for number of results, verbosity, reasoning, and creativity.
8. **Commit Message Generation**: The `commit-msg-generator` function can generate commit messages based on the current git diff, with an interactive confirmation process.
9. **CLI Ergonomics Improvement**: The `cli-ergonomics-engineer` function can refactor command-line interfaces to improve usability and ergonomics.

These shell scripts leverage the capabilities of the LLM to enhance the user experience and automate various tasks within the command-line environment.

## Installation

To use the shell scripts in this project, you will need to have the following installed:

1. A compatible shell, such as Bash or Zsh.
2. The `llm` command-line tool, which is used to interact with the language model. You can install it using the instructions provided in the [llm repository](https://github.com/anthropic-institute/llm).

Once you have the dependencies installed, you can source the relevant shell scripts in your terminal environment. For example, to use the `shelp_gemini` function, you would run:

```
source path/to/shelp_gemini.sh
```

Alternatively, you can add the path to the shell script files to your shell's startup file (e.g., `.bashrc` or `.zshrc`) to make the functions available in every new terminal session.

## Usage

Each shell script in the repository provides a specific functionality, as described in the Project Description section. You can use the functions by calling them in your terminal, optionally passing in various arguments to customize the behavior.

For example, to use the `code_explainer` function, you can run:

```
code_explainer --verbosity=5 path/to/code_file.py
```

This will generate an explanation of the code in the specified file, with a verbosity level of 5 out of 9.

Refer to the comments and documentation within each shell script to understand the available options and how to use the different functions.

## Contributing

If you would like to contribute to this project, please follow these steps:

1. Fork the repository.
2. Create a new branch for your feature or bug fix.
3. Implement your changes and ensure they work as expected.
4. Update the README.md file with any relevant information about your changes.
5. Submit a pull request to the main repository.

We welcome contributions that enhance the functionality, usability, or documentation of the shell scripts in this project.