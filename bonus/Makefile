up:
	vagrant up

ansible:
	ansible-playbook -i ./ansible/inventory.ini ./ansible/playbook.yml

re:
	make fclean
	make up

stop:
	vagrant halt

reload:
	vagrant reload

fclean:
	vagrant destroy -f


.PHONY: up re stop reload fcleean ansible
