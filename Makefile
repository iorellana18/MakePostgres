d.DEFAULT_GOAL := help

INS_DEPS := apt-get

############# Ayuda ######################
.PHONY: help

help:
        @echo "No hay ayuda"


############## Instalar postgresql 9.5 ##################

.PHONY: postgresql

postgresql:
        #
        # Añade postgres apt store
        #
        $ sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
        #
        # Prerequisito
        #
        $(INS_DEPS) install wget ca-certificates
        #
        # Llave de repositorio
        #
        $ wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
        #
        # Actualiza
        #
        $(INS_DEPS) update
        #
        # Postgres
        #
        $(INS_DEPS) install postgresql-9.5 postgresql-9.5-pgpool2
        #
	# Comienza el servicio
        #
        $ service postgresql start
        #
        # Entrar en sesión interactiva de PostgreSQL
        #
        #####################################################################
        #
        # # Se debe alterar password de usuario postgres
        # # Para esto se debe ejecutar en la consola de postgres lo siguiente
        # ALTER USER postgres WITH PASSWORD '<password>';
        # # Luego  crear un  usuario con privilegios de replicación
        # CREATE ROLE replication WITH REPLICATION PASSWORD '<replicationpassword>' LOGIN;
        # # Salir
        # \q
        #
        #####################################################################
        $ sudo -i -u postgres psql
        # Creando pass file
        $ touch /var/lib/postgresql/.pgpass
        $ echo "*:*:*:replication:<replicationpassword>">/var/lib/postgresql/.pgpass
        $ chown postgres:postgres /var/lib/postgresql/.pgpass
        $ chown 0600 /var/lib/postgresql/.pgpass
        #
        # Modificar postgresql.conf
        #
        $ sed -i '59s/localhost/*/' /etc/postgresql/9.5/main/postgresql.conf
        $ sed -i '59s/#//' /etc/postgresql/9.5/main/postgresql.conf
        $ sed -i '63s/5432/5433/' /etc/postgresql/9.5/main/postgresql.conf
        #
        # Modificar pg_hba.conf
        #
        $ sed -i '$s/$/\nhost  replication     replication     <IP_MASTER>/32          md5/' /etc/postgresql/9.5/main/pg_hba.conf
        $ sed -i '$s/$/\nhost  replication     replication     <IP_SLAVE>/32          md5/' /etc/postgresql/9.5/main/pg_hba.conf
        $ sed -i '$s/$/\nhost  replication     replication     <IP_VIRTUAL>/32          md5/' /etc/postgresql/9.5/main/pg_hba.conf



