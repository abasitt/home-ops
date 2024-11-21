task ansible:ping cluster=playground
task ansible:run cluster=playground playbook=cluster-prepare
task ansible:run cluster=playground playbook=cluster-installation
