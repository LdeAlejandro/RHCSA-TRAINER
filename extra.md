### 🧱 3️⃣ Exemplos comuns de permissões

| Octal | Permissão  | Descrição |
|--------|-------------|------------|
| **777** | rwxrwxrwx | Todos podem tudo (evite usar) |
| **755** | rwxr-xr-x | Dono pode tudo; outros só leem e executam (scripts, pastas) |
| **700** | rwx------ | Somente o dono pode acessar |
| **644** | rw-r--r-- | Dono pode ler/escrever; outros só leem (arquivos normais) |
| **600** | rw------- | Somente o dono pode ler e escrever |
| **400** | r-------- | Somente o dono pode ler |
| **000** | ---------- | Ninguém tem acesso |

---

### 🔢 Tabela de valores de permissões

| Permissão | Letra | Valor |
|------------|--------|--------|
| **read** | r | 4 |
| **write** | w | 2 |
| **execute** | x | 1 |

Você soma os valores de cada permissão para o grupo correspondente.

---

### 🧮 Exemplo de cálculo

| Tipo | r | w | x | Soma | Significado |
|------|---|---|---|------|--------------|
| **Owner** | 4 | 2 | 0 | **6** | read + write |
| **Group** | 4 | 0 | 0 | **4** | read only |
| **Others** | 4 | 0 | 0 | **4** | read only |