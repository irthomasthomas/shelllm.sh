# Shell Scripts for Enhanced CLI Ergonomics

## Project Description
This repository contains a collection of shell scripts that enhance the user experience and functionality of the command-line interface (CLI). These scripts utilize large language models (LLMs) to provide intelligent responses and automate various tasks, making the CLI more ergonomic and efficient.

The main features of this project include:

1. **Shell Commander**: A script that allows users to execute shell commands with the help of an LLM, providing reasoning and explaining the command's purpose.
2. **Shell Explainer**: A script that explains the purpose and functionality of shell commands.
3. **Shell Scripter**: A script that generates shell scripts based on user input, providing reasoning and explanation for the generated code.
4. **Prompt Improver**: A script that improves user prompts based on the input, enhancing the quality of responses from LLMs.
5. **Mindstorm Ideas Generator**: A script that generates creative ideas for a given topic using an LLM.
6. **Python Explanation**: A script that explains the purpose and functionality of Python code.
7. **Digraph Generator**: A script that generates a digraph (directed graph) based on user input.
8. **Search Term Engineer**: A script that generates high-quality search queries for search engines based on user input.
9. **Agent Plan Writer**: A script that writes an agent plan based on a task description.
10. **Task Plan Writer**: A script that writes a detailed task plan based on a task description.
11. **Analytical Hierarchy Process (AHP) Generator**: A script that generates an AHP analysis based on user-provided ideas, criteria, and weights.
12. **Commit Message Generator**: A script that generates commit messages for Git repositories based on the staged changes.
13. **CLI Ergonomics Agent**: A script that refactors the command-line interface to improve ergonomics and usability.

## Installation

1. Clone the repository:
   ```
   git clone https://github.com/your-username/shell-scripts-for-cli-ergonomics.git
   ```
2. Change to the project directory:
   ```
   cd shell-scripts-for-cli-ergonomics
   ```
3. Source the shell scripts to make them available in your current shell session:
   ```
   source shelllm.sh
   ```

## Usage

Each script in this repository has a specific purpose and can be used with various command-line arguments. Here's a brief overview of how to use each script:

1. **Shell Commander**: `shell-commander [-v <verbosity>] <command>`
2. **Shell Explainer**: `shell-explain [-v <verbosity>] <command>`
3. **Shell Scripter**: `shell-scripter [-v <verbosity>] <description>`
4. **Prompt Improver**: `prompt-improver [-v <verbosity>] <prompt>`
5. **Mindstorm Ideas Generator**: `mindstorm [-m <model>] <topic>`
6. **Python Explanation**: `py-explain [<verbosity>] <python_code>`
7. **Digraph Generator**: `digraph [-v <verbosity>] <input>`
8. **Search Term Engineer**: `search_term_engineer [-v <verbosity>] <user_input> [<num_queries>]`
9. **Agent Plan Writer**: `agent_plan [-v <verbosity>] <task_description> [<num_steps>]`
10. **Task Plan Writer**: `task_plan [-v <verbosity>] <task_description> [<num_steps>]`
11. **AHP Generator**: `ahp [-v <verbosity>] <industry/product> ideas criterion weights`
12. **Commit Message Generator**: `commit [-v=<verbosity>] [-n=<note>] [<git-command-options>]`
13. **CLI Ergonomics Agent**: `cli_ergonomics_agent [-v=<verbosity>] [-n=<note>] <command>`

Refer to the individual script descriptions for more details on the available options and usage.

## Contributing

Contributions to this project are welcome. If you find any issues or have ideas for new features, please feel free to create a new issue or submit a pull request. When contributing, please follow the existing coding style and conventions.