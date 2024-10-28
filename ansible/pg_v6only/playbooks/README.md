task ansible:ping cluster=pg_v6only
task ansible:run cluster=pg_v6only playbook=cluster-prepare
task ansible:run cluster=pg_v6only playbook=cluster-installation
