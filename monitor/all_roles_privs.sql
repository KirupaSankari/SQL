 select
   lpad(' ', 2*level) || granted_role "User, his roles and privileges"
 from
   (
   /* THE USERS */
     select
       null     grantee,
       username granted_role
     from
       dba_users
     where
       username like upper('&Schema_name')--Change the username accordingly
   /* THE ROLES TO ROLES RELATIONS */
   union
     select
       grantee,
       granted_role
     from
       dba_role_privs
   /* THE ROLES TO PRIVILEGE RELATIONS */
   union
     select
       grantee,
       privilege
     from
       dba_sys_privs
   )
 start with grantee is null
 connect by grantee = prior granted_role
/
