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

### Calculo umask

⚙️ 2️⃣ Como isso vira binário

Cada permissão é um número de 3 bits, que pode ir de 000 (sem nada) até 111 (tudo).

Binário	Octal	rwx	Significado
000	0	---	nenhuma permissão
001	1	--x	só execução
010	2	-w-	só escrita
011	3	-wx	escrita + execução
100	4	r--	só leitura
101	5	r-x	leitura + execução
110	6	rw-	leitura + escrita
111	7	rwx	leitura + escrita + execução


Permissões especiais
Permissão	Valor	chmod simbólico	Efeito
SUID	4000	u+s	Executa com o UID (proprietário) do arquivo.
SGID	2000	g+s	Executa com o GID (grupo) do arquivo. Em diretórios, novos arquivos herdam o grupo.
Sticky Bit	1000	+t	Em diretórios, apenas o dono do arquivo (ou root) pode removê-lo.