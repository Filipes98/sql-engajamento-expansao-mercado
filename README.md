# Análise de Engajamento e Expansão de Mercado (SQL/BigQuery)

Projeto final de consulta analítica sobre atividade de e-mail marketing
e engajamento em um cenário de e-commerce global.

## O que o projeto faz
- Consolida dados de contas, sessões e envios de e-mail usando múltiplas CTEs
- Aplica window functions (SUM() OVER, DENSE_RANK()) para ranquear países
  por volume de contas e de e-mails enviados
- Usa LEFT JOIN encadeados e UNION ALL para unir eventos de granularidades
  diferentes sem perder registros

## Técnicas aplicadas
CTEs (Common Table Expressions), Window Functions, LEFT JOIN, UNION ALL,
tratamento de duplicidade com COUNT(DISTINCT)

## Case completo
A análise completa, com contexto de negócio, insights e uma reflexão
sobre arquitetura de dados, está no meu portfólio:
[Filipe Santos — Portfólio de Análise de Dados](https://beryl-zenith-6a8.notion.site/Filipe-Santos-Portf-lio-de-An-lise-de-Dados-910309076ece4e4585b7eb6a031005d4)
