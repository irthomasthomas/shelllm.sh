# Shell Scripts Project

## Project Description

This repository contains a collection of shell scripts that provide various utilities and functionality to enhance the user's experience with the command line and system interactions. The scripts leverage large language models (LLMs) to power their capabilities, allowing users to interact with the system in more natural and intelligent ways.

The main features of this project include:

1. **Shell Command Execution**: The `shell-commander` script allows users to execute shell commands with the help of an LLM, providing context-aware responses and explanations.
2. **Shell Script Generation**: The `shell-scripter` script generates shell scripts based on user prompts, with the LLM providing the necessary reasoning and explanations.
3. **Prompt Improvement**: The `prompt-improver` script enhances user prompts by incorporating additional context and verbosity based on the user's request.
4. **Mindstorm Ideas Generation**: The `mindstorm-ideas-generator` script generates creative ideas and solutions using the power of the LLM.
5. **Python Code Explanation**: The `py-explain` script provides detailed explanations of Python code, tailored to the user's requested level of verbosity.
6. **Digraph Generation**: The `digraph_generator` script generates digraph visualizations based on user input.
7. **Search Term Engineering**: The `search_term_engineer` script generates high-quality search queries for search engines, based on user input.
8. **Agent and Task Planning**: The `write_agent_plan` and `write_task_plan` scripts create detailed plans for agents and tasks, respectively, using the LLM.
9. **Analytical Hierarchy Process (AHP) Generator**: The `analytical_hierarchy_process_generator` script generates AHP-based analysis and recommendations based on user-provided ideas, criteria, and weights.
10. **Commit Message Generation**: The `commit` script helps generate meaningful and context-aware commit messages for version control systems.

## Installation

To use the shell scripts in this project, you'll need to have the following dependencies installed:

- [LLM (Large Language Model) CLI tool](https://github.com/anthropic-institute/llm-cli) - This tool is used to interact with the LLM and provide the necessary functionality.
- [pv (Pipe Viewer)](https://www.ivarch.com/programs/pv.shtml) - This tool is used to display progress and verbosity in the shell scripts.

You can install these dependencies using your system's package manager (e.g., `apt-get`, `yum`, `brew`, etc.).

After installing the dependencies, you can clone the repository and add the scripts to your system's `PATH` environment variable for easy access.

## Usage

To use the shell scripts, simply invoke them from the command line. Most of the scripts support a `-v` or `--verbosity` option to control the level of detail in the output.

Here are some examples of how to use the scripts:

1. **Shell Command Execution**:
   ```
   $ shelp -v 3 "ls -l"
   ```

2. **Shell Script Generation**:
   ```
   $ scripter -v 5 "write a script to backup my home directory"
   ```

3. **Prompt Improvement**:
   ```
   $ prompt-improver -v 2 "generate a shell script to backup my files"
   ```

4. **Mindstorm Ideas Generation**:
   ```
   $ mindstorm -v 4 "generate 5 creative ideas for a new product"
   ```

5. **Python Code Explanation**:
   ```
   $ py-explain 3 my_python_script.py
   ```

You can refer to the individual script descriptions above for more details on how to use each functionality.

## Contributing

If you would like to contribute to this project, please follow these guidelines:

1. Fork the repository.
2. Create a new branch for your feature or bug fix.
3. Implement your changes and ensure they work as expected.
4. Update the documentation (this README.md file) to reflect your changes.
5. Commit your changes and push the branch to your fork.
6. Submit a pull request to the main repository.

We welcome contributions that enhance the functionality, improve the user experience, or add new features to the shell scripts. Please make sure your contributions align with the project's goals and follow best practices for shell scripting and LLM integration.