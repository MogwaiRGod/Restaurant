#!/bin/bash

###########################			UTILISATION
#
###		FICHIER TEXTE DU MENU
# 1) /!\ Ne pas mettre de lignes vides dans le documents
# 2) /!\ Ne pas enlever le tiret devant les titres des parties du menu (-Entrées...)
# 3) /!\ Ne pas mettre le signe euro (€) après le prix
# 4) /!\ Ne pas changer l'ordre des titres, ou ajouter des titres
# 5) Toujours écrire les plats sous la forme : "plat prix" 
# 6) /!\ Ne jamais mettre de tiret (-) devant le nom d'un plat
# 7) /!\ Ne pas mettre de plat ou boisson sans prix (écrire 0 si c'est cadeau)
# 8) Vous pouvez ajouter des plats, en supprimer, les modifier (de même que les prix) en respectant les conditions précédentes
#
###		INTERFACE
# 1) (A) Pour annuler la commande
# 2) (ENTREE) Pour valider le plat et quantité entrés
# 3) (T) Pour valider la commande
# 4) (Q) Pour éteindre le terminal
# La casse n'est pas importante
#
############################		COMMANDES
### L'historique des commandes est disponible dans commandes.txt. /!\ Ne pas modifier ce fichier /!\
### Le numéro de la commande est à la fin de la facture et chacune est séparée par une succession d'astérisques
### La note à donner au client qui vient de passer commande est dans note.txt




##########################             INITIALISATION

menu=menu_au_bon_gloumiam.txt;

#	on va découper le document texte original afin de récupérer les différentes informations
# cela nous sera utile pour l'affichage mais aussi pour les calculs

#  on détermine les numéros de lignes où afficher les titres du menu (entrées, plats...)
function index_ligne() {
	grep -n $1 $menu | sed "s:[^[:digit:]]::g";
	return 0;
}

index_plats=$(index_ligne "\-Plats");
index_desserts=$(index_ligne "\-Desserts");
index_boissons=$(index_ligne "\-Boissons");

#  sélectionne uniquement le nom du plat et son prix depuis le menu
#  <=> on supprime les titres (entrées...)
grep ^[^-] $menu > plats.txt;

#  total de plats dans le menu = nombre de lignes
nombre_plats=$(wc -l plats.txt | sed "s:plats.txt::");

#  deux listes : l'une avec le nom des plats, l'autre avec leur prix
#  les deux ont des index qui se réfèrent au même plat
declare -a tab_plats=("");
declare -a tab_prix=("");

#  fonction qui lit ligne par ligne le menu obtenu
#  et remplit les tableaux comme convenu
function initMenu () {

	for i in $(seq 1 1 $nombre_plats);
	do
		nom_plats[$i]=$(sed "${i}q;d" plats.txt | sed "s:[[:digit:]]::g" | tr -dc [[:print:]]); #noms des plats
		tab_plats[$i]=$(sed "${i}q;d" plats.txt | tr -dc [[:print:]]); #noms des plats + le prix
		tab_prix[$i]=$(sed "${i}q;d" plats.txt | sed "s:[^[:digit:]]::g"| tr -dc [[:print:]]); #les prix
	done
	return 1;
}



####################################################          LE MENU

function afficherMenu() {

	initMenu;
	clear;

	#  affiche le menu de manière statique car au secours
	cadre="#######################################";
	separation="#\n#-------------------------------------#";

	tput cup 0 0; echo $cadre; #on fait démarrer le menu tout en haut à gauche
	echo -e "#          Au Bon GlouMiam            #\n"$separation"\n#-Entrées                             #\n#                                     #";

	#affiche par itération chaque ligne du menu
	for i in $(seq 1 1 $nombre_plats);
	do
		#problème : soit je supprime les caractères invisibles qui restent dans mes tableaux, auquel cas je peux tout afficher sur une ligne MAIS les accents ne sont plus pris en compte
		#soit je garde les caractères invisibles auquel cas je ne peux pas tout afficher car ça crée un bug qui ramène une partie de la chaîne au début etc.
		if (( $i == $index_plats-1 )); then
			echo -e $separation"\n#-Plats                               #\n#                                     #";
		elif (( $i == $index_desserts-2 )); then
			echo -e $separation"\n#-Desserts                            #\n#                                     #";
		elif (( $i == $index_boissons-3 ));then
			echo -e $separation"\n#-Boissons                            #\n#                                     #";
		fi
			ligne_plat="#- "$i" "${nom_plats[$i]}"   "${tab_prix[$i]}"€\t#";
			echo -e $ligne_plat;
			#tput cup $i 38; echo -e "#";

			#avec tput, c'set mis n'importe comment et je n'ai plus le temps de réfléchir lol
			#tput cup $((i+5)) 0; echo -e $ligne_plat;
			#tput cuSp $((i+5)) 33; echo -e ${tab_prix[$i]}"€    ";
			#tput cup $((i+5)) 38; echo -e "#";

	done

	echo -e "#\n"$cadre;

	return 2;
}



###############################################             L'INTERFACE

#	fonction qui (ré)initialise la commande pour le (prochain) client
function initCommande () {
	cmd_plat=();
	cmd_qte=();
	no_plat=0;
	quantite=0;

	#	création du document texte qui contient la note du client en cours
	separation_cmds="******************************************************************************\n"
	entete="Numéro plat\tPlat\t\t\t\t\tQuantité\tPrix";
	echo -e $separation_cmds$entete > note.txt;

	#	si le terminal n'a jamais été utilisé, on initialise le numéro de la première commande
	if [[ ! -f "commandes.txt" ]]; then
		no_cmd=1;
	else
	#	sinon on récupère le numéro de la dernière commande et on l'incrémente
		no_cmd=$(($(cat commandes.txt | tail -n1)+1));
	fi

	return 3;
}

function attendre (){
	sleep 1;
	return 4;
}

function interface () {

	annulee="COMMANDE ANNULEE";

	while [ true ]; do

		initCommande;
		afficherMenu;

		notice="\nEntrer la commande n° : "$no_cmd"\nEntrer le numéro du plat choisi suivi de sa quantité ; appuyer sur (ENTREE) pour valider.\n(T) pour envoyer la commande.\n(A) Pour annuler.\n(Q) Pour éteindre le terminal."
		echo -e $notice;

		while [[ $no_plat != "T" && $no_plat != "t" ]]; do

			read -p ">>>	" no_plat quantite;

			if [[ $no_plat =~ [tT] ]]; then
				echo "Commande enregistrée"; attendre;

			# Commande annulée => n'enregistre rien et reprend du début
			elif [[ $no_plat =~ [Aa] ]]; then
				echo $annulee; attendre;
				echo -e $separation_cmds$annulee"\nCommande n°\n"$no_cmd >> commandes.txt;
				interface;

			# Eteint le terminal
			elif [[ $no_plat =~ [Qq] ]]; then
				exit 0;

			# Cas d'erreur : n'enregistre pas l'entrée si elle est incorrecte ou manquante et en redemande une
			elif [[ $no_plat =~ [^[:digit:]] || $no_plat = " " || $quantite = "" || $quantite =~ [^[:digit:]] ]]; then
				echo "Entrée incorrecte";

			else
				cmd_plat+=($no_plat);
				cmd_qte+=($quantite);
			fi
		done

		note;

	done
	return 5;
}



######################################################		FACTURE


#	Fonction qui calcule la note
#	L'enregistre dans un fichier texte
#	Et l'ajoute au fichier qui contient toutes les commandes
function note () {

	tva=1167; #<=> TVA à 11,67%
	total_ht=0; q=0; total=0; part_tva=0;

	for i in ${cmd_plat[@]};
	do
		((total_ht+=$((${tab_prix[$i]}*${cmd_qte[$q]}))));

		#	enregistre la facture dans un fichier
		#	malheureusement, les colonnes ne sont pas alignées mais je n'ai plus le temps lol
		echo -e $i "\t\t"${nom_plats[$i]}"\t"${cmd_qte[$q]}"\t\t"${tab_prix[$i]}"€" >> note.txt;
		((q++));
	done

	#	ajout de la TVA dans le total
	#	bash ne supporte pas les flottants donc obligée de faire deux opérations + le résultat est arrondi à un entier...
	total=$((total_ht*tva));
	total=$((total / 1000));
	part_tva=$((total-total_ht));

	echo -e "\nTOTAL\t"$total"€ (Dont "$part_tva"€ TVA)\nMerci, à bientôt !\n\nCommande n°\n"$no_cmd >> note.txt;
	cat note.txt >> commandes.txt;

	return 6;
}



###########################################				DEBUT DU SCRIPT

interface;

exit 0;


