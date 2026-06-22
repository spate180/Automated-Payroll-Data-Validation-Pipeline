import os

def read_sql_file(file_path: str):
    with open(file_path, "r") as f:
        content= f.read()
        return content

def get_sql_path(relative_path: str) -> str:
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    return os.path.join(base, relative_path)