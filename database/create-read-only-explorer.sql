CREATE ROLE explorer WITH LOGIN PASSWORD 'explorer';
GRANT CONNECT ON DATABASE iroha_data TO explorer;
GRANT USAGE ON SCHEMA public TO explorer;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO explorer;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO explorer;