# Shell Scripting Toolkit

## Project Description
The Shell Scripting Toolkit is a collection of shell scripts that provide various utilities and functionalities to enhance the user's shell experience. The toolkit includes scripts for improving prompts, explaining shell commands, generating shell scripts, and more. These scripts leverage large language models (LLMs) to provide intelligent and contextual responses to the user's requests.

## Installation
To use the Shell Scripting Toolkit, you will need to have the following dependencies installed:

1. A shell environment (e.g., Bash, Zsh)
2. The `llm` command-line tool, which is used to interact with the LLM
3. Optional: `pv` (Pipe Viewer) for better output formatting

Once you have the dependencies installed, you can clone the repository and source the relevant scripts in your shell configuration file (e.g., `.bashrc`, `.zshrc`).

```bash
git clone https://github.com/your-username/shell-scripting-toolkit.git
```

## Usage

### `prompt-improver`
The `prompt-improver` script is used to enhance the user's shell prompt with additional context and verbosity based on the user's request. The script takes the following options:

- `-v <verbosity>`: Sets the response verbosity level, where 0 is the default and higher numbers increase the verbosity.

Example usage:
```bash
prompt-improver -v 3 "What is the current directory?"
```

### `shell-explain`
The `shell-explain` script is used to provide explanations for shell commands. It takes the following options:

- `<verbosity>`: Sets the response verbosity level, where 1 is the default and higher numbers increase the verbosity.
- `<command>`: The shell command to be explained.

Example usage:
```bash
shell-explain 3 ls -l
```

### `shell-commander`
The `shell-commander` script is used to generate and execute shell commands based on a user's request. It takes the following arguments:

- `<command>`: The user's request for a shell command.

Example usage:
```bash
shelp "list all files in the current directory"
```

### `shell-scripter`
The `shell-scripter` script is used to generate complete bash shell scripts based on a user's prompt. It takes the following arguments:

- `<prompt>`: The user's request for a shell script.

Example usage:
```bash
shell-scripter "Write a script to backup the /etc directory to a tar file"
```

### `mindstorm-generator`
The `mindstorm-generator` script is used to generate a mindstorm of ideas based on a user's prompt. It takes the following options:

- `-m <model>`: Specifies the LLM model to use for the mindstorm generation (default is `claude-3.5-sonnet`).
- `<prompt>`: The user's request for a mindstorm of ideas.

Example usage:
```bash
mindstorm-generator -m gpt-4 "Generate ideas for a new startup business"
```

### `py-explain`
The `py-explain` script is used to provide explanations for Python code. It takes the following options:

- `<verbosity>`: Sets the response verbosity level, where 1 is the default and higher numbers increase the verbosity.
- `<python_code>`: The Python code to be explained.

Example usage:
```bash
py-explain 3 "def factorial(n):\n    if n == 0:\n        return 1\n    else:\n        return n * factorial(n-1)"
```

## Contributing
If you would like to contribute to the Shell Scripting Toolkit, please follow these steps:

1. Fork the repository.
2. Create a new branch for your feature or bug fix.
3. Implement your changes and ensure that the existing scripts are not broken.
4. Test your changes thoroughly.
5. Submit a pull request with a detailed description of your changes.

We welcome contributions of all kinds, including new scripts, bug fixes, and improvements to the existing scripts.