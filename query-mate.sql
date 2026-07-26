WITH account AS (
  -- métricas de conta: LEFT JOIN pois nem toda conta tem sessão registrada
  SELECT 
    ss.date AS date,
    sp.country AS country,
    ac.is_unsubscribed AS is_unsubscribed,
    ac.send_interval AS send_interval,
    ac.is_verified AS is_verified,
    COUNT(DISTINCT ac.id) AS account_cnt
  FROM `DA.account` ac
  JOIN `DA.account_session` acs ON ac.id = acs.account_id
  LEFT JOIN `DA.session_params` sp ON acs.ga_session_id = sp.ga_session_id
  LEFT JOIN `DA.session` ss ON ss.ga_session_id = acs.ga_session_id
  GROUP BY 1,2,3,4,5
),
email_metrics AS (
  -- date = data do envio, não a de criação da conta
  SELECT 
    DATE_ADD(ss.date, INTERVAL es.sent_date DAY) AS date,
    sp.country AS country,
    ac.is_unsubscribed AS is_unsubscribed,
    ac.send_interval AS send_interval,
    ac.is_verified AS is_verified,
    COUNT(DISTINCT es.id_message) AS sent_msg,
    COUNT(DISTINCT eo.id_message) AS open_msg,
    COUNT(DISTINCT ev.id_message) AS visit_msg
  FROM `DA.email_sent` es
  LEFT JOIN `DA.email_open` eo ON es.id_message = eo.id_message
  LEFT JOIN `DA.email_visit` ev ON es.id_message = ev.id_message
  LEFT JOIN `DA.account` ac ON es.id_account = ac.id
  LEFT JOIN `DA.account_session` acs ON acs.account_id = ac.id
  LEFT JOIN `DA.session_params` sp ON acs.ga_session_id = sp.ga_session_id
  LEFT JOIN `DA.session` ss ON ss.ga_session_id = acs.ga_session_id
  GROUP BY 1,2,3,4,5
),
unionn AS (
  -- junta conta e e-mail, preenchendo com 0 as métricas que não existem em cada lado
  SELECT 
    acc.date, acc.country, acc.is_unsubscribed, acc.send_interval, acc.is_verified,
    acc.account_cnt,
    0 AS sent_msg, 0 AS open_msg, 0 AS visit_msg
  FROM account AS acc
  UNION ALL
  SELECT 
    em.date, em.country, em.is_unsubscribed, em.send_interval, em.is_verified,
    0 AS account_cnt,
    em.sent_msg, em.open_msg, em.visit_msg
  FROM email_metrics AS em
),
grouped AS(
  -- agrupa os resultados
  SELECT un.date, un.country, un.is_unsubscribed, un.send_interval, un.is_verified,
    SUM(un.account_cnt) AS account_cnt, SUM(un.sent_msg) AS sent_msg, SUM(un.open_msg) AS open_msg, SUM(un.visit_msg) AS visit_msg
  FROM unionn AS un
  GROUP BY 1,2,3,4,5),
totals AS (
  -- totais por país via window function, sem colapsar as linhas originais
  SELECT
    date, country, send_interval, is_verified, is_unsubscribed,
    account_cnt, sent_msg, open_msg, visit_msg,
    SUM(account_cnt) OVER (PARTITION BY country) AS total_country_account_cnt,
    SUM(sent_msg) OVER (PARTITION BY country) AS total_country_sent_cnt
  FROM grouped
  WHERE country IS NOT NULL -- exclui contas/e-mails sem sessão (sem país conhecido)
),
ranked AS (
  -- DENSE_RANK evita saltos de posição quando países empatam no total
  SELECT
    date, country, send_interval, is_verified, is_unsubscribed,
    account_cnt, sent_msg, open_msg, visit_msg,
    total_country_account_cnt,
    total_country_sent_cnt,
    DENSE_RANK() OVER (ORDER BY total_country_account_cnt DESC) AS rank_total_country_account_cnt,
    DENSE_RANK() OVER (ORDER BY total_country_sent_cnt DESC) AS rank_total_country_sent_cnt
  FROM totals
)
-- resultado final: top 10 em contas OU top 10 em e-mails enviados
SELECT
  date, country, send_interval, is_verified, is_unsubscribed,
  account_cnt, sent_msg, open_msg, visit_msg,
  total_country_account_cnt,
  total_country_sent_cnt,
  rank_total_country_account_cnt,
  rank_total_country_sent_cnt
FROM ranked
WHERE rank_total_country_account_cnt <= 10 
   OR rank_total_country_sent_cnt <= 10