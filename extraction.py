import pandas as pd

def categorize_data(lines):
    materials, versions, variabilities, users = [], [], [], []
    for i, line in enumerate(lines):
        if line.startswith('<version>') and i + 1 < len(lines) and lines[i + 1].isdigit():
            versions.append({'Version': lines[i + 1]})
        elif line.startswith('<Variabilite>'):
            variability = {'Parameters': []}
            for j in range(i + 1, len(lines)):
                if lines[j].startswith('</Variabilite>'):
                    break
                if lines[j].replace('.', '', 1).isdigit():
                    variability['Parameters'].append(lines[j])
            variabilities.append(variability)
        elif line and not line.startswith(('<', '#', '/', ' ')):
            if i + 1 < len(lines) and lines[i + 1].replace('.', '', 1).isdigit():
                materials.append({'Material': line, 'Characteristic': lines[i + 1]})
            elif not any(char.isdigit() for char in line):
                users.append({'User': line})
    return materials, versions, variabilities, users

file_path = './BIBLIOTHEQUE COMPOS.txt'

with open(file_path, 'r', encoding='utf-16') as file:
    lines = [line.strip() for line in file.readlines()]

materials, versions, variabilities, users = categorize_data(lines)

df_materials = pd.DataFrame(materials)
df_versions = pd.DataFrame(versions)
df_variabilities = pd.DataFrame(variabilities, columns=['Parameters']).explode('Parameters')
df_users = pd.DataFrame(users)

with pd.ExcelWriter('categorized_data.xlsx', engine='openpyxl') as excel_writer:
    df_materials.to_excel(excel_writer, sheet_name='Materials', index=False)
    df_versions.to_excel(excel_writer, sheet_name='Versions', index=False)
    df_variabilities.to_excel(excel_writer, sheet_name='Variabilities', index=False)
    df_users.to_excel(excel_writer, sheet_name='Users', index=False)
v