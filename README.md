# Project Title

## Project Description

This repository contains a collection of shell scripts that provide various utilities and tools for working with shell commands, Python code, and task planning. The main functionalities include:

1. **Shell Commands Execution**: The `shelllm.sh` script allows you to execute shell commands based on natural language input, with support for different verbosity levels.
2. **Shell Commands Explanation**: The `shelllm.sh` script also includes a `shell-explain` function that can provide explanations for shell commands with varying levels of detail.
3. **Shell Script Generation**: The `shelllm.sh` script includes a `shell-scripter` function that can generate shell scripts based on natural language input, with support for verbosity and explanation of the generated script.
4. **Commit Message Generation**: The `shelllm.sh` script includes a `commit` function that can generate commit messages based on the changes in the repository, with support for verbosity.
5. **Prompt Improvement**: The `shelllm.sh` script includes a `prompt-improver` function that can improve user prompts based on natural language input, with support for verbosity.
6. **Mindstorm Generation**: The `shelllm.sh` script includes a `mindstorm-generator` function that can generate a mindstorm of ideas based on a user prompt, with support for verbosity and model selection.
7. **Python Code Explanation**: The `shelllm.sh` script includes a `py-explain` function that can provide explanations for Python code with varying levels of detail.
8. **Digraph Generation**: The `shelllm.sh` script includes a `digraph_generator` function that can generate a digraph based on user input, with support for verbosity.
9. **Search Query Generation**: The `shelllm.sh` script includes a `search_term_engineer` function that can generate high-quality search queries based on user input, with support for verbosity and the number of queries.
10. **Agent and Task Planning**: The `shelllm.sh` script includes `write_agent_plan` and `write_task_plan` functions that can generate agent and task plans based on user input, with support for verbosity and the number of steps.
11. **Analytical Hierarchy Process (AHP)**: The `shelllm.sh` script includes an `analytical_hierarchy_process` function that can perform AHP analysis based on user-provided ideas, criteria, and weights, with support for verbosity.

## Installation

To use the scripts in this repository, you will need to have the following dependencies installed:

- `llm` (Language Model) - A command-line interface for interacting with large language models.
- `pv` (Pipe Viewer) - A tool for monitoring the progress of data through a pipe.

You can install these dependencies using your system's package manager, for example:

```bash
# On Ubuntu/Debian
sudo apt-get install llm pv

# On macOS (with Homebrew)
brew install llm pv
```

Once you have the dependencies installed, you can clone the repository and source the `shelllm.sh` script in your shell configuration (e.g., `.bashrc`, `.zshrc`, etc.):

```bash
git clone https://github.com/your-username/your-repo.git
echo "source /path/to/your-repo/shelllm.sh" >> ~/.bashrc
```

## Usage

After sourcing the `shelllm.sh` script, you can use the various functions provided by the scripts. Here are some examples:

1. **Execute a shell command**:
   ```bash
   shelp "list the files in the current directory"
   ```

2. **Explain a shell command**:
   ```bash
   explainer "ls -l"
   ```

3. **Generate a shell script**:
   ```bash
   scripter "create a script that prints 'Hello, World!'"
   ```

4. **Commit changes to the repository**:
   ```bash
   commit "Implement new feature"
   ```

5. **Improve a user prompt**:
   ```bash
   prompt-improver "Tell me about the weather"
   ```

6. **Generate a mindstorm of ideas**:
   ```bash
   mindstorm-generator "Brainstorm ideas for a new product"
   ```

7. **Explain Python code**:
   ```bash
   py-explain "def fibonacci(n):\n  if n <= 1:\n    return n\n  else:\n    return(fibonacci(n-1) + fibonacci(n-2))"
   ```

8. **Generate a digraph**:
   ```bash
   digraph_generator "Create a diagram showing the relationship between different components"
   ```

9. **Generate search queries**:
   ```bash
   search_term_engineer "Improve search engine results for machine learning"
   ```

10. **Write an agent plan**:
    ```bash
    write_agent_plan "Develop a new marketing strategy for the company"
    ```

11. **Write a task plan**:
    ```bash
    write_task_plan "Implement a new feature in the application"
    ```

12. **Perform Analytical Hierarchy Process (AHP)**:
    ```bash
    analytical_hierarchy_process "Select the best product idea" ideas criterion weights
    ```

For more detailed information on the usage of each function, you can refer to the comments and descriptions within the `shelllm.sh` script.

## Contributing

If you would like to contribute to this project, please follow these steps:

1. Fork the repository.
2. Create a new branch for your feature or bug fix.
3. Make your changes and commit them with clear and concise commit messages.
4. Push your changes to your forked repository.
5. Submit a pull request to the main repository.

Please make sure your contributions adhere to the project's coding style and guidelines.