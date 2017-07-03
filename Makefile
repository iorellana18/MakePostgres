.DEFAULT_GOAL := help

INS_DEPS := apt-get

############# Ayuda ######################
.PHONY: help

help:
	@echo "No hay ayuda aún :c"


############## Instalar postgresql 9.5 ##################

.PHONY: postgresql

postgresql:
	# Añade postgres apt store
	$ sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
	# Prerequisito
	$(INS_DEPS) install wget ca-certificates
	# Llave de repositorio
	$ wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
	# Actualiza
	$(INS_DEPS) update
	# Postgres
	$(INS_DEPS) install postgresql-9.5 postgresql-9.5-pgpool2
