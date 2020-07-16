CREATE USER explorer WITH PASSWORD 'explorer';
GRANT CONNECT ON DATABASE iroha_data TO explorer;
GRANT USAGE ON SCHEMA public TO explorer;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO explorer;
