#!/bin/bash

# Script de compilation pour MONCOMBLE_projet.s
# Auteur: Jules MONCOMBLE

# Couleurs pour l'affichage
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}[+] Compilation du projet de Jules MONCOMBLE${NC}"

# Vérifier si nasm est installé
if ! command -v nasm &> /dev/null; then
    echo -e "${RED}[-] NASM n'est pas installé. Installation...${NC}"
    sudo apt-get update
    sudo apt-get install -y nasm
fi

echo -e "${BLUE}[+] Compilation du fichier source...${NC}"
# Compiler le fichier source en fichier objet
if nasm -f elf64 MONCOMBLE_projet.s -o MONCOMBLE_projet.o; then
    echo -e "${GREEN}[+] Compilation réussie !${NC}"
else
    echo -e "${RED}[-] Erreur lors de la compilation${NC}"
    exit 1
fi

echo -e "${BLUE}[+] Édition des liens...${NC}"
# Lier le fichier objet pour créer l'exécutable
if ld MONCOMBLE_projet.o -o MONCOMBLE_projet; then
    echo -e "${GREEN}[+] Édition des liens réussie !${NC}"
else
    echo -e "${RED}[-] Erreur lors de l'édition des liens${NC}"
    exit 1
fi

echo -e "${BLUE}[+] Configuration des permissions...${NC}"
# Rendre le fichier exécutable
if chmod +x MONCOMBLE_projet; then
    echo -e "${GREEN}[+] Permissions configurées !${NC}"
else
    echo -e "${RED}[-] Erreur lors de la configuration des permissions${NC}"
    exit 1
fi

echo -e "${GREEN}[+] Compilation terminée avec succès !${NC}"
echo -e "${BLUE}[+] Pour exécuter le programme, utilisez: ./MONCOMBLE_projet${NC}"
echo -e "${BLUE}[+] Si vous rencontrez des problèmes de permissions: sudo ./MONCOMBLE_projet${NC}"

exit 0
