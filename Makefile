d.DEFAULT_GOAL := help

INS_DEPS := apt-get

password = pass
replicationpassword = pass
replicationuser = replication
slotname = slotname

############### Directorios ######################
# Configuración de postgresql
config = /etc/postgresql/9.5/main
# Scripts sql
sql = /etc/postgresql/9.5/main/sql
# Scripts pgpool
poolsql = pgpool-II-3.5.2/src/sql/
# Postgresql data
data = /var/lib/postgresql/9.5/main
# Pgpool main
pgpool = /etc/pgpool2/3.5.2/
# Pgpool share
sharepool = /usr/share/pgpool2/3.5.2/

############# Ayuda ######################
.PHONY: help

help:
	@echo "No hay ayuda"


############## Instalar y configurar postgresql 9.5 ##################

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
	# Archivos de respaldo
	#
	$ cp $(config)/pg_hba.conf $(config)/pg_hba.conf.copy
	$ cp $(config)/postgresql.conf $(config)/postgresql.conf.copy
	#
	# Confiar en postgres
	#
	$ sed -i '85s/peer/trust/' $(config)/pg_hba.conf
	#
	# Comienza servicio
	#
	$ service postgresql start
	#
	# Alterar usuario con contraseña
	#
	$ psql -c "ALTER USER postgres WITH PASSWORD '$(password)';" -U postgres
	#
	# Crear usuario con privilegios de replicación
	#
	$ psql -c "CREATE ROLE $(replicationuser) WITH REPLICATION PASSWORD '$(replicationpassword)' LOGIN;" -U postgres
	#
	# Creando pass file
	#
	$ touch /var/lib/postgresql/.pgpass
	$ echo "*:*:*:$(replicationuser):$(replicationpassword)">/var/lib/postgresql/.pgpass
	$ chown postgres:postgres /var/lib/postgresql/.pgpass
	$ chown 0600 /var/lib/postgresql/.pgpass
	#
	# Modificar postgresql.conf
	#
	$ sed -i '59s/localhost/*/' $(config)/postgresql.conf
	$ sed -i '59s/#//' $(config)/postgresql.conf
	$ sed -i '63s/5432/5433/' $(config)/postgresql.conf
	#
	# Crear archivos de respaldo
	#
	$(MAKE) failover
	#
	# Modificar pg_hba.conf
	#

############## Instalar y configurar pgpool-II ##################

.PHONY: pgpool

pgpool:
	$(INS_DEPS) update
	$(INS_DEPS) install libpq-dev make
	#
	# Configurando pgpool-II
	#
	$ mkdir /etc/pgpool2/
	$ mkdir $(pgpool)
	$ mv $(sharepool)etc/pcp.conf.sample $(pgpool)
	$ mv $(sharepool)etc/pgpool.conf.sample $(pgpool)
	$ mv $(sharepool)etc/pgpool.conf.sample-master-slave $(pgpool)
	$ mv $(sharepool)etc/pgpool.conf.sample-replication $(pgpool)
	$ mv $(sharepool)etc/pgpool.conf.sample-stream $(pgpool)
	$ mv $(sharepool)etc/pool_hba.conf.sample $(pgpool)
	$ cp $(sharepool)bin/pcp_attach_node /usr/sbin/
	$ cp $(sharepool)bin/pcp_detach_node /usr/sbin/
	$ cp $(sharepool)bin/pcp_node_count /usr/sbin/
	$ cp $(sharepool)bin/pcp_node_info /usr/sbin/
	$ cp $(sharepool)bin/pcp_pool_status /usr/sbin/
	$ cp $(sharepool)bin/pcp_proc_count /usr/sbin/
	$ cp $(sharepool)bin/pcp_proc_info /usr/sbin/
	$ cp $(sharepool)bin/pcp_promote_node /usr/sbin/
	$ cp $(sharepool)bin/pcp_recovery_node /usr/sbin/
	$ cp $(sharepool)bin/pcp_stop_pgpool /usr/sbin/
	$ cp $(sharepool)bin/pcp_watchdog_info /usr/sbin/
	$ cp $(sharepool)bin/pg_md5 /usr/sbin/
	$ cp $(sharepool)bin/pgpool /usr/sbin/
	# Create SQL scripts directory:
	$ mkdir $(sql)
	$ cp $(poolsql)insert_lock.sql $(sql)/
	$ cp $(poolsql)pgpool_adm/pgpool_adm.control /usr/share/postgresql/9.5/extension/
	$ cp $(poolsql)pgpool_adm/pgpool_adm--1.0.sql /usr/share/postgresql/9.5/extension/
	$ cp $(poolsql)pgpool_adm/pgpool_adm.sql.in $(sql)/pgpool_adm.sql
	$ cp $(poolsql)pgpool-recovery/pgpool_recovery.control /usr/share/postgresql/9.5/extension/
	$ cp $(poolsql)pgpool-recovery/pgpool_recovery--1.1.sql /usr/share/postgresql/9.5/extension/
	$ cp $(poolsql)pgpool-recovery/pgpool-recovery.sql.in $(sql)/pgpool-recovery.sql
	$ cp $(poolsql)pgpool-recovery/uninstall_pgpool-recovery.sql $(sql)/
	$ cp $(poolsql)pgpool-regclass/pgpool_regclass.control /usr/share/postgresql/9.5/extension/
	$ cp $(poolsql)pgpool-regclass/pgpool_regclass--1.0.sql /usr/share/postgresql/9.5/extension/
	$ cp $(poolsql)pgpool-regclass/pgpool-regclass.sql.in $(sql)/pgpool-regclass.sql
	$ cp $(poolsql)pgpool-regclass/uninstall_pgpool-regclass.sql $(sql)/
	#
	# Falta configurar archivos
	#
	#$ chown postgres:postgres -R $(sql)
	#
	# Configurar scripts
	#
	#$ update-rc.d pgpool2 defaults
	#$ update-rc.d pgpool2 disable

############## Configuración de servidor maestro  ##################

.PHONY: master

master:
	$ touch $(config)/im_the_master
	#
	# Configurando postgresql.conf
	#
	$ rm $(config)/postgresql.conf
	$ cp $()/repltemplates/postgresql.conf.primary $(config)/postgresql.conf
	$ sudo service postgresql restart
	#
	# Crear slot de replicación
	#
	$ psql -c "SELECT * FROM pg_create_physical_replication_slot('$(slotname)');" -U postgres


############## Configuración de servidor esclavo ##################

.PHONY: slave

slave:
	$ touch $(config)/im_slave
	#
	# Configurando postgresql.conf
	#
	$ rm $(config)/postgresql.conf
	$ cp $(config)/repltemplates/postgresql.conf.standby $(config)/postgresql.conf
	$ sudo service postgresql restart
	#
	# Borrar directorio de datos
	#
	$ sudo -H -u postgres bash -c 'rm -rf $(data)'
	#
	# Conectarse con servidor maestro
	#
	$ sudo -H -u postgres bash -c 'pg_basebackup -v -D main -R -P -h <IP_MASTER> -p 5433 -U $(replicationuser)'
	#
	#  Configurando recovery.conf
	#
	$ touch $(data)/recovery.conf
	$ echo "standby_mode = 'on'">>$(data)/recovery.conf
	$ echo "primary_slot_name = '<slotname>'">>$(data)/recovery.conf
	$ echo "primary_conninfo = 'host=<IP_MASTER> port=5433 user=replication password=$(replicationpassword)'">>$(data)/recovery.conf
	$ echo "trigger_file = '$(config)/im_the_master'">>$(data)/recovery.conf

############## Configuración failover ##################

.PHONY: failover

failover:
	#
	# Crear directorio con archivos de configuración
	#
	$ mkdir $(config)/repltemplates
	$ cp $(config)/postgresql.conf $(config)/repltemplates/postgresql.conf.primary
	$ cp $(config)/postgresql.conf $(config)/repltemplates/postgresql.conf.standby
	#
	# Configurando postgresql.conf.primary
	#
	$ sed -i '171s/#//' $(config)/repltemplates/postgresql.conf.primary
	$ sed -i '171s/minimal/hot_standby/' $(config)/repltemplates/postgresql.conf.primary
	$ sed -i '222s/#//' $(config)/repltemplates/postgresql.conf.primary
	$ sed -i '222s/0/3/' $(config)/repltemplates/postgresql.conf.primary
	$ sed -i '227s/#//' $(config)/repltemplates/postgresql.conf.primary
	$ sed -i '227s/0/3/' $(config)/repltemplates/postgresql.conf.primary
	#
	# Configurando postgresql.conf.standby
	#
	$ sed -i '245s/#//' $(config)/repltemplates/postgresql.conf.standby
	$ sed -i '245s/off/on/' $(config)/repltemplates/postgresql.conf.standby
	$ sed -i '255s/#//' $(config)/repltemplates/postgresql.conf.standby
	$ sed -i '255s/off/on/' $(config)/repltemplates/postgresql.conf.standby
	#
	# Permisos
	#
	$ chown postgres:postgres $(config)/pg_hba.conf
	$ chown postgres:postgres -R $(config)/repltemplates
	#
	# Directorio para scripts automáticos
	#
	$ mkdir $(config)/replscripts
	$ cp replscripts/disable_postgresql.sh $(config)/replscripts/disable_postgresql.sh
	$ cp replscripts/promote.sh $(config)/replscripts/promote.sh
	$ cp replscripts/create_slot.sh $(config)/replscripts/create_slot.sh
	$ cp replscripts/initiate_replication.sh $(config)/replscripts/initiate_replication.sh
	$ chown postgres:postgres -R $(config)/replscripts
	$ chmod 0744 -R $(config)/replscripts
	$ sudo service postgresql restart
############## Archivos de configuración iniciales  ##################

.PHONY: restart

restart:
	$ rm $(config)/postgresql.conf
	$ cp $(config)/postgresql.conf.copy $(config)/postgresql.conf
	$ rm $(config)/pg_hba.conf
	$ cp $(config)/pg_hba.conf.copy $(config)/pg_hba.conf



############## Volver a estado inicial  ##################

.PHONY: clean

clean:
	#
	# Eliminar postgresql
	#
	$ sudo service postgresql stop
	$(INS_DEPS) --purge remove postgresql\*
	$ rm -r /etc/postgresql/
	$ rm -r /var/lib/postgresql/
	#
	# Eliminar pgpool
	#
	$(INS_DEPS) remove --auto-remove pgpool2
	$(INS_DEPS) purge pgpool2
	$(INS_DEPS) purge --auto-remove pgpool2
	$ rm -r /etc/pgpool2/
