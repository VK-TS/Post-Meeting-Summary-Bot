from pathlib import Path

PROMPTS_DIR = Path("prompts")

def load_prompt(filename: str, **kwargs)->str:
    prompt_path = PROMPTS_DIR / filename

    with open(prompt_path, "r", encoding="utf-8") as file:
        template = file.read()
    
    return template.format(**kwargs)