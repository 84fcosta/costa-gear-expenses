# Costa Gear Business Expenses App, Guia de Deploy

Este app segue a mesma lógica do app anterior `costa-gear-v2.zip`:

- React
- Supabase como banco de dados
- Vercel para publicar
- Exportação Excel com a biblioteca `xlsx`
- Visual Costa Gear com header escuro, logo e command bar

## 1. O que o app faz

### Expenses
Registra despesas do business com:

- Data
- Fornecedor
- Descrição
- Categoria
- Valor total em CAD
- Percentual de uso do business
- Valor dedutível
- Forma de pagamento
- Link do recibo
- Status do recibo
- Observações
- Indicação se é compra de ativo

### Assets (CCA)
Registra ativos separados das despesas normais:

- Asset ID
- Nome do ativo
- Data de compra
- Fornecedor
- Custo
- Classe CCA
- Taxa CCA
- Percentual de uso no business
- Custo de uso business
- Estimativa de CCA do primeiro ano
- Link do recibo
- Status

A estimativa usa:

`business cost × CCA rate × 50%`

Isso considera a regra geral de meio ano. Confirme a classe e o cálculo final com o contador antes de declarar.

### Tax Report
Gera um arquivo Excel com:

- Tax Summary
- By Category
- Expense Details
- Assets CCA

## 2. Criar o banco no Supabase

1. Acesse Supabase
2. Crie um projeto novo
3. Vá em **SQL Editor**
4. Abra o arquivo `supabase-setup.sql`
5. Copie todo o conteúdo
6. Clique em **Run**

Isso cria as tabelas:

- `expenses`
- `assets`

E insere os dados iniciais baseados no Excel que você compartilhou.

## 3. Configurar as chaves do Supabase

No Supabase:

1. Vá em **Project Settings**
2. Clique em **API**
3. Copie:
   - Project URL
   - anon public key

Você vai usar essas duas variáveis:

```txt
REACT_APP_SUPABASE_URL
REACT_APP_SUPABASE_ANON_KEY
```

## 4. Rodar localmente

Dentro da pasta do app:

```bash
npm install
```

Crie um arquivo `.env` na raiz do projeto:

```txt
REACT_APP_SUPABASE_URL=https://seu-projeto.supabase.co
REACT_APP_SUPABASE_ANON_KEY=sua-chave-anon
```

Depois rode:

```bash
npm start
```

## 5. Publicar no Vercel

1. Suba os arquivos para um repositório GitHub
2. No Vercel, clique em **Add New Project**
3. Selecione o repositório
4. Framework: **Create React App**
5. Adicione as variáveis de ambiente:
   - `REACT_APP_SUPABASE_URL`
   - `REACT_APP_SUPABASE_ANON_KEY`
6. Clique em **Deploy**

## 6. Observação importante sobre segurança

O setup segue o mesmo modelo simples do app anterior, com acesso público de leitura e escrita no Supabase.

Isso é prático para teste, mas não é seguro para dados reais do business se o link for compartilhado com outras pessoas.

Antes de usar com dados sensíveis, recomendo adicionar autenticação ou restringir as políticas do Supabase.
