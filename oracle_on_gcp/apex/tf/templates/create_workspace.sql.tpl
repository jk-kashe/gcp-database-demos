WHENEVER SQLERROR EXIT SQL.SQLCODE;
-- 1) Create a dedicated schema for the workspace
DECLARE
  l_db_username VARCHAR2(30) := '${apex_schema}';
  l_db_password VARCHAR2(30) := "${oracle_password}";
BEGIN
  EXECUTE IMMEDIATE 'CREATE USER '||l_db_username||
                    ' IDENTIFIED BY "'||l_db_password||'" '||
                    ' DEFAULT TABLESPACE USERS'||
                    ' QUOTA UNLIMITED ON USERS';

  EXECUTE IMMEDIATE 'GRANT create session, create table, create sequence, create view TO ${apex_schema}';
END;
/
-- 2) Create the APEX workspace and map it to the schema
DECLARE
  l_workspace   VARCHAR2(30) := '${apex_workspace}';
  l_db_username VARCHAR2(30) := '${apex_schema}';
BEGIN
  apex_instance_admin.add_workspace(
    p_workspace      => l_workspace,
    p_primary_schema => l_db_username );
END;
/
-- 3) Create a workspace admin account (APEX user) in that workspace
DECLARE
  l_workspace       VARCHAR2(30) := '${apex_workspace}';
BEGIN
  apex_util.set_workspace(p_workspace => l_workspace);

  apex_util.create_user(
    p_user_name                    => '${apex_user}',
    p_web_password                 => '${oracle_password}',
    p_developer_privs              => 'ADMIN:CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL',
    p_email_address                => '${user_email}',
    p_default_schema               => '${apex_schema}',
    p_change_password_on_first_use => 'Y');
END;
/
COMMIT;
/
EXIT;
/
