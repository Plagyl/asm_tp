Jules MONCOMBLE - 4SI4

Un projet d'assembleur x86_64 permettant de stocker des données chiffrées directement en RAM.
Ce projet implémente un "coffre-fort mémoire" qui permet de stocker des chaînes de caractères en mémoire avec un chiffrement XOR. 
L'utilisateur peut définir sa propre clé de chiffrement et interagir avec le programme via une interface en ligne de commande intuitive.

J'ai fais ce projet suite à notre disscussion vis à vis de mon projet annuel de chiffrement de RAM
Ce n'est pas exactement ce dont j'ai besoin pouir mon projet car ce sera en rust au niveau du kernel, mais c'est une grosse pierre pour mon projet quand même.

J'ai bien sûr utilisé des IA pour la réalisation de tous ces codes, ayant débuté l'assembleur cette année cela m'a permi d'aller beaucoup plus vite et beaucoup plus loin.
J'ai appris beaucoup de choses, j'espère que vous ne sanctionnerez pas cela car ici, les IA (chatGPT o1/o3-mini-high et surtout Claude 3.7 Sonnet) m'ont énormément appris car 
je me suis nourri de toutes leurs explications sans faire des copiés collés stupides.

Je ne suis pas devenu un pro de l'assembleur, mais en tout cas ma courbe de progression et la vue de ce résultat final me rendent fier de moi.

Place au code :

## Fonctionnalités

- Stockage sécurisé de données en mémoire RAM
- Chiffrement XOR avec clé personnalisable
- Interface utilisateur interactive en ligne de commande
- Plusieurs commandes disponibles (aide, stockage, lecture, etc.)
- Implémentation complète en assembleur x86_64

## Prérequis

Pour compiler et exécuter ce projet, vous aurez besoin de:

- Un système Linux x86_64
- NASM (Netwide Assembler)
- LD (GNU Linker)
- Permissions root pour certaines opérations mémoire (si nécessaire)

## Installation et compilation

### Option 1: Compilation manuelle

```bash
# Compiler le code source
nasm -f elf64 MONCOMBLE_projet.s -o MONCOMBLE_projet.o

# Créer l'exécutable
ld MONCOMBLE_projet.o -o MONCOMBLE_projet

# Ajouter les permissions d'exécution
chmod +x MONCOMBLE_projet
```

### Option 2: Utiliser le script de compilation

```bash
# Rendre le script exécutable
chmod +x compil.sh

# Exécuter le script
./compil.sh
```

## Utilisation

Pour lancer le programme:

```bash
./MONCOMBLE_projet
```

Si vous rencontrez des problèmes de permission:

```bash
sudo ./MONCOMBLE_projet
```

### Commandes disponibles

Une fois le programme lancé, vous pouvez utiliser les commandes suivantes:

- `aide` - Affiche la liste des commandes disponibles
- `stocker <données>` - Chiffre et stocke les données en mémoire
- `lire` - Récupère et affiche les données déchiffrées
- `cle <mot_de_passe>` - Définit une nouvelle clé de chiffrement (par défaut: "42")
- `quitter` - Quitte le programme

### Exemple d'utilisation

```
> stocker Information confidentielle
[+] Donnees stockees en memoire chiffree
> lire
[+] Donnees dechiffrees: Information confidentielle
> cle secret123
[+] Cle de chiffrement definie
> stocker Nouvelles données avec nouvelle clé
[+] Donnees stockees en memoire chiffree
> lire
[+] Donnees dechiffrees: Nouvelles données avec nouvelle clé
> quitter
```

## Fonctionnement technique

### Architecture du programme

Le programme est structuré en plusieurs sections:

1. **Section .data** - Contient les messages, chaînes de commande et données statiques
2. **Section .bss** - Définit les espaces de stockage pour les tampons et variables
3. **Section .text** - Contient le code exécutable avec les fonctions principales

### Chiffrement

Le programme utilise un chiffrement XOR simple mais efficace:

- Chaque octet des données est XORé avec un octet de la clé
- Si la clé est plus courte que les données, elle est appliquée cycliquement
- Le même algorithme est utilisé pour le chiffrement et le déchiffrement

### Analyse des commandes

Le traitement des commandes se fait en deux étapes:

1. Extraction de la commande depuis l'entrée utilisateur
2. Comparaison avec les commandes connues et exécution de l'action correspondante

## Limitations et améliorations possibles

Bien que fonctionnel, ce projet a quelques limitations:

- Le chiffrement XOR est relativement simple et pourrait être remplacé par un algorithme plus robuste
- Les données sont stockées uniquement pendant l'exécution du programme (pas de persistance)
- La taille des données et de la clé est limitée (1023 octets pour les données, 63 pour la clé)

Améliorations possibles:

- Implémentation d'algorithmes de chiffrement plus avancés (AES, etc.)
- Ajout d'une fonctionnalité de sauvegarde des données chiffrées dans un fichier
- Implémentation d'un vrai système de protection mémoire avec appels système mmap
- Ajout de fonctionnalités comme la compression des données
