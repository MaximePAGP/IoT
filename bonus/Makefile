up:
	ansible-playbook -i ./ansible/inventory.ini ./ansible/playbook.yml

# 	source ./.venv/bin/activate
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
