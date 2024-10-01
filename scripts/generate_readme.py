import os
import sys
import glob
import anthropic
import openai

# Environment variables
AI_PROVIDER = os.environ['AI_PROVIDER'].lower()
AI_MODEL = os.environ['AI_MODEL']

def get_file_contents(file_path):
    with open(file_path, 'r') as file:
        return file.read()

def scan_repository():
    file_types = {
        'Terraform Files': '**/*.tf',
        'Terraform Variables Files': '**/*.tfvars',
        'Shell Scripts': '**/*.sh',
        'Python Scripts': '**/*.py'
    }
    
    repo_content = ""
    
    for file_type, glob_pattern in file_types.items():
        files = glob.glob(glob_pattern, recursive=True)
        if files:
            repo_content += f"\n{file_type}:\n"
            for file in files:
                repo_content += f"\n--- {file} ---\n"
                repo_content += get_file_contents(file)
    
    return repo_content.strip()

def generate_readme_with_anthropic(prompt):
    client = anthropic.Anthropic(api_key=os.environ['ANTHROPIC_API_KEY'])
    message = client.messages.create(
        model=AI_MODEL,
        max_tokens=4000,
        messages=[{"role": "user", "content": prompt}]
    )
    return message.content[0].text

def generate_readme_with_openai(prompt):
    client = openai.OpenAI(api_key=os.environ['OPENAI_API_KEY'])
    response = client.chat.completions.create(
        model=AI_MODEL,
        messages=[{"role": "user", "content": prompt}],
        max_tokens=4000
    )
    return response.choices[0].message.content

def generate_readme():
    try:
        repo_content = scan_repository()
        
        if not repo_content:
            print("No .tf, .tfvars, .sh, or .py files found in the repository.")
            return
        
        prompt = f"""Based on the following repository content, generate a comprehensive README.md file. 
        Include sections for Project Description, Installation, Usage, and Contributing. 
        Only include information about file types that are present in the repository content provided.
        Make sure to accurately reflect the purpose and functionality of the files present.
        Group related files and their descriptions logically.
        If Terraform files are present, explain the infrastructure being provisioned.
        If shell scripts are present, explain their purpose and how to use them.
        If Python scripts are present, explain their functionality and how they relate to the project.
        
        Repository Content:
        {repo_content}
        
        Please generate the README.md content now:"""

        if AI_PROVIDER == 'anthropic':
            if 'ANTHROPIC_API_KEY' not in os.environ:
                raise ValueError("ANTHROPIC_API_KEY is not set")
            readme_content = generate_readme_with_anthropic(prompt)
        elif AI_PROVIDER == 'openai':
            if 'OPENAI_API_KEY' not in os.environ:
                raise ValueError("OPENAI_API_KEY is not set")
            readme_content = generate_readme_with_openai(prompt)
        else:
            raise ValueError(f"Unsupported AI provider: {AI_PROVIDER}")
        
        with open('README.md', 'w') as f:
            f.write(readme_content)
        
        print(f"README.md generated successfully using {AI_PROVIDER.capitalize()} ({AI_MODEL}).")
    except Exception as e:
        print(f"Error generating README: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    generate_readme()